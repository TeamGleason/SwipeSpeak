//
//  SpeechSynthesizer.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 09/11/2017.
//  Copyright © 2017 Microsoft. All rights reserved.
//

import Foundation
import AVFoundation

class SpeechSynthesizer {
    
    static let shared = SpeechSynthesizer()

    private let synthesizer = AVSpeechSynthesizer()

    private init() { }
    
    func speak(_ text: String) {
        speak(text, UserPreferences.shared.voiceIdentifier)
    }
    
    func speak(_ text: String, _ voiceIdentifier: String? = nil) {
        let utterance = AVSpeechUtterance(string: text)

        if let voiceIdentifier = voiceIdentifier,
            let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        utterance.rate = UserPreferences.shared.speechRate
        utterance.volume = UserPreferences.shared.speechVolume
        
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
    
}
