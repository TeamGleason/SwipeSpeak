//
//  SentenceHistoryVC.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//


import Foundation
import UIKit

class SentenceHistoryVC: UITableViewController {
    var sentenceHistoryList = [(String, String)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Entered Sentence History"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let filePath = fileInDocumentsDirectory("", fileName: sentenceHistoryName)
        if FileManager.default.fileExists(atPath: filePath) {
            sentenceHistoryList = getSentenceHistoryFromCSV(filePath)
        }
        
        self.tableView.reloadData()
    }
    
    // Update number of rows in tableview (only one section in the tableview).
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sentenceHistoryList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm"

        let cell = tableView.dequeueReusableCell(withIdentifier: "SentenceCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = sentenceHistoryList[indexPath.row].0
        cell.detailTextLabel?.text = dateFormatter.string(from: Date(timeIntervalSince1970: Double(sentenceHistoryList[indexPath.row].1)!))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            sentenceHistoryList.remove(at: indexPath.row)
            self.tableView.reloadData()
            self.saveWordList()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func saveWordList() {
        let wordList = fileInDocumentsDirectory("", fileName: sentenceHistoryName)
        var file = ""
        for pair in self.sentenceHistoryList {
            file.append(pair.0 + "," + pair.1 + "\n")
        }
        do {
            try file.write(toFile: wordList, atomically: false, encoding: String.Encoding.utf8)
        } catch {}
    }
}
