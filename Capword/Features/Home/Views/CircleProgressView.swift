//
//  CircleProgressView.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//

import SwiftUI

struct CircleProgressView: View {
    @State private var isSpinning: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            // sizes relative to available square
            let dashedSize = size * 0.92
            let segmentsSize = dashedSize * 0.82
            let dashedLineWidth = max(2.0, dashedSize * 0.01)
            let segmentsLineWidth = max(4.0, segmentsSize * 0.03)
            
            ZStack {
                // Dashed background ring (scales with container)
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: dashedLineWidth, dash: [dashedSize * 0.01, dashedSize * 0.02]))
                    .foregroundColor(AppTheme.card)
                    .frame(width: dashedSize, height: dashedSize)
                
                // Rotating segments layer (scales and animates)
                CircleSegmentView(lineWidth: segmentsLineWidth, desiredGapPerSegment: 0.02)
                    .frame(width: segmentsSize, height: segmentsSize)
                    .rotationEffect(.degrees(isSpinning ? 360 : 0))
                    .animation(.linear(duration: 44).repeatForever(autoreverses: false), value: isSpinning)
                    .onAppear { isSpinning = true }
            }
            // center the ZStack inside the GeometryReader
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
        .padding(.vertical, 8)
    }
}
 
struct CircleSegmentView: View {
    // allow configurable line width and gap; provide defaults for backwards compatibility
    private let lineWidth: Double
    private let desiredGapPerSegment: Double
    
    init(lineWidth: Double = 12.0, desiredGapPerSegment: Double = 0.02) {
        self.lineWidth = lineWidth
        self.desiredGapPerSegment = desiredGapPerSegment
    }
    
    // Constants for segment calculations
    // We want equal segment lengths and equal gaps between them.
    // Specify desired gap per segment (fraction of circle). The segment size
    // is computed so 5*(segmentSize + segmentGap) <= 1.0.
    private var segmentGap: Double { max(0, desiredGapPerSegment) }
    
    private var segmentSize: Double {
        // Ensure we don't overflow the circle: distribute remaining space equally
        let totalGaps = 5.0 * segmentGap
        let available = max(0.0, 1.0 - totalGaps)
        return available / 5.0
    }
    
    private func segmentPosition(index: Int) -> Double {
        return Double(index) * (segmentSize + segmentGap)
    }
    
    var body: some View {
        ZStack {
            // Using arcs approximated by trimmed circles with rotation
            Circle()
                .fill(Color.white)
            
            // Segment 1 (Blue)
            Circle()
                .trim(from: segmentPosition(index: 0), to: segmentPosition(index: 0) + segmentSize)
                .stroke(AppTheme.pastelBlue, lineWidth: lineWidth)
                .padding()
                .rotationEffect(.degrees(-90))
            
            // Segment 2 (Purple)
            Circle()
                .trim(from: segmentPosition(index: 1), to: segmentPosition(index: 1) + segmentSize)
                .stroke(AppTheme.pastelPurple, lineWidth: lineWidth)
                .padding()
                .rotationEffect(.degrees(-90))
            
            
            // Segment 3 (Pink)
            Circle()
                .trim(from: segmentPosition(index: 2), to: segmentPosition(index: 2) + segmentSize)
                .stroke(AppTheme.pastelPink, lineWidth: lineWidth)
                .padding()
                .rotationEffect(.degrees(-90))
            
            // Segment 4 (Green)
            Circle()
                .trim(from: segmentPosition(index: 3), to: segmentPosition(index: 3) + segmentSize)
                .stroke(AppTheme.pastelGreen, lineWidth: lineWidth)
                .padding()
                .rotationEffect(.degrees(-90))
            
            // Segment 5 (Yellow)
            Circle()
                .trim(from: segmentPosition(index: 4), to: segmentPosition(index: 4) + segmentSize)
                .stroke(AppTheme.pastelYellow, lineWidth: lineWidth)
                .padding()
                .rotationEffect(.degrees(-90))
        }
    }
}
