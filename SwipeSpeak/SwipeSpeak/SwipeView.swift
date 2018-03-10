//
//  SwipeView.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Updated by Daniel Tsirulnikov on 11/9/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation
import UIKit

protocol SwipeViewDelegate {
    func keyEntered(key: Int)
    func firstStrokeEntered(key: Int)
    func secondStrokeEntered(key: Int)
}

// MARK: -

class SwipeView: UIView {
    
    // MARK: Properties
    
    private var swipeDirectionList = [Int]()
    var firstStroke: Int?
    
    private var path = UIBezierPath()
    private var previousPoint: CGPoint = CGPoint.zero
    
    private let keyboardContainerView: UIView?
    private let keyboardLabels: [UILabel]
    
    var delegate: SwipeViewDelegate?
    
    // MARK: - Initialization
    
    init(frame: CGRect, keyboardContainerView: UIView, keyboardLabels: [UILabel], isTwoStrokes: Bool, delegate: SwipeViewDelegate) {
        self.keyboardContainerView = keyboardContainerView
        self.keyboardLabels = keyboardLabels
        self.delegate = delegate
        
        super.init(frame: frame)
        
        setup(isTwoStrokes: isTwoStrokes)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.keyboardContainerView = nil
        self.keyboardLabels = []

        super.init(coder: aDecoder)
        
        setup()
    }
    
    private func setup(isTwoStrokes: Bool = false) {
        self.backgroundColor = UIColor.clear
        
        self.isUserInteractionEnabled = true
        
        if isTwoStrokes {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(self.handleSwipeTwoStrokes(_:)))
            pan.maximumNumberOfTouches = 1
            self.addGestureRecognizer(pan)
        } else {
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
            self.addGestureRecognizer(tap)
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
            pan.maximumNumberOfTouches = 1
            self.addGestureRecognizer(pan)
        }
    }
    
    // MARK: - UIView

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = keyboardContainerView?.hitTest(point, with: event) else {
            return super.hitTest(point, with: event)
        }
        
        // Pass pass through events to keyboard labels
        for keyView in keyboardLabels {
            if keyView === hitView {
                return super.hitTest(point, with: event)
            }
        }
        
        // Pass pass through events to labels and buttons
        if hitView is UILabel || hitView is UIButton {
            return hitView
        }
        
        return super.hitTest(point, with: event)
    }
    
    // MARK: - UIViewRendering
    
    override func draw(_ rect: CGRect) {
        UIColor.red.setStroke()
        path.lineWidth = 4.0
        path.stroke()
    }
    
    // MARK: - Handle Swipe
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        let currentPoint = recognizer.location(in: keyboardContainerView)

        guard let hitView = keyboardContainerView?.hitTest(currentPoint, with: nil) else {
            return
        }
        
        for i in 0 ..< keyboardLabels.count {
            if hitView === keyboardLabels[i] {
                if UserPreferences.shared.audioFeedback {
                    playSoundClick()
                }
                
                delegate?.keyEntered(key: i)
                return
            }
        }
    }
    
    @objc func handleSwipe(_ recognizer: UIPanGestureRecognizer) {
        let currentPoint = recognizer.location(in: self)
        let midPoint = CGPoint(x: (previousPoint.x + currentPoint.x) / 2,
                               y: (previousPoint.y + currentPoint.y) / 2)
        
        switch recognizer.state {
        case .began:
            // When user starts swipe gesture, reset directionCount.
            swipeDirectionList = Array<Int>(repeating: 0, count: UserPreferences.shared.keyboardLayout.rawValue)
            
            // Make sure we clean previous gesture.
            path.removeAllPoints()
            path.move(to: currentPoint)
            break
        case .changed:
            // When user is doing swipe gesture, find current velocity direction.
            let velocity = recognizer.velocity(in: self)
            let keyIndex = SwipeView.keyIndexForSwipe(velocity: velocity, numberOfKeys: UserPreferences.shared.keyboardLayout.rawValue)
            swipeDirectionList[keyIndex] += 1
            
            // Add curve.
            path.addQuadCurve(to: midPoint, controlPoint: previousPoint)
            break
        case .ended:
            // When user completes swipe gesture, find the majority velocity direction during the swipe.
            guard let max = swipeDirectionList.max(), max > 0 else {
                return
            }
            
            let majorityDirection = swipeDirectionList.index(of: max)!
            delegate?.keyEntered(key: majorityDirection)
            
            if UserPreferences.shared.vibrate {
                vibrate()
            }
            
            if UserPreferences.shared.audioFeedback {
                playSoundSwipe()
            }
            
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
    
    @objc func handleSwipeTwoStrokes(_ recognizer: UIPanGestureRecognizer) {
        let currentPoint = recognizer.location(in: self)
        let midPoint = CGPoint(x: (previousPoint.x + currentPoint.x) / 2,
                               y: (previousPoint.y + currentPoint.y) / 2)
        
        switch recognizer.state {
        case .began:
            // When user starts swipe gesture, reset directionCount.
            swipeDirectionList = Array<Int>(repeating: 0, count: 6)
            
            // Make sure we clean previous gesture.
            path.removeAllPoints()
            path.move(to: currentPoint)
            break
        case .changed:
            // When user is doing swipe gesture, find current velocity direction.
            let velocity = recognizer.velocity(in: self)
            let numberOfKeys: Int
            
            if firstStroke == nil {
                numberOfKeys = -1
            } else {
                if firstStroke == 5 {
                    numberOfKeys = -3
                } else {
                    numberOfKeys = -2
                }
            }
            
            let keyIndex = SwipeView.keyIndexForSwipe(velocity: velocity, numberOfKeys: numberOfKeys)
            swipeDirectionList[keyIndex] += 1
            
            // Add curve.
            path.addQuadCurve(to: midPoint, controlPoint: previousPoint)
            break
        case .ended:
            // When user completes swipe gesture, find the majority velocity direction during the swipe.
            guard let max = swipeDirectionList.max(), max > 0 else {
                return
            }
            
            let majorityDirection = swipeDirectionList.index(of: max)!
            
            if firstStroke == nil {
                delegate?.firstStrokeEntered(key: majorityDirection)
                firstStroke = majorityDirection
                
                if UserPreferences.shared.vibrate {
                    vibrate()
                }
                
                if UserPreferences.shared.audioFeedback {
                    playSoundSwipe()
                }
            } else {
                let letterValue = Int((UnicodeScalar(String(Constants.keyLetterGroupingSteve[firstStroke!][majorityDirection]))?.value)!)
                delegate?.secondStrokeEntered(key: letterValue)
                
                firstStroke = nil
                
                if UserPreferences.shared.vibrate {
                    vibrate()
                }
                
                if UserPreferences.shared.audioFeedback {
                    playSoundSwipe()
                }
            }
            
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

// MARK: - Helper

extension SwipeView {
    
    fileprivate static func keyIndexForSwipe(velocity: CGPoint, numberOfKeys: Int) -> Int {
        var degree = Double(atan2(velocity.y, velocity.x)) * 180 / Double.pi
        if (degree < 0) {
            degree += 360
        }
        
        if numberOfKeys == 4 {
            if (315 <= degree && degree <= 360) || (0 <= degree && degree < 45) {
                return 1
            } else if (45 <= degree && degree < 135) {
                return 3
            } else if (135 <= degree && degree < 225) {
                return 2
            } else if (225 <= degree && degree < 315) {
                return 0
            }
        } else if numberOfKeys == 6 {
            if (0 <= degree && degree < 60) {
                return 3
            } else if (60 <= degree && degree < 120) {
                return 4
            } else if (120 <= degree && degree < 180) {
                return 5
            } else if (180 <= degree && degree < 240) {
                return 2
            } else if (240 <= degree && degree < 300) {
                return 1
            } else if (300 <= degree && degree <= 360) {
                return 0
            }
        } else if numberOfKeys == 8 {
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
        } else if numberOfKeys == -1 { // 6 directions for Steve keyboard layout, stroke 1
            if (0 <= degree && degree < 60) {
                return 3
            } else if (60 <= degree && degree < 120) {
                return 4
            } else if (120 <= degree && degree < 180) {
                return 5
            } else if (180 <= degree && degree < 240) {
                return 2
            } else if (240 <= degree && degree < 300) {
                return 1
            } else if (300 <= degree && degree <= 360) {
                return 0
            }
        } else if numberOfKeys == -2 { // 4 directions for Steve keyboard layout, stroke 2
            if (315 <= degree && degree <= 360) || (0 <= degree && degree < 45) {
                return 0
            } else if (45 <= degree && degree < 135) {
                return 3
            } else if (135 <= degree && degree < 225) {
                return 2
            } else if (225 <= degree && degree < 315) {
                return 1
            }
        } else if numberOfKeys == -3 { // 6 directions(include Y,Z) for Steve keyboard layout, stroke 2
            let unit = 22.5
            if (unit*14 <= degree && degree <= 360) || (0 <= degree && degree < unit) {
                return 0
            } else if (unit <= degree && degree < unit*3) {
                return 4
            } else if (unit*3 <= degree && degree < unit*5) {
                return 3
            } else if (unit*5 <= degree && degree < unit*7) {
                return 5
            } else if (unit*7 <= degree && degree < unit*10) {
                return 2
            } else if (unit*10 <= degree && degree < unit*14) {
                return 1
            }
        }
        return 0
    }
    
}

