//
//  Utility.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Updated by Daniel Tsirulnikov on 11/9/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

typealias KeyboardKey = Int

struct Constants {    
    static let defaultWordFrequency = 99999

    static let keyLetterGrouping4Keys = ["abcdef", "ghijkl", "mnopqrs", "tuvwxyz"]
    static let keyLetterGrouping6Keys = ["abcd", "efgh", "ijkl", "mnop", "qrstu", "vwxyz"]
    static let keyLetterGrouping8Keys = ["abc", "def", "ghi", "jkl", "mno", "pqrs", "tuv", "wxyz"]
    static let keyLetterGroupingSteve = ["abcd", "efgh", "ijkl", "mnop", "qrst", "uvwxyz"]
    static let keyLetterGroupingMSR   = ["abcd", "efgh", "ijkl", "mnop", "qrst", "uvwxyz"]
    
    static let arrows4KeysMap = [0: "↑",
                                 1: "→",
                                 2: "←",
                                 3: "↓"]
    
    static let arrows4KeysTextMap = [0: "Up",
                                     1: "Right",
                                     2: "Left",
                                     3: "Down"]
    
    static let arrows2StrokesMap = [0: "↗︎",
                                    1: "↑",
                                    2: "↖︎",
                                    3: "↘︎",
                                    4: "↓",
                                    5: "↙︎"]
    
    static let arrows2StrokesTextMap = [0: "Up Right",
                                        1: "Up",
                                        2: "Up Left",
                                        3: "Down Right",
                                        4: "Down",
                                        5: "Down left"]
    
    // ✔︎ ✘ ⌫
    static let MSRKeyYes = "👍🏻"
    static let MSRKeyNo = "👎🏻"
    static let MSRKeySpeak = "💬"
    static let MSRKeyDelete = "⟵"
    static let MSRKeyCancel = "❌"

    static let MSRKeyboardMasterKeys1 = ["C B A\nE   D", "G \(MSRKeyYes) F\nI    H", "L K J\nN   M", "P   O\nR   Q", "T \(MSRKeyNo) S\nV    U", "X   W\nZ   Y"]
    static let MSRKeyboardMasterKeys2 = ["C B A\nE   D", "G \(MSRKeySpeak) F\nI    H", "L K J\nN   M", "P   O\nR   Q", "T \(MSRKeyDelete) S\nV    U", "X   W\nZ   Y"]

    static let MSRKeyboardDetailKeys1 = [["A", "B",       "C", "D", MSRKeyCancel, "E"],
                                         ["F", MSRKeyYes, "G", "H", MSRKeyCancel, "I"],
                                         ["J", "K",       "L", "M", MSRKeyCancel, "N"],
                                         ["O", "",        "P", "Q", MSRKeyCancel, "R"],
                                         ["S", MSRKeyNo,  "T", "U", MSRKeyCancel, "V"],
                                         ["W", "",        "X", "Y", MSRKeyCancel, "Z"]]
    
    static let MSRKeyboardDetailKeys2 = [["A", "B",          "C", "D", MSRKeyCancel, "E"],
                                         ["F", MSRKeySpeak,  "G", "H", MSRKeyCancel, "I"],
                                         ["J", "K",          "L", "M", MSRKeyCancel, "N"],
                                         ["O", "",           "P", "Q", MSRKeyCancel, "R"],
                                         ["S", MSRKeyDelete, "T", "U", MSRKeyCancel, "V"],
                                         ["W", "",           "X", "Y", MSRKeyCancel, "Z"]]
}

func getWordAndFrequencyListFromCSV(_ filepath: String) -> [(String, Int)]? {
    let contents = try? String(contentsOfFile: filepath)
    let lines = contents?.components(separatedBy: CharacterSet.newlines).filter{!$0.isEmpty}
    var wordAndFrequencyList = [(String, Int)]()
    for line in lines! {
        let pair = line.components(separatedBy: ",")
        if let frequency = Int(pair[1]) {
            wordAndFrequencyList.append((pair[0].lowercased(), frequency))
        } else {
            wordAndFrequencyList.append((pair[0].lowercased(), Constants.defaultWordFrequency))
        }
    }
    return wordAndFrequencyList
}

func isWordValid(_ word: String) -> Bool {
    let predicate = NSPredicate(format:"SELF MATCHES %@", "[A-Za-z]+")
    return predicate.evaluate(with: word)
}

extension UIViewController {
    var isPresentedModaly: Bool {
        if let index = navigationController?.viewControllers.index(of: self), index > 0 {
            return false
        } else if presentingViewController != nil {
            return true
        } else if navigationController?.presentingViewController?.presentedViewController == navigationController  {
            return true
        } else if tabBarController?.presentingViewController is UITabBarController {
            return true
        } else {
            return false
        }
    }
}

extension String {
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
}

var appVersion: String {
    guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return "" }
    return version
}

var appBuild: String {
    guard let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String else { return "" }
    return build
}

func vibrate() {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
}

func playSoundClick() {
    AudioServicesPlaySystemSound(1123)
}

func playSoundSwipe() {
    AudioServicesPlaySystemSound(1004)
}

func playSoundBackspace() {
    AudioServicesPlaySystemSound(1155)
}

func playSoundWordAdded() {
    AudioServicesPlaySystemSound(1111)
}
