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
    @State private var showHeader: Bool = false
    @State private var showCircle: Bool = false
    @State private var showDailyProgress: Bool = false
    @State private var showCamera: Bool = false
    @State private var showSubscription: Bool = false
    @StateObject private var cameraManager = CameraManager()
    private let subscriptionHelper = SubscriptionHelper.shared

    // Split directions for easy use
    private var upOffset: CGFloat { max(0, scrollOffset) }      // scrolling up
    private var downOffset: CGFloat { max(0, -scrollOffset) }   // scrolling down

    // Shrinks as you scroll up; never exceeds 1.0 when pulling down
    private var circleScale: CGFloat {
        let minScale: CGFloat = 0.4, maxScale: CGFloat = 0.9, threshold: CGFloat = 200
        let shrink = (upOffset / threshold) * (maxScale - minScale)
        return max(minScale, maxScale - shrink)
    }
    
    // Optional: gentle parallax when pulling down
    private var circleParallaxY: CGFloat { downOffset * 0.25 }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    GlassNavigationBar("", hideBackButton: true, trailing: {
                        NavigationLink(destination: ProfileView()) {
                            CircleButtonLabel(systemNameIcon: "person")
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                Vibration.fire(.impact(.soft))
                            }
                        )
                    })
                    
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
                        VStack {
                            HeaderView()
                                .opacity(showHeader ? 1 : 0)
                                .offset(y: showHeader ? 0 : 30)
                                .animation(.easeOut(duration: 0.5), value: showHeader)
                            
                            CircleProgressView()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .scaleEffect(circleScale, anchor: .center)
//                                .offset(y: circleParallaxY) // only moves when pulling down
                                .opacity(showCircle ? 1 : 0)
//                                .offset(y: showCircle ? circleParallaxY : circleParallaxY + 30)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: circleScale)
                                .animation(.easeOut(duration: 0.5).delay(0.15), value: showCircle)
                                .animation(.easeOut(duration: 0.2), value: circleParallaxY)
                                .onTapGesture {
                                    Vibration.fire(.impact(.medium))
                                    if subscriptionHelper.shouldShowSubscription() {
                                        showSubscription = true
                                    } else {
                                        showCamera = true
                                    }
                                }
                            
                            NavigationLink(destination: WordsView()) {
                                DailyProgressCardView()
                                    .opacity(showDailyProgress ? 1 : 0)
                                    .offset(y: showDailyProgress ? 0 : 30)
                                    .animation(.easeOut(duration: 0.5).delay(0.3), value: showDailyProgress)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    Vibration.fire(.impact(.medium))
                                }
                            )
                        }
                        .padding(.horizontal, AppTheme.Constants.horizontalPadding)
                        .onAppear {
                            showHeader = true
                            showCircle = true
                            showDailyProgress = true
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(cameraManager: cameraManager)
            }
            .fullScreenCover(isPresented: $showSubscription) {
                SubscriptionView()
            }
        }
    }
}

