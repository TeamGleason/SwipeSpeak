//
//  RotationHelperNVC.swift
//  SwipeSpeak
//
//  Created by Daniel Tsirulnikov on 01/01/2018.
//  Copyright © 2018 TeamGleason. All rights reserved.
//

import UIKit

@IBDesignable
class RotationHelperNVC: UINavigationController {
    
    // These properties can be set from Interface Builder
    @IBInspectable
    public var rotatePhone: Bool = false
    
    @IBInspectable
    public var rotatePad: Bool = false
    
    override var shouldAutorotate: Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return rotatePad
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            return rotatePhone
        } else {
            return false
        }
    }
    
}
