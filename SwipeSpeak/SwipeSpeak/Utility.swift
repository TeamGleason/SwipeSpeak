//
//  Utility.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import UIKit


func getNumberOfKeys() -> Int {
    if UserDefaults.standard.integer(forKey: "keyboard") <= 0 {
        setKeyboardNumber(4)
        return 4
    }
    return UserDefaults.standard.integer(forKey: "keyboard")
}
func setKeyboardNumber(_ keyboard: Int) {
    UserDefaults.standard.set(keyboard, forKey: "keyboard")
}
