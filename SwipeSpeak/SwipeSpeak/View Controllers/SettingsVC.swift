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
    @IBOutlet weak var keyboardLayoutLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        numLetterSwitch.isOn = getAudioCueNumLetterSwitch()
        pauseSwitch.isOn = getBuildWordPauseSwitch()
        
        let keys = getNumberOfKeys()
        keyboardLayoutLabel.text = NSLocalizedString("\(keys) Keys", comment: "")

    }
    
    @IBAction func dismissViewController() {
        dismiss(animated: true, completion: nil)
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
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Reload the image for the tint to take effect
        cell.imageView?.tintColor = UIColor.lightGray
        cell.imageView?.image = cell.imageView?.image?.withRenderingMode(.alwaysTemplate)
    }
}
