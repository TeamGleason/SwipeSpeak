//
//  VoicesVC.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 05/11/2017.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import UIKit
import AVFoundation

class VoicesVC: UITableViewController {

    private lazy var voices: [AVSpeechSynthesisVoice] = {
        return AVSpeechSynthesisVoice.speechVoices().filter({ (voice) -> Bool in
            return voice.language.range(of: "en-") != nil
        })
    }()
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voices.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("English Voices", comment: "")
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "voiceCell", for: indexPath)

        let voice = voices[indexPath.row]
        cell.textLabel?.text = voice.name
        cell.detailTextLabel?.text = (NSLocale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: voice.language)

        if let voiceIdentifier = UserPreferences.shared.voiceIdentifier, voiceIdentifier == voice.identifier {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let voice = voices[indexPath.row]

        UserPreferences.shared.voiceIdentifier = voice.identifier
        
        SpeechSynthesizer.shared.speak(NSLocalizedString("Hello, this is \(voice.name)", comment: ""), voice.identifier)
        
        for cell in tableView.visibleCells {
            if tableView.indexPath(for: cell) == indexPath {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }


}
