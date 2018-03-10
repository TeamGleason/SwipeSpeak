//
//  SpeechVC.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 06/11/2017.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import UIKit
import AVFoundation

class SpeechVC: UITableViewController  {
    
    @IBOutlet weak var voiceLabel: UILabel!
    
    @IBOutlet weak var rateSlider: UISlider!
    @IBOutlet weak var rateLabel: UILabel!

    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var volumeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rateSlider.minimumValue = AVSpeechUtteranceMinimumSpeechRate
        rateSlider.maximumValue = AVSpeechUtteranceMaximumSpeechRate
        
        volumeSlider.minimumValue = 0.0
        volumeSlider.maximumValue = 1.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let voiceIdentifier = UserPreferences.shared.voiceIdentifier,
            let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            voiceLabel.text = (NSLocale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: voice.language)
        } else {
           voiceLabel.text = ""
        }
        
        rateSlider.value = UserPreferences.shared.speechRate
        volumeSlider.value = UserPreferences.shared.speechVolume
        
        rateLabel.text = "\(Int(rateSlider.value*100))%"
        volumeLabel.text = "\(Int(volumeSlider.value*100))%"
    }
    
    @IBAction func rateSliderValueChanged(_ sender: UISlider) {
        rateLabel.text = "\(Int(sender.value*100))%"
        UserPreferences.shared.speechRate = sender.value
        
        SpeechSynthesizer.shared.speak(NSLocalizedString("Speaking Rate", comment: ""))
    }
    
    @IBAction func volumeSliderValueChanged(_ sender: UISlider) {
        volumeLabel.text = "\(Int(sender.value*100))%"
        UserPreferences.shared.speechVolume = sender.value
    }
    
}
