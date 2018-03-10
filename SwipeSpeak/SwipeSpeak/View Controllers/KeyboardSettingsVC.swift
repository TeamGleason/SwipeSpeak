//
//  KeyboardSettingsVC.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Updated by Daniel Tsirulnikov on 11/9/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import UIKit

class KeyboardSettingsVC: UITableViewController {
    
    private let rowLayoutMap: [Int: KeyboardLayout] = [0: .keys4,
                                                       1: .keys6,
                                                       2: .keys8,
                                                       3: .strokes2]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let row: Int
        switch UserPreferences.shared.keyboardLayout {
        case .keys4:
            row = 0
        case .keys6:
            row = 1
        case .keys8:
            row = 2
        case .strokes2:
            row = 3
        }
        
        if let selectedCell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) {
            selectedCell.accessoryType = .checkmark
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        for cell in tableView.visibleCells {
            cell.accessoryType = .none
        }
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            
            UserPreferences.shared.keyboardLayout = rowLayoutMap[indexPath.row]!
        }
    }
}
