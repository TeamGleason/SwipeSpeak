//
//  AboutVC.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 13/11/2017.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import UIKit

class AboutVC: UITableViewController {
    
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        versionLabel.text = NSLocalizedString("Version", comment: "") + " \(appVersion) (\(appBuild))"
    }
    
}
