//
//  CameraView.swift
//  Capword
//
//  Camera capture view with viewfinder frame and controls.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker = false
    @State private var capturedImage: UIImage?
    @State private var showPreview = false
    @ObservedObject var cameraManager: CameraManager
    
    var body: some View {
        ZStack {
            // Camera preview background
            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()
            
            // Dark overlay to dim the camera feed
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Loading indicator while camera is initializing
            if !cameraManager.isReady {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
            
            VStack(spacing: 0) {
                // Top section with date
                topSection
                
                Spacer()
                
                // Center viewfinder frame
                viewfinderFrame
                
                Spacer()
                
                // Bottom controls
                bottomControls
                    .padding(.bottom, 40)
            }
            
            // Full-screen image preview overlay
            if showPreview, let image = capturedImage {
                ImagePreviewOverlay(image: image, onRetake: {
                    showPreview = false
                    capturedImage = nil
                    // keep session running for smooth UX
                }, onUse: {
                    // Handle using the image (e.g., navigate to next screen)
                    dismiss()
                })
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $capturedImage)
        }
        .task {
            // Start camera session immediately
            cameraManager.startSession()
        }
    }
    
    // MARK: - Top Section
    private var topSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(currentDateString())
                .font(AppTheme.TextStyles.header())
                .foregroundColor(.white)
                .padding(.top, 60)
                .padding(.leading, AppTheme.Constants.horizontalPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Viewfinder Frame
    private var viewfinderFrame: some View {
        GeometryReader { geo in
            VStack(spacing: 60) {
                // Frame with rounded corner brackets
                ZStack(alignment: .bottom) {
                    let frameWidth: CGFloat = geo.size.width * 0.85
                    let frameHeight: CGFloat = geo.size.height * 0.75
                    let cornerRadius: CGFloat = 25
                    let cornerLength: CGFloat = 50
                    let lineWidth: CGFloat = 5
                    
                    // Top-left corner (quarter circle arc)
                    Path { path in
                        path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius),
                                   radius: cornerRadius,
                                   startAngle: .degrees(180),
                                   endAngle: .degrees(270),
                                   clockwise: false)
                    }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: cornerLength, height: cornerLength)
                    .position(x: cornerLength / 2, y: cornerLength / 2)
                    
                    // Top-right corner (quarter circle arc)
                    Path { path in
                        path.addArc(center: CGPoint(x: cornerLength - cornerRadius, y: cornerRadius),
                                   radius: cornerRadius,
                                   startAngle: .degrees(270),
                                   endAngle: .degrees(0),
                                   clockwise: false)
                    }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: cornerLength, height: cornerLength)
                    .position(x: frameWidth - cornerLength / 2, y: cornerLength / 2)
                    
                    // Bottom-left corner (quarter circle arc)
                    Path { path in
                        path.addArc(center: CGPoint(x: cornerRadius, y: cornerLength - cornerRadius),
                                   radius: cornerRadius,
                                   startAngle: .degrees(90),
                                   endAngle: .degrees(180),
                                   clockwise: false)
                    }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: cornerLength, height: cornerLength)
                    .position(x: cornerLength / 2, y: frameHeight - cornerLength / 2)
                    
                    // Bottom-right corner (quarter circle arc)
                    Path { path in
                        path.addArc(center: CGPoint(x: cornerLength - cornerRadius, y: cornerLength - cornerRadius),
                                   radius: cornerRadius,
                                   startAngle: .degrees(0),
                                   endAngle: .degrees(90),
                                   clockwise: false)
                    }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: cornerLength, height: cornerLength)
                    .position(x: frameWidth - cornerLength / 2, y: frameHeight - cornerLength / 2)
                    
                    VStack(spacing: 8) {
                        Text("Please place the object")
                            .font(AppTheme.TextStyles.subtitle())
                            .foregroundColor(.white)
                        Text("within the frame")
                            .font(AppTheme.TextStyles.subtitle())
                            .foregroundColor(.white)
                    }
                    .multilineTextAlignment(.center)
                }
                .frame(width: geo.size.width * 0.85, height: geo.size.height * 0.75, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        HStack(spacing: 60) {
            // Close button
            Button(action: {
                Vibration.fire(.impact(.soft))
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 60, height: 60)
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            // Capture button with rainbow ring
            Button(action: {
                Vibration.fire(.impact(.medium))
                cameraManager.capturePhoto { image in
                    capturedImage = image
                    showPreview = true
                    // keep session running for smooth UX; CameraManager will stop on app background
                }
            }) {
                ZStack {
                    // Rainbow gradient ring
                    Circle()
                        .trim(from: 0, to: 1)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    AppTheme.pastelPink,
                                    AppTheme.pastelYellow,
                                    AppTheme.pastelGreen,
                                    AppTheme.pastelBlue,
                                    AppTheme.pastelPurple,
                                    AppTheme.pastelPink
                                ]),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            lineWidth: 6
                        )
                        .frame(width: 80, height: 80)
                    
                    // Inner white circle
                    Circle()
                        .fill(Color.white)
                        .frame(width: 66, height: 66)
                }
            }
            
            // Gallery button
            Button(action: {
                Vibration.fire(.impact(.soft))
                showImagePicker = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 60, height: 60)
                    Image(systemName: "photo")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Helper
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: Date())
    }
}
