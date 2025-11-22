//
//  WordCardView.swift
//  Capword
//
//  Created by Ly Hor Sin on 22/11/25.
//
import SwiftUI
import SwiftData

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
