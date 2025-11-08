//
//  HomeView.swift
//  Capword
//
//  Placeholder home view for the Home feature.
//
import SwiftUI

struct HomeView: View {
    @State private var scrollOffset: CGFloat = 0     // signed
    @State private var baselineY: CGFloat? = nil     // first sentinel Y
    @State private var isVibration: Bool = false

    // Split directions for easy use
    private var upOffset: CGFloat { max(0, scrollOffset) }      // scrolling up
    private var downOffset: CGFloat { max(0, -scrollOffset) }   // scrolling down

    // Shrinks as you scroll up; never exceeds 1.0 when pulling down
    private var circleScale: CGFloat {
        let minScale: CGFloat = 0.4, maxScale: CGFloat = 1.0, threshold: CGFloat = 200
        let shrink = (upOffset / threshold) * (maxScale - minScale)
        return max(minScale, maxScale - shrink)
    }

    // Optional: gentle parallax when pulling down
    private var circleParallaxY: CGFloat { downOffset * 0.25 }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            GeometryReader { geo in
                ZStack(alignment: .top) {
                    TrackableScrollView(.vertical, showsIndicators: false) { point in
                        let y = point.y
                        if baselineY == nil { baselineY = y }        // capture once
                        // Signed offset: positive when scrolling up, negative when down
                        scrollOffset = (baselineY ?? y) - y
                        if scrollOffset >= 140 && !isVibration {
                            Vibration.fire(.impact(.soft))
                            isVibration = true
                        }
                        if scrollOffset < 140 {
                            isVibration = false
                        }
                        
                    } content: {
                        VStack(spacing: 24) {
                            HeaderView()

                            CircleProgressView()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .scaleEffect(circleScale, anchor: .center)
                                .offset(y: circleParallaxY) // only moves when pulling down
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: circleScale)
                                .animation(.easeOut(duration: 0.2), value: circleParallaxY)

                            DailyProgressCardView()
                        }
                        .frame(minHeight: geo.size.height-geo.safeAreaInsets.bottom)
                        .paddingContent()
                    }

                    GlassNavigationBar("",
                        hideBackButton: true,
                        trailing: {
                            CircleButtonView(systemNameIcon: "person") { }
                        }
                    )
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }
    }
}
