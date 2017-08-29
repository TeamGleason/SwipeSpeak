//
//  SettingsVC.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import UIKit

class SettingsVC: UITableViewController {
    @IBOutlet weak var numLetterSwitch: UISwitch!
    @IBOutlet weak var pauseSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = false
        
        numLetterSwitch.isOn = getAudioCueNumLetterSwitch()
        pauseSwitch.isOn = getBuildWordPauseSwitch()
    }
    
    @IBAction func numLetterSwitchTouched(_ sender: UISwitch) {
        if sender.isOn {
            setAudioCueNumLetterSwitch(true)
        } else {
            setAudioCueNumLetterSwitch(false)
        }
    }
    
    @IBAction func pauseSwitchTouched(_ sender: UISwitch) {
        if sender.isOn {
            setBuildWordPauseSwitch(true)
        } else {
            setBuildWordPauseSwitch(false)
        }
    }
}
