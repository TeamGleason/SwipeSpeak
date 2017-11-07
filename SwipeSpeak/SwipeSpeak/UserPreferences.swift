//
//  UserPreferences.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 06/11/2017.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import AVFoundation
import Zephyr

enum KeyboardLayout: Int {
    case keys4 = 0, keys6, keys8, strokes2
}

private struct Keys {
    
    static let keyboardLayout   = "keyboardLayout"

    static let announceLettersCount      = "announceLettersCount"
    static let vibrate                   = "vibrate"
    static let longerPauseBetweenLetters = "longerPauseBetweenLetters"

    static let audioFeedback    = "audioFeedback"
    static let voiceIdentifier  = "voiceIdentifier"
    static let speechRate       = "speechRate"
    static let speechVolume     = "speechVolume"
    
    static let enableCloudSync  = "enableCloudSync"

    static let userAddedWords   = "userAddedWords"
    static let sentenceHistory  = "sentenceHistory"
    
    static func iCloudSyncKeys() -> [String] {
        return [
            Keys.keyboardLayout,
            
            Keys.announceLettersCount,
            Keys.vibrate,
            Keys.longerPauseBetweenLetters,
            
            Keys.audioFeedback,
            Keys.voiceIdentifier,
            Keys.speechRate,
            Keys.speechVolume,
            
            //Keys.enableCloudSync,
            
            Keys.userAddedWords,
            Keys.sentenceHistory,
        ]
    }
}

class UserPreferences {
    
    // MARK: Shared Instance
    
    static let shared = UserPreferences()
    
    // MARK: User Defaults
    
    private var userDefaults: UserDefaults {
        return UserDefaults.standard
    }
    
    // MARK: Initialization

    init() {
        userDefaults.register(defaults: [
            Keys.keyboardLayout: KeyboardLayout.keys4.rawValue,
            
            Keys.announceLettersCount: true,
            Keys.vibrate: true,
            Keys.longerPauseBetweenLetters: true,

            Keys.audioFeedback: true,
            Keys.speechRate: AVSpeechUtteranceDefaultSpeechRate,
            Keys.speechVolume: 1.0,
            
            Keys.enableCloudSync: true,
            ])
        
        Zephyr.debugEnabled = true
        Zephyr.sync(keys: Keys.iCloudSyncKeys())
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Properties
    
    var keyboardLayout: KeyboardLayout {
        get {
            guard let layout = KeyboardLayout(rawValue: userDefaults.integer(forKey: Keys.keyboardLayout)) else {
                return KeyboardLayout.keys4
            }
            return layout
        }
        set(newValue) {
            userDefaults.set(newValue.rawValue, forKey: Keys.speechRate)
        }
    }
    
    var voiceIdentifier: String? {
        get {
            return userDefaults.string(forKey: Keys.voiceIdentifier)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.voiceIdentifier)
        }
    }
    
    var speechRate: Float {
        get {
            return userDefaults.float(forKey: Keys.speechRate)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.speechRate)
        }
    }
    
    var speechVolume: Float {
        get {
            return userDefaults.float(forKey: Keys.speechVolume)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.speechVolume)
        }
    }
    
    var userAddedWords: [String] {
        get {
            guard let array = userDefaults.array(forKey: Keys.userAddedWords) else { return [] }
            return array as! [String]
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.userAddedWords)
        }
    }
    
    // User added words
    
    func addWord(_ word: String) {
        let array = userAddedWords
        var newArray = Array(array)
        newArray.insert(word, at: 0)
        
        userAddedWords = newArray
    }
    
    func removeWord(_ index: Int) {
        let array = userAddedWords
        guard index < array.count else { return }
        
        var newArray = Array(array)
        newArray.remove(at: index)
        
        userAddedWords = newArray
    }
    
    // Sentence history

    var sentenceHistory: [[String: Any]] {
        get {
            guard let array = userDefaults.array(forKey: Keys.sentenceHistory) else { return [] }
            return array as! [[String: Any]]
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.sentenceHistory)
        }
    }
    
    func addSentence(_ sentence: String) {
        let array = sentenceHistory
        var newArray = Array(array)
        
        let dict = ["sentence": sentence, "date": Date()] as [String : Any]
        newArray.insert(dict, at: 0)
        
        sentenceHistory = newArray
    }
    
    func removeSentence(_ index: Int) {
        let array = sentenceHistory
        guard index < array.count else { return }
        
        var newArray = Array(array)
        newArray.remove(at: index)
        
        sentenceHistory = newArray
    }
    
    
    
}
