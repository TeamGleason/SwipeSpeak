//
//  KeyboardSettingsVC.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import UIKit

class KeyboardSettingsVC: UITableViewController {
    let numberOfKeysList = [4, 6, 8]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        var selectedCell: UITableViewCell!
        if getNumberOfKeys() == 4 {
            selectedCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
        } else if getNumberOfKeys() == 6 {
            selectedCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0))
        } else if getNumberOfKeys() == 8 {
            selectedCell = tableView.cellForRow(at: IndexPath(row: 2, section: 0))
        }
        selectedCell.accessoryType = .checkmark
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        for cell in tableView.visibleCells {
            cell.accessoryType = .none
        }
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            
            setKeyboardNumber(numberOfKeysList[indexPath.row])
        }
        
        keyboardSettingsUpdated = true
    }
}
