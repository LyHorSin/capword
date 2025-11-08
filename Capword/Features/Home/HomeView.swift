//
//  HomeView.swift
//  Capword
//
//  Placeholder home view for the Home feature.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            GeometryReader { geo in
                ZStack(alignment: .top) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            HeaderView()

                            // Make the progress ring size respond to available width/height
                            CircleProgressView()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)

                            DailyProgressCardView()
                        }
                        // Make the content at least the full height of the remaining screen
                        .frame(minHeight: geo.size.height)
                        .paddingContent()
                    }
                    GlassNavigationBar("",
                                       hideBackButton: true, trailing:  {
                        Button {
                            
                        } label: {
                            CircleButtonView(systemNameIcon: "person") {
                                
                            }
                        }
                    })
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }
    }
}

#Preview {
    HomeView()
}
