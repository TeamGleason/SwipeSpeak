//
//  UserAddedWordListVC.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import UIKit

class UserAddedWordListVC: UITableViewController {
    var userAddedWordList = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "User-added Words"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Word", style: .plain, target: self, action: #selector(self.addWordButtonTouched))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        userAddedWordListUpdated = true
        userAddedWordList.removeAll()
        
        let filePath = fileInDocumentsDirectory("", fileName: userAddedWordListName)
        if !FileManager.default.fileExists(atPath: filePath) {
            saveWordList()
        } else {
            if let wordAndFrequencyList = getWordAndFrequencyListFromCSV(filePath) {
                for pair in wordAndFrequencyList {
                    userAddedWordList.append(pair.0)
                }
            }
        }
        
        self.tableView.reloadData()
    }
        
    // Update number of rows in tableview (only one section in the tableview).
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userAddedWordList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = userAddedWordList[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            userAddedWordList.remove(at: indexPath.row)
            self.tableView.reloadData()
            self.saveWordList()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func isValidWord(_ textField: UITextField) -> Bool {
        if let word = textField.text {
            let emailTest = NSPredicate(format:"SELF MATCHES %@", "[A-Za-z]+")
            return emailTest.evaluate(with: word)
        }
        return false
    }
    
    func addWordButtonTouched() {
        let alertController = UIAlertController(title: "Add a word", message: "Please do not include punctuation or space.", preferredStyle: .alert)
        
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            let textField = alertController.textFields![0] as UITextField
            if (textField.text != nil) && textField.text!.characters.count > 0 {
                self.userAddedWordList.insert(textField.text!, at: 0)
                self.tableView.reloadData()
                
                self.saveWordList()
            }
        }
        saveAction.isEnabled = false
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        alertController.addTextField { (textField) in
            textField.text = ""
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main, using: { _ in
                saveAction.isEnabled = self.isValidWord(textField)
            })
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func saveWordList() {
        let wordList = fileInDocumentsDirectory("", fileName: userAddedWordListName)
        var file = ""
        for word in self.userAddedWordList {
            file.append(word + "," + "" + "\n")
        }
        do {
            try file.write(toFile: wordList, atomically: false, encoding: String.Encoding.utf8)
        } catch {}
    }
}
