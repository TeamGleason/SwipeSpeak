//
//  SettingsVC.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Updated by Daniel Tsirulnikov on 11/9/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import UIKit

class SettingsVC: UITableViewController {
    
    @IBOutlet weak var keyboardLayoutLabel: UILabel!

    @IBOutlet weak var announceLettersCountSwitch: UISwitch!
    @IBOutlet weak var vibrateSwitch: UISwitch!

    @IBOutlet weak var longerPauseBetweenLettersSwitch: UISwitch!
 
    @IBOutlet weak var enableAudioFeedbackSwitch: UISwitch!
    @IBOutlet weak var enableCouldSyncSwitch: UISwitch!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        keyboardLayoutLabel.text = UserPreferences.shared.keyboardLayout.localizedString()

        announceLettersCountSwitch.isOn = UserPreferences.shared.announceLettersCount
        vibrateSwitch.isOn = UserPreferences.shared.vibrate
        
        longerPauseBetweenLettersSwitch.isOn = UserPreferences.shared.longerPauseBetweenLetters

        enableAudioFeedbackSwitch.isOn = UserPreferences.shared.audioFeedback
        enableCouldSyncSwitch.isOn = UserPreferences.shared.enableCloudSync
    }
    
    @IBAction func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Reload the image for the tint to take effect
        cell.imageView?.tintColor = UIColor.lightGray
        cell.imageView?.image = cell.imageView?.image?.withRenderingMode(.alwaysTemplate)
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if sender === announceLettersCountSwitch {
            UserPreferences.shared.announceLettersCount = sender.isOn
        } else if sender === vibrateSwitch {
            UserPreferences.shared.vibrate = sender.isOn
        } else if sender === longerPauseBetweenLettersSwitch {
            UserPreferences.shared.longerPauseBetweenLetters = sender.isOn
        } else if sender === enableAudioFeedbackSwitch {
            UserPreferences.shared.audioFeedback = sender.isOn
        } else if sender === enableCouldSyncSwitch {
            UserPreferences.shared.enableCloudSync = sender.isOn
        }
    }
    
}
