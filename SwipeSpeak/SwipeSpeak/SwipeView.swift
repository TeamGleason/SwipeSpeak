//
//  SwipeView.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class SwipeView: UIView {
    var swipeDirectionList = [Int]()
    
    var path = UIBezierPath()
    var previousPoint: CGPoint
    
    var keyboardView = UIView()
    var keyViewList = [UILabel]()
    
    override init(frame: CGRect) {
        previousPoint = CGPoint.zero
        super.init(frame: frame)
    }
    
    init(frame: CGRect, keyboardView: UIView, keyViewList: [UILabel]) {
        previousPoint = CGPoint.zero
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        
        self.keyboardView = keyboardView
        self.keyViewList = keyViewList
        
        self.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
        pan.maximumNumberOfTouches = 1
        self.addGestureRecognizer(pan)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        previousPoint = CGPoint.zero
        super.init(coder: aDecoder)
    }
    
    
    override func draw(_ rect: CGRect) {
        UIColor.red.setStroke()
        path.lineWidth = 4.0
        path.stroke()
    }
    
    
    func swipeToKey(_ velocity: CGPoint) -> Int {
        var degree = (Double)(atan2(velocity.y, velocity.x)) * 180 / Double.pi
        if (degree < 0) { degree += 360 }
        
        if getNumberOfKeys() == 4 {
            if (315 <= degree && degree <= 360) || (0 <= degree && degree < 45) {
                return 1
            } else if (45 <= degree && degree < 135) {
                return 3
            } else if (135 <= degree && degree < 225) {
                return 2
            } else if (225 <= degree && degree < 315) {
                return 0
            }
        } else if getNumberOfKeys() == 6 {
            let unit = 22.5
            if (unit*15 <= degree && degree <= 360) || (0 <= degree && degree < unit*2) {
                return 3
            } else if (unit*2 <= degree && degree < unit*6) {
                return 5
            } else if (unit*6 <= degree && degree < unit*9) {
                return 4
            } else if (unit*9 <= degree && degree < unit*11) {
                return 2
            } else if (unit*11 <= degree && degree < unit*13) {
                return 1
            } else if (unit*13 <= degree && degree < unit*15) {
                return 0
            }
        } else if getNumberOfKeys() == 8 {
            let unit = 22.5
            if (unit*15 <= degree && degree <= 360) || (0 <= degree && degree < unit) {
                return 3
            } else if (unit <= degree && degree < unit*3) {
                return 5
            } else if (unit*3 <= degree && degree < unit*5) {
                return 6
            } else if (unit*5 <= degree && degree < unit*7) {
                return 7
            } else if (unit*7 <= degree && degree < unit*9) {
                return 4
            } else if (unit*9 <= degree && degree < unit*11) {
                return 2
            } else if (unit*11 <= degree && degree < unit*13) {
                return 1
            } else if (unit*13 <= degree && degree < unit*15) {
                return 0
            }
        }
        return 0
    }
    
    func handleTap(_ recognizer:UITapGestureRecognizer) {
        let currentPoint = recognizer.location(in: self)
        let pointInKeyboardView = CGPoint(x: currentPoint.x - keyboardView.frame.minX, y: currentPoint.y - keyboardView.frame.minY)
        for i in 0 ..< keyViewList.count {
            if keyViewList[i].frame.contains(pointInKeyboardView) {
                AudioServicesPlaySystemSound(1105)

                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "KeyEntered"), object: i)
                return
            }
        }
    }
    
    func handleSwipe(_ recognizer:UIPanGestureRecognizer) {
        let currentPoint = recognizer.location(in: self)
        let midPoint = CGPoint(x: (previousPoint.x + currentPoint.x) / 2,
                               y: (previousPoint.y + currentPoint.y) / 2)
        
        switch recognizer.state {
        case .began:
            // When user starts swipe gesture, reset directionCount.
            swipeDirectionList = Array<Int>(repeating: 0, count: getNumberOfKeys())
            
            // Make sure we clean previous gesture.
            path.removeAllPoints()
            path.move(to: currentPoint)
            break
        case .changed:
            // When user is doing swipe gesture, find current velocity direction.
            let velocity = recognizer.velocity(in: self)
            swipeDirectionList[swipeToKey(velocity)] += 1
            
            // Add curve.
            path.addQuadCurve(to: midPoint, controlPoint: previousPoint)
            break
        case .ended:
            // When user completes swipe gesture, find the majority velocity direction during the swipe.
            let majorityDirection = (Int)(swipeDirectionList.index(of: swipeDirectionList.max()!)!)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "KeyEntered"), object: majorityDirection)
            
            AudioServicesPlaySystemSound(1004)
            
            // Clean the path.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.path.removeAllPoints()
                self.setNeedsDisplay()
            }
            break
        default:
            break
        }
        
        previousPoint = currentPoint
        self.setNeedsDisplay()
    }
}
