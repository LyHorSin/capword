//
//  PermissionManager.swift
//  Capword
//
//  Centralize permission requests (notifications, camera, photos, etc.).
//

import Foundation
import AVFoundation
import UserNotifications
import Photos
import UIKit

final class PermissionManager {
    static let shared = PermissionManager()

    private init() {}

    // MARK: - Camera

    /// Returns current camera authorization status
    func cameraAuthorizationStatus() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }

    /// Request camera access. Returns `true` if access granted.
    func requestCameraPermission() async -> Bool {
        // If already authorized, return true
        let status = cameraAuthorizationStatus()
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    cont.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    // MARK: - Notifications

    /// Get current notification settings
    func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                cont.resume(returning: settings)
            }
        }
    }

    /// Request notification authorization with specified options. Returns true if granted.
    func requestNotificationPermission(options: UNAuthorizationOptions = [.alert, .sound, .badge]) async -> Bool {
        // If already authorized, return true
        let settings = await notificationSettings()
        if settings.authorizationStatus == .authorized {
            return true
        }

        return await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, _ in
                cont.resume(returning: granted)
            }
        }
    }

    // MARK: - Photo Library

    /// Returns the current photo library authorization status for read/write operations.
    func photoLibraryAuthorizationStatus() -> PHAuthorizationStatus {
        if #available(iOS 14, *) {
            return PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            return PHPhotoLibrary.authorizationStatus()
        }
    }

    /// Request photo library permission (read/write by default). Returns the new status.
    func requestPhotoLibraryPermission(accessLevel: PHAccessLevel = .readWrite) async -> PHAuthorizationStatus {
        if #available(iOS 14, *) {
            return await withCheckedContinuation { cont in
                PHPhotoLibrary.requestAuthorization(for: accessLevel) { status in
                    cont.resume(returning: status)
                }
            }
        } else {
            return await withCheckedContinuation { cont in
                PHPhotoLibrary.requestAuthorization { status in
                    cont.resume(returning: status)
                }
            }
        }
    }

    // MARK: - Utilities

    /// Open the app's Settings page so the user can manually enable permissions.
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

// Helpful convenience asynchronous helpers that return Bool
extension PermissionManager {
    func ensureCameraPermission() async -> Bool {
        return await requestCameraPermission()
    }

    func ensureNotificationPermission() async -> Bool {
        return await requestNotificationPermission()
    }

    func ensurePhotoPermission() async -> Bool {
        let status = await requestPhotoLibraryPermission()
        switch status {
        case .authorized, .limited:
            return true
        default:
            return false
        }
    }
}

/*
 Info.plist notes (you must add these keys in your Xcode project Info.plist):
 - NSCameraUsageDescription (Privacy - Camera Usage Description)
 - NSPhotoLibraryUsageDescription (Privacy - Photo Library Usage Description)
 - NSPhotoLibraryAddUsageDescription (Privacy - Photo Library Additions Usage Description)
 For notifications, no Info.plist key is required, but ask the user to allow notifications.
 */
