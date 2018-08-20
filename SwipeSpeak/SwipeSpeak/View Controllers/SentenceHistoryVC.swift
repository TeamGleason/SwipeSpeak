//
//  SentenceHistoryVC.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Updated by Daniel Tsirulnikov on 11/9/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import FirebaseAnalytics

class SentenceHistoryVC: UITableViewController {
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    private var sentenceHistory: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString("Sentence History", comment: "")
        
        self.tableView.emptyDataSetSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isPresentedModaly {
            let closeBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_close"),
                                                     style: .plain,
                                                     target: self,
                                                     action: #selector(self.dismissViewController))
            closeBarButtonItem.accessibilityLabel = NSLocalizedString("Close", comment: "")
            self.navigationItem.leftBarButtonItem = closeBarButtonItem
        }
        
        loadSentenceHistory()
        self.tableView.reloadData()
        
        if !sentenceHistory.isEmpty {
            self.navigationItem.rightBarButtonItem = self.editButtonItem
        }
    }
    
    private func loadSentenceHistory() {
        sentenceHistory = Array(UserPreferences.shared.sentenceHistory)
    }
    
    @IBAction func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sentenceHistory.count > 0 ? 2 : 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? sentenceHistory.count : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = indexPath.section == 1 ? "DeleteCell" : "SentenceCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as UITableViewCell
        
        guard cellIdentifier == "SentenceCell" else {
            return cell
        }
        
        let sentenceObject = sentenceHistory[indexPath.row]
        
        if let sentence = sentenceObject[SentenceKeys.sentence] as? String,
            let date = sentenceObject[SentenceKeys.date] as? Date {
            cell.textLabel?.text = sentence
            cell.detailTextLabel?.text = dateFormatter.string(from: date)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 {
            return false
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            UserPreferences.shared.removeSentence(indexPath.row)
            loadSentenceHistory()
            
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.tableView.reloadEmptyDataSet()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        if indexPath.section == 1 {
            askToClearHistory()
            return
        }
        
        let sentenceObject = sentenceHistory[indexPath.row]
        if let sentence = sentenceObject[SentenceKeys.sentence] as? String, !sentence.isEmpty {
            SpeechSynthesizer.shared.speak(sentence)
        }
    }
    
    private func askToClearHistory() {
        let alertController = UIAlertController(title: NSLocalizedString("Clear Sentence History", comment: ""),
                                                message: NSLocalizedString("Are you sure you want to clear the sentence history?", comment: ""),
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
        let clearAction = UIAlertAction(title: NSLocalizedString("Clear", comment: ""), style: .destructive) { [weak self] (action: UIAlertAction) in
            Analytics.logEvent("clear_sentence_history", parameters: nil)
            
            UserPreferences.shared.clearSentenceHistory()
            
            self?.loadSentenceHistory()
            self?.tableView.reloadData()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(clearAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

}

// MARK: - DZNEmptyDataSetSource

extension SentenceHistoryVC: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let title = NSLocalizedString("No History", comment: "")
        let attribute = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .title1),
                         NSAttributedStringKey.foregroundColor: UIColor.darkGray]
        return NSAttributedString(string: title, attributes: attribute)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let subtitle = NSLocalizedString("When you create sentences you will see them here.", comment: "")
        let attribute = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .body),
                         NSAttributedStringKey.foregroundColor: UIColor.lightGray]
        return NSAttributedString(string: subtitle, attributes: attribute)
    }
    
}
