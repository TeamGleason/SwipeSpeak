//
//  UserAddedWordListVC.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Updated by Daniel Tsirulnikov on 11/9/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class UserAddedWordListVC: UITableViewController {
    
    private var userAddedWords: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Added Words", comment: "")
        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .add,
                                                                   target: self,
                                                                   action: #selector(self.addWordButtonTouched)),
                                                   self.editButtonItem]
        
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadUserAddedWords()
        self.tableView.reloadData()
    }
    
    private func loadUserAddedWords() {
        userAddedWords = Array(UserPreferences.shared.userAddedWords)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userAddedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = userAddedWords[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            UserPreferences.shared.removeWord(indexPath.row)
            loadUserAddedWords()
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.tableView.reloadEmptyDataSet()
        }
    }
    
    @objc func addWordButtonTouched() {
        let alertController = UIAlertController(title: "Add Word",
                                                message: "Please do not include punctuations or spaces",
                                                preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Add", style: .default) { (_) in
            guard let textFields = alertController.textFields else { return }
            guard let textField = textFields.first else { return }
            guard let text = textField.text else { return }
            guard isWordValid(text) else { return }

            UserPreferences.shared.addWord(text)
            self.loadUserAddedWords()
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            self.tableView.reloadEmptyDataSet()
        }
        
        saveAction.isEnabled = false
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        alertController.addTextField { (textField) in
            textField.text = ""
            textField.clearButtonMode = .whileEditing
            //textField.keyboardType = .asciiCapable
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main, using: { _ in
                if let text = textField.text, isWordValid(text) {
                    saveAction.isEnabled = true
                } else {
                    saveAction.isEnabled = false
                }
            })
        }
        
        present(alertController, animated: true, completion: nil)
        alertController.view.tintColor = UIColor.darkGray
    }
    
    /*
    @objc func clearWordsButtonTouched() {
        let alertController = UIAlertController(title: "Clear Words",
                                                message: "Are you sure you want to clear all added words?",
                                                preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Clear", style: .destructive) { (_) in
            UserPreferences.shared.clearWords()
            self.loadUserAddedWords()
            self.tableView.reloadData()
            self.tableView.reloadEmptyDataSet()
            
            userAddedWordListUpdated = true
        }
        alertController.addAction(saveAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
 */
    
}

// MARK: - DZNEmptyDataSetSource

extension UserAddedWordListVC: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let title = NSLocalizedString("No Added Words", comment: "")
        let attribute = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .title1),
                         NSAttributedStringKey.foregroundColor: UIColor.darkGray]
        return NSAttributedString(string: title, attributes: attribute)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let subtitle = NSLocalizedString("When you add words you will see them here.", comment: "")
        let attribute = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .body),
                         NSAttributedStringKey.foregroundColor: UIColor.lightGray]
        return NSAttributedString(string: subtitle, attributes: attribute)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        let title = NSLocalizedString("Add Word", comment: "")
        let attribute = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .headline),
                         NSAttributedStringKey.foregroundColor: UIColor.darkGray]
        return NSAttributedString(string: title, attributes: attribute)
    }
}

// MARK: - DZNEmptyDataSetDelegate

extension UserAddedWordListVC: DZNEmptyDataSetDelegate {
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        addWordButtonTouched()
    }
    
}
