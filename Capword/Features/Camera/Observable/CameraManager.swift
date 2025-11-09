
//
//  Observable.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//
import SwiftUI
import AVFoundation

class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var photoCaptureCompletion: ((UIImage?) -> Void)?
    @Published var isReady = false
    private var isSetup = false
    private let setupLock = NSLock()
    private var pendingStopWorkItem: DispatchWorkItem?
    private let sessionQueue = DispatchQueue(label: "capword.camera.session")
    private var observers: [NSObjectProtocol] = []
    
    override init() {
        super.init()
        // Don't setup camera in init - do it lazily
        // Observe app lifecycle to keep session alive while app is foreground
        let nc = NotificationCenter.default
        let willResign = nc.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.stopSession(immediate: true)
        }
        let didBecome = nc.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            // Start session if setup is already done (do not force setup here)
            if let self = self, self.isSetup {
                self.startSession()
            }
        }
        observers.append(contentsOf: [willResign, didBecome])
    }

    deinit {
        for obs in observers { NotificationCenter.default.removeObserver(obs) }
    }
    
    private func setupCamera() {
        setupLock.lock()
        defer { setupLock.unlock() }

        guard !isSetup else {
            print("⚠️ Camera already setup, skipping")
            return
        }

        isSetup = true
        print("🔧 Setting up camera (sessionQueue)")

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                self.session.commitConfiguration()
                print("❌ Camera device not available")
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }

                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }

                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.isReady = true
                }
                print("✅ Camera setup complete (one-time)")
            } catch {
                print("❌ Error setting up camera: \(error.localizedDescription)")
                self.session.commitConfiguration()
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCaptureCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func stopSession(immediate: Bool = false) {
        // If immediate, cancel any pending stop and stop right away on sessionQueue
        pendingStopWorkItem?.cancel()
        pendingStopWorkItem = nil

        if immediate {
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                if self.session.isRunning {
                    print("⏸️ Stopping camera session (immediate)")
                    self.session.stopRunning()
                }
            }
            return
        }

        // Schedule a delayed stop to avoid tearing down hardware on quick reopen.
        // If `startSession()` is called before the delay expires, the stop will be cancelled.
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.sessionQueue.async {
                if self.session.isRunning {
                    print("⏸️ Stopping camera session (delayed)")
                    self.session.stopRunning()
                }
            }
        }
        pendingStopWorkItem = work
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3.0, execute: work)
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
                // If a stop was scheduled, cancel it to avoid racing stop/start
                self.pendingStopWorkItem?.cancel()
                self.pendingStopWorkItem = nil

                // Setup camera first if not done (on sessionQueue)
                if !self.isSetup {
                    self.setupCamera()
                }

                // Start running on sessionQueue to avoid blocking main
                self.sessionQueue.async {
                    if !self.session.isRunning {
                        print("▶️ Starting camera session (sessionQueue)")
                        self.session.startRunning()
                        print("✓ Camera session started")
                    }
                }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoCaptureCompletion?(nil)
            return
        }
        photoCaptureCompletion?(image)
    }
}
