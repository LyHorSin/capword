//
//  NetworkManager.swift
//  Capword
//
//  Network manager with connectivity monitoring, slow network detection,
//  request helpers with timeout and retry/backoff logic.
//

import Foundation
import Network

/// Errors emitted by NetworkManager
public enum NetworkError: Error {
    case noConnection
    case slowConnection(TimeInterval)
    case timeout
    case httpError(statusCode: Int)
}

final class NetworkManager {
    static let shared = NetworkManager()

    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.capword.network.monitor")
    private var currentPath: NWPath?

    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
        self.monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.currentPath = path
        }
        monitor.start(queue: monitorQueue)
    }

    private func stopMonitoring() {
        monitor.cancel()
    }

    /// Whether the device currently has network connectivity
    var isConnected: Bool {
        return currentPath?.status == .satisfied
    }

    /// Whether the current connection is considered expensive (cellular)
    var isExpensive: Bool {
        return currentPath?.isExpensive ?? false
    }

    /// Human friendly interface type if available
    var interfaceType: String {
        guard let path = currentPath else { return "unknown" }
        if path.usesInterfaceType(.wifi) { return "wifi" }
        if path.usesInterfaceType(.cellular) { return "cellular" }
        if path.usesInterfaceType(.wiredEthernet) { return "ethernet" }
        return "other"
    }

    // MARK: - Latency / Slow network detection

    /// Measure latency (round-trip) to a URL by performing a small GET request.
    /// Returns elapsed time in seconds.
    func measureLatency(to url: URL, timeout: TimeInterval = 5.0) async throws -> TimeInterval {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout

        let start = Date()
        let (_, response) = try await session.data(for: request)
        // Optionally validate response
        if let http = response as? HTTPURLResponse, !(200...399).contains(http.statusCode) {
            throw NetworkError.httpError(statusCode: http.statusCode)
        }
        return Date().timeIntervalSince(start)
    }

    // MARK: - Requests with timeout / retry / slow detection

    /// Fetch data from a URL with optional timeout, retry attempts and slow-network detection.
    /// - Parameters:
    ///   - url: URL to fetch
    ///   - timeout: request timeout in seconds
    ///   - retries: number of retry attempts (exponential backoff)
    ///   - slowThreshold: if measured latency is >= slowThreshold, function will throw `NetworkError.slowConnection` (pass nil to disable)
    func fetchData(from url: URL,
                   timeout: TimeInterval = 15,
                   retries: Int = 2,
                   slowThreshold: TimeInterval? = 2.0) async throws -> Data {

        // Quick connectivity guard
        guard isConnected else { throw NetworkError.noConnection }

        // Optional pre-check: measure latency to the host root (if slowThreshold provided)
        if let threshold = slowThreshold {
            // Use the same host root if available, fallback to the url itself
            let probeURL = URL(string: "/", relativeTo: URL(string: "\(url.scheme ?? "https")://\(url.host ?? "")")) ?? url
            do {
                let latency = try await measureLatency(to: probeURL, timeout: 4.0)
                if latency >= threshold {
                    throw NetworkError.slowConnection(latency)
                }
            } catch {
                // If latency measurement fails, we continue to attempt the real request —
                // but if you want to fail early, rethrow here.
            }
        }

        var attempt = 0
        var lastError: Error?
        while attempt <= retries {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = timeout

                let (data, response) = try await session.data(for: request)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    throw NetworkError.httpError(statusCode: http.statusCode)
                }
                return data
            } catch let urlError as URLError where urlError.code == .timedOut {
                lastError = NetworkError.timeout
            } catch {
                lastError = error
            }

            attempt += 1
            // exponential backoff
            let backoff = pow(2.0, Double(attempt))
            try? await Task.sleep(nanoseconds: UInt64(backoff * 0.5 * 1_000_000_000))
        }

        throw lastError ?? NetworkError.noConnection
    }
}

