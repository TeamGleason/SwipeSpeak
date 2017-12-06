//
//  AboutVC.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 13/11/2017.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import UIKit

class AboutVC: UITableViewController {
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "\(appVersion) (\(appBuild))"
    }
    
}
