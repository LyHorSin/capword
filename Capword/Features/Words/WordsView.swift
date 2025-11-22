//
//  WordsView.swift
//  Capword
//
//  Displays all saved words grouped by date.
//

import SwiftUI
import SwiftData

struct WordsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Query(sort: \CapturedWord.capturedDate, order: .reverse, animation: .spring(response: 0.4, dampingFraction: 0.75))
    private var allWords: [CapturedWord]
    @State private var activeWordID: UUID?
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showCamera = false
    @State private var showSubscription = false
    @StateObject private var cameraManager = CameraManager()
    private let subscriptionHelper = SubscriptionHelper.shared
    
    private var groupedWords: [String: [CapturedWord]] {
        Dictionary(grouping: allWords) { word in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            return formatter.string(from: word.capturedDate)
        }
    }
    
    private var sortedDates: [String] {
        groupedWords.keys.sorted { date1, date2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            guard let d1 = formatter.date(from: date1),
                  let d2 = formatter.date(from: date2) else {
                return date1 > date2
            }
            return d1 > d2
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                GlassNavigationBar("", backAction: {
                    presentationMode.wrappedValue.dismiss()
                })
                
                if allWords.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            ForEach(sortedDates, id: \.self) { date in
                                if let words = groupedWords[date], !words.isEmpty {
                                    dateSection(date: date, words: words)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .top).combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                }
                            }
                        }
                        .paddingContent()
                        .padding(.bottom, 122)
                    }
                    
                }
            }
            .overlay(alignment: .bottom) {
                Button(action: {
                    Vibration.fire(.impact(.medium))
                    if subscriptionHelper.shouldShowSubscription() {
                        showSubscription = true
                    } else {
                        showCamera = true
                    }
                }) {
                    ZStack {
                        // Dashed background ring (scales with container)
                        Circle()
                            .strokeBorder(style: StrokeStyle(lineWidth: 4, dash: [100 * 0.01, 100 * 0.02]))
                            .foregroundColor(AppTheme.card)
                            .frame(width: 100, height: 100)
                        
                        CircleSegmentView()
                            .frame(width: 80, height: 80)
                    }
                }
            }
            
            if showToast {
                VStack {
                    Spacer()
                    ToastView(message: toastMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 22)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showToast)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(cameraManager: cameraManager)
        }
        .fullScreenCover(isPresented: $showSubscription) {
            SubscriptionView()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.secondary.opacity(0.5))
            
            Text("No words captured yet")
                .font(AppTheme.TextStyles.title())
                .foregroundColor(AppTheme.primary)
            
            Text("Start capturing objects with your camera")
                .font(AppTheme.TextStyles.body())
                .foregroundColor(AppTheme.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paddingContent()
    }
    
    private func dateSection(date: String, words: [CapturedWord]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(date)
                    .font(AppTheme.TextStyles.title())
                    .foregroundColor(AppTheme.primary)
                    .bold()
                
                Text("\(words.count) Words")
                    .font(AppTheme.TextStyles.caption())
                    .foregroundColor(AppTheme.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(words) { word in
                    WordCardView(
                        word: word,
                        activeWordID: $activeWordID,
                        onShowToast: { message in
                            toastMessage = message
                            withAnimation {
                                showToast = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation {
                                    showToast = false
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}


