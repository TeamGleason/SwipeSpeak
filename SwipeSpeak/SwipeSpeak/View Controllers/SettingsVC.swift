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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 5 && indexPath.row == 2 {
            askToClearWordRanking()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func askToClearWordRanking() {
        let alertController = UIAlertController(title: NSLocalizedString("Clear Word Ranking", comment: ""),
                                                message: NSLocalizedString("Are you sure you want to clear the world ranking?", comment: ""),
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
        let clearAction = UIAlertAction(title: NSLocalizedString("Clear", comment: ""), style: .destructive) { (action: UIAlertAction) in
            UserPreferences.shared.clearWordRating()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(clearAction)
        
        self.present(alertController, animated: true, completion: nil)
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
