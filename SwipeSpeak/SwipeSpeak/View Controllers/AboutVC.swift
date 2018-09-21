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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            contactPressed()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func contactPressed() {
        let email = "swipespeak@teamgleason.org"
        let subject = NSLocalizedString("SwipeSpeak Feedback", comment: "").addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) ?? NSLocalizedString("Feedback", comment: "")
        
        let urls = [
            NSLocalizedString("Mail", comment: ""): "mailto:\(email)?subject=\(subject)",
            NSLocalizedString("Gmail", comment: ""): "googlegmail:///co?to=\(email)&subject=\(subject)",
            NSLocalizedString("Inbox", comment: ""): "inbox-gmail://co?to=\(email)&subject=\(subject)",
            NSLocalizedString("Outlook", comment: ""): "ms-outlook://compose?to=\(email)&subject=\(subject)"
        ]
        
        func buildOpenAction(title: String, url urlString: String) -> UIAlertAction? {
            guard let url = URL(string: urlString) else { return nil }
            guard UIApplication.shared.canOpenURL(url) else {
                return nil
            }
            
            return UIAlertAction(title: title, style: .default) { (_) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        
        var actions: [UIAlertAction] = []
        for (name, url) in urls {
            if let action = buildOpenAction(title: name, url: url) {
                actions.append(action)
            }
        }
        
        let alertController = UIAlertController(title: NSLocalizedString("Choose an email app:", comment: ""), message: nil, preferredStyle: .actionSheet)
        
        actions.forEach({ action in
            alertController.addAction(action)
        })
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
}
