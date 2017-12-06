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

// Constants
let addedWordFreq = 9999999
let buttonBackgroundColor = UIColor.init(white: 67/255, alpha: 1)
let buttonGreenColor = UIColor.init(red: 61/255, green: 193/255, blue: 71/255, alpha: 1)
let buildWordButtonText = "Build Word"
let screenW = UIScreen.main.bounds.width
let screenH = UIScreen.main.bounds.height
let numPredictionLabels = 8
let keyLetterGrouping4Keys = ["abcdef", "ghijkl", "mnopqrs", "tuvwxyz"]
let keyLetterGrouping6Keys = ["abcd", "efgh", "ijkl", "mnop", "qrstu", "vwxyz"]
let keyLetterGrouping8Keys = ["abc", "def", "ghi", "jkl", "mno", "pqrs", "tuv", "wxyz"]
let keyLetterGroupingSteve = ["abcd", "efgh", "ijkl", "mnop", "qrst", "uvwxyz"]
let audioCue4Keys = ["Up", "Left", "Right", "Down"]
let audioCue6Keys = ["Up Left", "Up", "Up Right", "Left", "Right", "Down"]
let audioCue8Keys = ["Up Left", "Up", "Up Right", "Left", "Right", "Down Left", "Down", "Down Right"]

// Global
var userAddedWordListUpdated = false
var keyboardSettingsUpdated = false

func fileInDocumentsDirectory(_ folderName: String, fileName: String) -> String {
    var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    if folderName != "" {
        url = url.appendingPathComponent(folderName)
    }
    url = url.appendingPathComponent(fileName)
    return url.path
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
            wordAndFrequencyList.append((pair[0].lowercased(), addedWordFreq))
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

var appVersion: String {
    return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
}

var appBuild: String {
    return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
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
