//
//  WaveView.swift
//  Capword
//
//  Created by Ly Hor Sin on 15/11/25.
//
import SwiftUI

fileprivate struct WaveView: View {
    var color: Color = Color.white.opacity(0.22)
    var amplitude: CGFloat = 20
    var frequency: CGFloat = 1.2
    var phase: CGFloat = 0

    var body: some View {
        WaveShape(amplitude: amplitude, frequency: frequency, phase: phase)
            .fill(color)
            .allowsHitTesting(false)
    }
}

// MARK: - Wave overlay (top -> bottom sweep while detecting)
fileprivate struct WaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        guard w > 0 else { return path }

        path.move(to: CGPoint(x: 0, y: h))
        let step: CGFloat = max(1, w / 200)
        var x: CGFloat = 0
        while x <= w {
            let relativeX = x / w
            let y = h / 2 + sin((relativeX * .pi * 2 * frequency) + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        return path
    }
}

/// Reusable overlay that sweeps a wave from top to bottom while `isActive` is true.
struct TopToBottomWave: View {
    @Binding var isActive: Bool
    var color: Color = Color.white.opacity(0.18)
    var amplitude: CGFloat = 14
    var frequency: CGFloat = 1.1
    var duration: Double = 1.6

    @State private var progress: CGFloat = -1
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { g in
            // Move wave vertically across the image
            WaveView(color: color, amplitude: amplitude, frequency: frequency, phase: phase)
                .frame(width: g.size.width, height: g.size.height)
                .offset(y: progress * g.size.height)
                .clipped()
                .onAppear {
                    // keep phase slowly moving for a subtle horizontal motion
                    withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false)) {
                        phase = .pi * 2
                    }
                    updateAnimation(active: isActive)
                }
                .onChange(of: isActive) { oldValue, newValue in
                    updateAnimation(active: newValue)
                }
        }
        .allowsHitTesting(false)
    }

    private func updateAnimation(active: Bool) {
        if active {
            // start from above and sweep down repeatedly
            progress = -1
            withAnimation(Animation.linear(duration: duration).repeatForever(autoreverses: false)) {
                progress = 1
            }
        } else {
            // stop and reset off-screen
            withAnimation(.easeOut(duration: 0.2)) {
                progress = -1
            }
        }
    }
}
