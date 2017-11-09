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

class SentenceHistoryVC: UITableViewController {
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    private var sentenceHistory: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Sentence History"
        
        self.tableView.emptyDataSetSource = self
        
        loadSentenceHistory()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isPresentedModaly {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissViewController))
        }
        
        loadSentenceHistory()
        self.tableView.reloadData()
    }
    
    func loadSentenceHistory() {
        sentenceHistory = Array(UserPreferences.shared.sentenceHistory)
    }
    
    @IBAction func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sentenceHistory.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SentenceCell", for: indexPath) as UITableViewCell
        
        let sentenceObject = sentenceHistory[indexPath.row]
        let sentence = sentenceObject["sentence"]! as! String
        let date = sentenceObject["date"]! as! Date

        cell.textLabel?.text = sentence
        cell.detailTextLabel?.text = dateFormatter.string(from: date)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            UserPreferences.shared.removeSentence(indexPath.row)
            loadSentenceHistory()
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.tableView.reloadEmptyDataSet()
        }
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
        let subtitle = NSLocalizedString("When you create sentances you will see them here.", comment: "")
        let attribute = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .body),
                         NSAttributedStringKey.foregroundColor: UIColor.lightGray]
        return NSAttributedString(string: subtitle, attributes: attribute)
    }
    
}
