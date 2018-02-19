//
//  UserPreferences.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 06/11/2017.
//  Updated by Daniel Tsirulnikov on 11/9/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import AVFoundation
import Zephyr

enum KeyboardLayout: Int {
    case keys4 = 4
    case keys6 = 6
    case keys8 = 8
    case strokes2 = -1
    
    func localizedString() -> String {
        switch self {
        case .keys4:
            return NSLocalizedString("4 Keys", comment: "")
        case .keys6:
            return NSLocalizedString("6 Keys", comment: "")
        case .keys8:
            return NSLocalizedString("8 Keys", comment: "")
        case .strokes2:
            return NSLocalizedString("2 Strokes", comment: "")
        }
    }
}

struct SentenceKeys {
    static let sentence = "sentence"
    static let date     = "date"
}

extension NSNotification.Name {
    static let KeyboardLayoutDidChange = NSNotification.Name(rawValue: "KeyboardLayoutDidChange")
    static let UserAddedWordsUpdated = NSNotification.Name(rawValue: "UserAddedWordsUpdated")
}

private struct Keys {
    
    static let keyboardLayout = "keyboardLayout"

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

    private init() {
        userDefaults.register(defaults: [
            Keys.keyboardLayout: KeyboardLayout.strokes2.rawValue,
            
            Keys.announceLettersCount: true,
            Keys.vibrate: false,
            Keys.longerPauseBetweenLetters: true,

            Keys.audioFeedback: true,
            Keys.speechRate: AVSpeechUtteranceDefaultSpeechRate,
            Keys.speechVolume: 1.0,
            
            Keys.enableCloudSync: true,
            ])
        
        if self.enableCloudSync {
            enableZephyr()
        }
    }
    
    // MARK: Zephyr

    private func enableZephyr() {
        Zephyr.debugEnabled = true
        Zephyr.sync(keys: Keys.iCloudSyncKeys())
        Zephyr.addKeysToBeMonitored(keys: Keys.iCloudSyncKeys())
    }
    
    private func disableZephyr() {
        Zephyr.removeKeysFromBeingMonitored(keys: Keys.iCloudSyncKeys())
    }
    
    // MARK: Properties
    
    var keyboardLayout: KeyboardLayout {
        get {
            return KeyboardLayout(rawValue: userDefaults.integer(forKey: Keys.keyboardLayout))!
        }
        set(newValue) {
            userDefaults.set(newValue.rawValue, forKey: Keys.keyboardLayout)
            
            NotificationCenter.default.post(name: Notification.Name.KeyboardLayoutDidChange, object: self)
        }
    }
    
    var announceLettersCount: Bool {
        get {
            return userDefaults.bool(forKey: Keys.announceLettersCount)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.announceLettersCount)
        }
    }
    
    var vibrate: Bool {
        get {
            return userDefaults.bool(forKey: Keys.vibrate)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.vibrate)
        }
    }
    
    var longerPauseBetweenLetters: Bool {
        get {
            return userDefaults.bool(forKey: Keys.longerPauseBetweenLetters)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.longerPauseBetweenLetters)
        }
    }
    
    var audioFeedback: Bool {
        get {
            return userDefaults.bool(forKey: Keys.audioFeedback)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.audioFeedback)
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
    
    var enableCloudSync: Bool {
        get {
            return userDefaults.bool(forKey: Keys.enableCloudSync)
        }
        set(newValue) {
            userDefaults.set(newValue, forKey: Keys.enableCloudSync)
            
            if newValue {
                enableZephyr()
            } else {
                disableZephyr()
            }
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
    
    private let MaxUserAddedWords = 100
    
    func addWord(_ word: String) {
        let array = userAddedWords
        var newArray = Array(array)
        newArray.insert(word, at: 0)
        
        if newArray.count > MaxUserAddedWords {
            newArray.removeLast()
        }
        
        userAddedWords = newArray
        
        NotificationCenter.default.post(name: Notification.Name.UserAddedWordsUpdated, object: self)
    }
    
    func removeWord(_ index: Int) {
        let array = userAddedWords
        guard index < array.count else { return }
        
        var newArray = Array(array)
        newArray.remove(at: index)
        
        userAddedWords = newArray
    }
    
    func clearWords() {
        userAddedWords = []
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
    
    private let MaxSentenceHistory = 100

    func addSentence(_ sentence: String) {
        let array = sentenceHistory
        var newArray = Array(array)
        
        let dict = [SentenceKeys.sentence: sentence,
                    SentenceKeys.date: Date()] as [String : Any]
        newArray.insert(dict, at: 0)
        
        if newArray.count > MaxSentenceHistory {
            newArray.removeLast()
        }
        
        sentenceHistory = newArray
    }
    
    func removeSentence(_ index: Int) {
        let array = sentenceHistory
        guard index < array.count else { return }
        
        var newArray = Array(array)
        newArray.remove(at: index)
        
        sentenceHistory = newArray
    }
    
    func clearSentenceHistory() {
        sentenceHistory = []
    }
    
}
