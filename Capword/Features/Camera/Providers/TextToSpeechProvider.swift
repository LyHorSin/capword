//
//  TextToSpeechProvider.swift
//  Capword
//
//  Created by assistant on 2025-11-15.
//

import AVFoundation
import Combine

@MainActor
final class TextToSpeechProvider: NSObject, ObservableObject {
    static let shared = TextToSpeechProvider()

    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    /// Optional explicit voice identifier (e.g. from `availableVoices()`)
    /// If set, `bestVoice(for:)` will prefer this identifier when available.
    var preferredVoiceIdentifier: String?

    @Published private(set) var isSpeaking: Bool = false

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Audio session (still plays in silent mode)
    private func configureAudioSessionIfNeeded() {
        do {
            try audioSession.setCategory(.playback,
                                         mode: .spokenAudio,
                                         options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
    }

    // MARK: - Best voice helper
    private func bestVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        // If a preferred identifier is set, try to find it first (and ensure
        // it matches the language requested).
        if let pref = preferredVoiceIdentifier,
           let match = allVoices.first(where: { $0.identifier == pref && $0.language.hasPrefix(languageCode) }) {
            return match
        }

        // Filter voices for the target language
        let candidates = allVoices.filter { $0.language.hasPrefix(languageCode) }

        // Prefer enhanced quality if available
        if let enhanced = candidates.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }

        // Fallback to any matching voice
        if let any = candidates.first {
            return any
        }

        // Last resort: try direct init
        let voice = AVSpeechSynthesisVoice(language: languageCode)
        
        // If voice is still nil (language not supported), log and return nil
        if voice == nil {
            print("⚠️ No voice available for language code: \(languageCode)")
            print("📋 Available languages: \(Set(allVoices.map { $0.language }).sorted())")
        }
        
        return voice
    }

    /// Return available voices matching (optionally) a language prefix.
    func availableVoices(matching languagePrefix: String? = nil) -> [AVSpeechSynthesisVoice] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        guard let prefix = languagePrefix, !prefix.isEmpty else { return voices }
        return voices.filter { $0.language.hasPrefix(prefix) }
    }

    /// Speak with more "human-like" settings.
    func speak(_ text: String,
               languageCode: String = "en",
               rate: Float = 0.48,          // default base rate
               pitchMultiplier: Float = 1.0,
               volume: Float = 1.0) {
        // By default route to the more natural speaker that breaks text into
        // sentence-level utterances and adds tiny, varying prosody so the
        // result sounds less robotic.
        speakNatural(text,
                     languageCode: languageCode,
                     baseRate: rate,
                     basePitch: pitchMultiplier,
                     volume: volume,
                     interrupt: true)
    }

    /// Speak in a more human / natural style by splitting into sentences and
    /// applying small, random variations to rate and pitch, plus short
    /// pauses between sentences. This reduces monotony and feels closer to
    /// how a real person would speak.
    func speakNatural(_ text: String,
                      languageCode: String = "en",
                      baseRate: Float = 0.48,
                      basePitch: Float = 1.0,
                      volume: Float = 1.0,
                      interrupt: Bool = true) {

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        configureAudioSessionIfNeeded()

        if interrupt && synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let sentences = splitIntoSentences(trimmed)
        guard !sentences.isEmpty else { return }

        for (index, sentence) in sentences.enumerated() {
            let utterance = AVSpeechUtterance(string: sentence)

            // Slight natural variation so consecutive utterances don't sound
            // exactly the same. Keep variations small to avoid sounding odd.
            let rateVariation = Float(Double.random(in: -0.03...0.03))
            let pitchVariation = Float(Double.random(in: -0.05...0.05))

            let computedRate = max(0.1, min(AVSpeechUtteranceMaximumSpeechRate, baseRate + rateVariation))
            let computedPitch = max(0.5, min(2.0, basePitch + pitchVariation))

            utterance.rate = computedRate
            utterance.pitchMultiplier = computedPitch
            utterance.volume = volume

            // Slightly longer pause after sentence boundaries to mimic breathing
            // or natural phrasing. Use longer pause for final sentence.
            utterance.preUtteranceDelay = (index == 0) ? 0.02 : 0.01
            let isFinal = (index == sentences.count - 1)
            utterance.postUtteranceDelay = isFinal ? 0.20 : 0.12

            if let voice = bestVoice(for: languageCode) {
                utterance.voice = voice
            }

            synthesizer.speak(utterance)
        }

        isSpeaking = true
    }

    // Split text into sentence-like chunks using NSString sentence enumeration.
    private func splitIntoSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        let ns = text as NSString
        ns.enumerateSubstrings(in: NSRange(location: 0, length: ns.length), options: .bySentences) { (substring, _, _, _) in
            if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                sentences.append(s)
            }
        }
        return sentences
    }

    /// Speak in a style tuned to be closer to the neutral, clear tone used by
    /// services like Google Translate: consistent rate, little random
    /// variation, clear enunciation and short, steady pauses.
    func speakGoogleLike(_ text: String,
                         languageCode: String = "en",
                         baseRate: Float = 0.50,
                         basePitch: Float = 1.0,
                         volume: Float = 1.0,
                         interrupt: Bool = true) {

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        configureAudioSessionIfNeeded()

        if interrupt && synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let sentences = splitIntoSentences(trimmed)
        guard !sentences.isEmpty else { return }

        // Google-like style: smaller variance, slightly faster, shorter post pauses
        for (index, sentence) in sentences.enumerated() {
            let utterance = AVSpeechUtterance(string: sentence)

            // Minimal variation to keep speech from sounding overly robotic but
            // retain consistent tone compared to speakNatural.
            let rateVariation = Float(Double.random(in: -0.01...0.01))
            let computedRate = max(0.1, min(AVSpeechUtteranceMaximumSpeechRate, baseRate + rateVariation))

            utterance.rate = computedRate
            utterance.pitchMultiplier = basePitch
            utterance.volume = volume

            utterance.preUtteranceDelay = 0.01
            let isFinal = (index == sentences.count - 1)
            // shorter inter-sentence pause than natural mode; keeps flow smooth
            utterance.postUtteranceDelay = isFinal ? 0.12 : 0.06

            if let voice = bestVoice(for: languageCode) {
                utterance.voice = voice
            }

            synthesizer.speak(utterance)
        }

        isSpeaking = true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false

        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Failed to deactivate audio session: \(error)")
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension TextToSpeechProvider: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
