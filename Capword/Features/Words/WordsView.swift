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
    @StateObject private var cameraManager = CameraManager()
    
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
                    showCamera = true
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
                    .font(AppTheme.TextStyles.subtitle())
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

struct ToastView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sticker saved to Photos!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Text("+1")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
}

struct WordCardView: View {
    let word: CapturedWord
    @Binding var activeWordID: UUID?
    let onShowToast: (String) -> Void
    @State private var scale: CGFloat = 1.0
    @State private var showDeleteAlert = false
    @State private var showDetail = false
    @Environment(\.modelContext) private var modelContext
    
    private var shouldBlur: Bool {
        activeWordID != nil && activeWordID != word.id
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if let imageData = word.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            StrokeLabelView(
                text: word.translation,
                font: AppTheme.TextStyles.captionUIFont(),
                textColor: UIColor(AppTheme.primary),
                strokeColor: .white,
                strokeSize: 12,
                textAlignment: .center
            )
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: false)
            .shadow(color: .black.opacity(0.42), radius: 18, x: 0, y: 8)
        }
        .scaleEffect(scale)
        .opacity(shouldBlur ? 0.4 : 1.0)
        .blur(radius: shouldBlur ? 3 : 0)
        .animation(.interpolatingSpring(stiffness: 300, damping: 20), value: scale)
        .animation(.easeOut(duration: 0.25), value: shouldBlur)
        .onTapGesture {
            Vibration.fire(.impact(.soft))
            showDetail = true
        }
        .contextMenu {
            Button(action: {
                speakWord()
            }) {
                Label("Speak", systemImage: "speaker.wave.3")
            }
            
            Button(action: {
                saveToGallery()
            }) {
                Label("Save to Gallery", systemImage: "arrow.down.circle.fill")
            }
            
            Button(role: .destructive, action: {
                showDeleteAlert = true
            }) {
                Label("Delete", systemImage: "trash.fill")
            }
        }
        .alert("Delete Word?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteWord()
            }
        } message: {
            Text("Are you sure you want to delete \"\(word.translation)\"?")
        }
        .fullScreenCover(isPresented: $showDetail) {
            if let imageData = word.imageData, let image = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    ImagePreviewOverlay(
                        image: image,
                        detectedText: word.detectedText,
                        translationText: word.translation,
                        targetLanguage: word.targetLanguage,
                        isViewOnly: true
                    )
                    
                    Button(action: {
                        showDetail = false
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.35))
                                .frame(width: 44, height: 44)
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .paddingContent()
                }
            }
        }
    }
    
    private func speakWord() {
        Vibration.fire(.impact(.soft))
        TextToSpeechProvider.shared.speak(word.translation, languageCode: word.targetLanguage)
    }
    
    private func saveToGallery() {
        Vibration.fire(.impact(.medium))
        
        guard let imageData = word.imageData,
              let image = UIImage(data: imageData) else {
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        withAnimation(.interpolatingSpring(stiffness: 250, damping: 15)) {
            scale = 1.15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                scale = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 22)) {
                activeWordID = nil
            }
            onShowToast("Copied! Paste it anywhere")
        }
    }
    
    private func deleteWord() {
        Vibration.fire(.impact(.medium))
        
        withAnimation(.interpolatingSpring(stiffness: 350, damping: 20)) {
            scale = 0.85
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.2)) {
                activeWordID = nil
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                modelContext.delete(word)
            }
        }
    }
}
