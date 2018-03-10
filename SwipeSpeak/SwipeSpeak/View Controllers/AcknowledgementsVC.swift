//
//  AcknowledgementsVC.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 06/12/2017.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import UIKit
import MarkdownView

class AcknowledgementsVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mdView = self.view as? MarkdownView else {
            return
        }
        
        guard let path = Bundle.main.path(forResource: "Pods-SwipeSpeak-acknowledgements", ofType: "markdown") else {
            return
        }
        
        let url = URL(fileURLWithPath: path)
        let markdown = try! String(contentsOf: url, encoding: String.Encoding.utf8)
        
        mdView.load(markdown: markdown, enableImage: false)
    }

}
