//
//  TrackableScrollView.swift
//  Capword
//
//  Created by Ly Hor Sin on 8/11/25.
//

import SwiftUI

// Latest-only value (no summing)
private struct ScrollViewOffsetKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {  }
}

struct TrackableScrollView<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let onOffsetChange: (CGPoint) -> Void
    @ViewBuilder var content: () -> Content

    init(_ axes: Axis.Set = .vertical,
         showsIndicators: Bool = true,
         onOffsetChange: @escaping (CGPoint) -> Void = { _ in },
         @ViewBuilder content: @escaping () -> Content) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.onOffsetChange = onOffsetChange
        self.content = content
    }
    
    private var offsetView: some View {
        GeometryReader { proxy in
            let origin = proxy.frame(in: .named("scrollView")).origin
            Color.clear
                .preference(key: ScrollViewOffsetKey.self, value: origin)
        }
    }

    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            offsetView
            content()
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollViewOffsetKey.self, perform: onOffsetChange)
    }
}
