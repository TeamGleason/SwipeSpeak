//
//  ViewController.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import UIKit
import AVFoundation

class MainVC: UIViewController {
    var sentenceLabel: UILabel!
    var wordLabel: UILabel!
    var backspaceButton: UIButton!
    var wordPredictionView: UIView!
    
    // Text to Speech
    let synthesizer = AVSpeechSynthesizer()
    
    var swipeView: SwipeView!
    var settingsButton = UIButton()
    
    // Predictive Text Dictionary
    var wordPredictionEngine: WordPredictionEngine!
    var enteredKeyList = [Int]()
    var keyViewList = [UILabel]()
    var keyboardView = UIView()
    var keyLetterGrouping = [String]()
    var predictionLabels = [UILabel]()
    
    // Build Word Mode
    var buildWordTimer = Timer()
    var buildWordProgressIndex = 0
    var buildWordLetterIndex = -1
    var buildWordResult = ""
    var buildWordConfirmButton = UIButton()
    var buildWordCancelButton = UIButton()
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupWordPredictionEngine()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyEntered), name: NSNotification.Name(rawValue: "KeyEntered"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(firstStrokeEntered), name: NSNotification.Name(rawValue: "FirstStrokeEntered"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(secondStrokeEntered), name: NSNotification.Name(rawValue: "SecondStrokeEntered"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        
        if userAddedWordListUpdated || keyboardSettingsUpdated {
            setupUI()
            setupWordPredictionEngine()
            userAddedWordListUpdated = false
            keyboardSettingsUpdated = false
        }
    }
    
    func setupWordPredictionEngine() {
        wordPredictionEngine = WordPredictionEngine()
        wordPredictionEngine.setKeyLetterGrouping(keyLetterGrouping)
        
        if let filePath = Bundle.main.path(forResource: "WordList", ofType: "csv") {
            if let wordAndFrequencyList = getWordAndFrequencyListFromCSV(filePath) {
                for pair in wordAndFrequencyList {
                    wordPredictionEngine.insert(pair.0, frequency: pair.1)
                }
            }
        }
        
        let filePath = fileInDocumentsDirectory("", fileName: userAddedWordListName)
        if FileManager.default.fileExists(atPath: filePath) {
            if let wordAndFrequencyList = getWordAndFrequencyListFromCSV(filePath) {
                for pair in wordAndFrequencyList {
                    wordPredictionEngine.insert(pair.0, frequency: pair.1)
                }
            }
        }
    }
    
    func setupUI() {
        for v in self.view.subviews {
            v.removeFromSuperview()
        }
        
        setupKeyboard()
        
        swipeView = SwipeView(frame: CGRect(x: 0, y: 0, width: screenW, height: screenH),
                              keyboardView: keyboardView,
                              keyViewList:  keyViewList,
                              isTwoStrokes: getNumberOfKeys() == -1)
        self.view.addSubview(swipeView)
        
        sentenceLabel = UILabel(frame: CGRect(x: 0, y: 30, width: screenW - 60, height: 60))
        sentenceLabel.text = ""
        sentenceLabel.backgroundColor = UIColor.white
        sentenceLabel.font = UIFont.systemFont(ofSize: 30)
        sentenceLabel.isUserInteractionEnabled = true
        sentenceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.sentenceLabelTouched)))
        sentenceLabel.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.sentenceLabelLongPressed)))
        self.view.addSubview(sentenceLabel)
        
        wordLabel = UILabel(frame: CGRect(x: 0, y: 140, width: screenW, height: 60))
        wordLabel.text = ""
        wordLabel.backgroundColor = UIColor.white
        wordLabel.font = UIFont.boldSystemFont(ofSize: 30)
        wordLabel.isUserInteractionEnabled = true
        self.view.addSubview(wordLabel)
        
        backspaceButton = UIButton(frame: CGRect(x: screenW - 60, y: 0, width: 60, height: 60))
        backspaceButton.setImage(UIImage(named: "Backspace"), for: .normal)
        backspaceButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.backspace)))
        backspaceButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.backspaceAll)))
        wordLabel.addSubview(backspaceButton)
        
        wordPredictionView = UIView(frame: CGRect(x: 0, y: 220, width: screenW, height: 100))
        self.view.addSubview(wordPredictionView)
        
        buildWordConfirmButton = UIButton(frame: CGRect(x: 0, y: wordPredictionView.frame.minY, width: (screenW - 5)/2, height: 50))
        buildWordConfirmButton.setTitle("Confirm", for: .normal)
        buildWordConfirmButton.setTitleColor(UIColor.white, for: .normal)
        buildWordConfirmButton.backgroundColor = buttonGreenColor
        buildWordConfirmButton.addTarget(self, action: #selector(self.buildWordConfirmButtonTouched), for: .touchUpInside)
        buildWordConfirmButton.isHidden = true
        self.view.addSubview(buildWordConfirmButton)
        
        buildWordCancelButton = UIButton(frame: CGRect(x: screenW - (screenW - 5)/2, y: wordPredictionView.frame.minY, width: (screenW - 5)/2, height: 50))
        buildWordCancelButton.setTitle("Cancel", for: .normal)
        buildWordCancelButton.setTitleColor(UIColor.white, for: .normal)
        buildWordCancelButton.backgroundColor = buttonBackgroundColor
        buildWordCancelButton.addTarget(self, action: #selector(self.buildWordCancelButtonTouched), for: .touchUpInside)
        buildWordCancelButton.isHidden = true
        self.view.addSubview(buildWordCancelButton)
        
        settingsButton = UIButton(frame: CGRect(x: screenW - 60, y: 30, width: 60, height: 60))
        settingsButton.setImage(UIImage(named:"Settings"), for: .normal)
        settingsButton.addTarget(self, action: #selector(self.settingsButtonTouched), for: .touchUpInside)
        self.view.addSubview(settingsButton)
        
        setupPredictionLabels()
        
        backspaceAll()
        resetBuildWordMode()
    }
    
    func setupPredictionLabels() {
        if predictionLabels.count != 0 {
            predictionLabels.removeAll()
        }
        
        for i in 0 ..< 8 {
            let pixelOfGap: CGFloat = 2
            let width: CGFloat = (wordPredictionView.frame.width - pixelOfGap) / 4
            let height: CGFloat = (wordPredictionView.frame.height - pixelOfGap) / 2
            let predictionLabel = UILabel()
            predictionLabel.font = predictionLabel.font.withSize(20)
            predictionLabel.textColor = UIColor.white
            predictionLabel.frame = CGRect(x: CGFloat(i%4) * (width + pixelOfGap), y: CGFloat(i/4) * (height + pixelOfGap), width: width, height: height)
            predictionLabel.backgroundColor = buttonBackgroundColor
            predictionLabel.adjustsFontSizeToFitWidth = true
            wordPredictionView.addSubview(predictionLabel)
            predictionLabels.append(predictionLabel)
            
            predictionLabel.isUserInteractionEnabled = true
            predictionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.readAloudLabel(_:))))
            predictionLabel.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.addWordToSentence(_:))))
        }
        
        let buildWordButton = predictionLabels.last!
        buildWordButton.font = UIFont.boldSystemFont(ofSize: 16)
        buildWordButton.backgroundColor = UIColor.orange
        buildWordButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.buildWordButtonTouched)))
    }
    
    func setupKeyboard() {
        keyboardView.removeFromSuperview()
        
        switch getNumberOfKeys() {
        case 4:
            let keyW: CGFloat = 140
            let keyH: CGFloat = 100
            let keyGap: CGFloat = 5
            keyboardView = UIView(frame: CGRect(x: screenW - (keyW*2+keyGap), y: screenH - (keyH*3+keyGap*2), width: keyW*2+keyGap, height: keyH*3+keyGap*2))
            keyViewList = [
                UILabel(frame: CGRect(x: (keyW+keyGap)/2, y: 0,                 width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: keyW+keyGap,     y: keyH + keyGap,     width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: 0,               y: keyH + keyGap,     width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: (keyW+keyGap)/2, y: (keyH + keyGap)*2, width: keyW, height: keyH))
            ]
            keyLetterGrouping = keyLetterGrouping4Keys
            break
        case 6:
            let keyW: CGFloat = 110
            let keyH: CGFloat = 100
            let keyGap: CGFloat = 3
            keyboardView = UIView(frame: CGRect(x: screenW - (keyW*3+keyGap*2), y: screenH - (keyH*3+keyGap*2), width: keyW*3+keyGap*2, height: keyH*3+keyGap*2))
            keyViewList = [
                UILabel(frame: CGRect(x: (keyW+keyGap)*2, y: 0,                 width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: keyW+keyGap,     y: 0,                 width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: 0,               y: 0,                 width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: (keyW+keyGap)*2, y: keyH + keyGap,     width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: 0,               y: keyH + keyGap,     width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: keyW+keyGap,     y: (keyH + keyGap)*2, width: keyW, height: keyH))
            ]
            keyLetterGrouping = keyLetterGrouping6Keys
            break
        case 8:
            let keyW: CGFloat = 110
            let keyH: CGFloat = 100
            let keyGap: CGFloat = 3
            keyboardView = UIView(frame: CGRect(x: screenW - (keyW*3+keyGap*2), y: screenH - (keyH*3+keyGap*2), width: keyW*3+keyGap*2, height: keyH*3+keyGap*2))
            keyViewList = [
                UILabel(frame: CGRect(x: (keyW+keyGap)*2, y: 0,                 width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: keyW+keyGap,     y: 0,                 width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: 0,               y: 0,                 width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: (keyW+keyGap)*2, y: keyH + keyGap,     width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: 0,               y: keyH + keyGap,     width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: (keyW+keyGap)*2, y: (keyH + keyGap)*2, width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: keyW+keyGap,     y: (keyH + keyGap)*2, width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: 0,               y: (keyH + keyGap)*2, width: keyW, height: keyH))
            ]
            keyLetterGrouping = keyLetterGrouping8Keys
            break
        case -1:
            let keyGap: CGFloat = 3
            let keyW: CGFloat = (screenW - keyGap*2)/3
            let keyH: CGFloat = keyW
            keyboardView = UIView(frame: CGRect(x: screenW - (keyW*3+keyGap*2), y: screenH - (keyH*2+keyGap), width: keyW*3+keyGap*2, height: keyH*2+keyGap))
            keyViewList = [
                UILabel(frame: CGRect(x: (keyW+keyGap)*2, y: 0,                 width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: keyW+keyGap,     y: 0,                 width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: 0,               y: 0,                 width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: (keyW+keyGap)*2, y: keyH + keyGap,     width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: keyW+keyGap,     y: keyH + keyGap,     width: keyW, height: keyH)),
                UILabel(frame: CGRect(x: 0,               y: keyH + keyGap,     width: keyW, height: keyH))
            ]
            keyLetterGrouping = keyLetterGroupingSteve
            break
        default:
            break
        }
        
        for i in 0 ..< keyViewList.count {
            keyViewList[i].backgroundColor = buttonBackgroundColor
            keyViewList[i].text = keyLetterGrouping[i].uppercased()
            keyViewList[i].font = UIFont.boldSystemFont(ofSize: 27)
            keyViewList[i].adjustsFontSizeToFitWidth = true
            keyViewList[i].textColor = UIColor.white
            keyViewList[i].textAlignment = .center
            keyViewList[i].tag = i
            keyViewList[i].layer.borderColor = UIColor.green.cgColor
            keyViewList[i].isUserInteractionEnabled = true
            
            if getNumberOfKeys() == 4 {
                keyViewList[i].numberOfLines = 2
                keyViewList[i].font = UIFont.boldSystemFont(ofSize: 36)
                var s = keyLetterGrouping[i].uppercased()
                s.insert("\n", at: s.index(s.startIndex, offsetBy: 3))
                keyViewList[i].text = s
            }
            if getNumberOfKeys() == -1 {
                keyViewList[i].text = ""
                let keyH = keyViewList[i].frame.height
                let keyW = keyViewList[i].frame.width
                let letterSize: CGFloat = 36
                var letterLabelList = [
                    UILabel(frame: CGRect(x: keyW - letterSize,     y: (keyH - letterSize)/2, width: letterSize, height: letterSize)),
                    UILabel(frame: CGRect(x: (keyW - letterSize)/2, y: 0,                     width: letterSize, height: letterSize)),
                    UILabel(frame: CGRect(x: 0,                     y: (keyH - letterSize)/2, width: letterSize, height: letterSize)),
                    UILabel(frame: CGRect(x: (keyW - letterSize)/2, y: keyH - letterSize,     width: letterSize, height: letterSize))
                ]
                // Add Y and Z letter
                if i == 5 {
                    letterLabelList.append(UILabel(frame: CGRect(x: keyW - letterSize, y: keyH - letterSize, width: letterSize, height: letterSize)))
                    letterLabelList.append(UILabel(frame: CGRect(x: 0,                 y: keyH - letterSize, width: letterSize, height: letterSize)))
                }
                for j in 0 ..< letterLabelList.count {
                    letterLabelList[j].text = String(keyLetterGrouping[i][j]).uppercased()
                    letterLabelList[j].font = UIFont.boldSystemFont(ofSize: 36)
                    letterLabelList[j].textColor = UIColor.white
                    letterLabelList[j].textAlignment = .center
                    keyViewList[i].addSubview(letterLabelList[j])
                }
                
            }
            keyboardView.addSubview(keyViewList[i])
        }
        self.view.addSubview(keyboardView)
    }
    
    
    /* --------------------UI Interaction-------------------- */
    
    func settingsButtonTouched() {
        performSegue(withIdentifier: "showSettingsVC", sender: self)
    }
    
    func updateKeyboardIndicator(_ index: Int) {
        for key in keyViewList {
            key.layer.borderWidth = 0
        }
        if index != -1 {
            // Visual indicator
            keyViewList[index].layer.borderWidth = 3
            /*
            // Audio indicator
            if getNumberOfKeys() == 4 {
                readAloudText(audioCue4Keys[index])
            } else if getNumberOfKeys() == 6 {
                readAloudText(audioCue6Keys[index])
            } else if getNumberOfKeys() == 8 {
                readAloudText(audioCue8Keys[index])
            }
             */
        }
    }
    
    func firstStrokeEntered(_ notification:NSNotification) {
        let key = (Int)(notification.object! as! NSNumber)
        updateKeyboardIndicator(key)
    }
    
    func secondStrokeEntered(_ notification:NSNotification) {
        let letter = (Int)(notification.object! as! NSNumber)
        enteredKeyList.append(letter)
        updatePredictions()
    }
    
    func keyEntered(_ notification:NSNotification) {
        let key = (Int)(notification.object! as! NSNumber)
        enteredKeyList.append(key)
        // Update predictive text for key list.
        updatePredictions()
        updateKeyboardIndicator(key)
    }
    
    func backspace() {
        updateKeyboardIndicator(-1)
        if (enteredKeyList.count == 0) { return }
        
        // Remove last character.
        enteredKeyList.remove(at: enteredKeyList.endIndex - 1)
        updatePredictions()
    }
    
    func backspaceAll() {
        enteredKeyList.removeAll()
        updatePredictions()
        updateKeyboardIndicator(-1)
    }
    
    // Input box should has same length as entered keys.
    // E.g. if key list is [down, right, left], "unit" is the first prediction.
    // But there are only 3 keys in list, so we should show "uni" in input box.
    func trimmedStringForwordLabel(_ result: String) -> String {
        if result == "" { return "" }
        return result.substring(to: result.characters.index(result.startIndex, offsetBy: enteredKeyList.count))
    }
    
    func readAloudText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        // Change speed here.
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
    
    func readAloudLabel(_ sender: UITapGestureRecognizer) {
        if let word = (sender.view as! UILabel).text {
            readAloudText(word)
        }
    }
    
    func sentenceLabelTouched() {
        if sentenceLabel.text == "" { return }

        readAloudText(sentenceLabel.text!)
        sentenceLabelLongPressed()
    }
    
    func sentenceLabelLongPressed() {
        if sentenceLabel.text == "" { return }
        
        addSentenceToCSV(sentenceLabel.text!)
        resetAfterWordAdded()
        sentenceLabel.text = ""
    }
    
    func resetAfterWordAdded() {
        enteredKeyList = [Int]()
        wordLabel.text = ""
        for label in predictionLabels {
            label.text = ""
        }
        updateKeyboardIndicator(-1)
    }
    
    // Interpreter add word to sentence by long press.
    func addWordToSentence(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == .began){
            if let word = (sender.view as! UILabel).text {
                // Audio feedback after adding a word.
                AudioServicesPlaySystemSound(1111)
                sentenceLabel.text! += (word + " ")
                resetAfterWordAdded()
                resetBuildWordMode()
            }
        }
    }
    
    
    
    // Update input box and predictions
    func updatePredictions() {
        // Initialize.
        var prediction = [(String, Int)]()
        for label in predictionLabels {
            label.text = ""
        }
        if (enteredKeyList.count == 0) {
            wordLabel.text = ""
            return
        }
        
        // Possible words from input letters.
        if getNumberOfKeys() != -1 {
            if let buildWordButton = predictionLabels.last {
                buildWordButton.text = buildWordButtonText
            }
        }
        // Possible words from input T9 digits.
        let results = wordPredictionEngine.getSuggestions(enteredKeyList)
        
        // Show first result in input box.
        if (results.count >= numPredictionLabels) {
            // If we already get enough results, we do not need add characters to search predictions.
            wordLabel.text = results[0].0
            // Results is already sorted.
            for i in 0 ..< numPredictionLabels {
                prediction.append(results[i])
            }
        } else {
            // Add characters after input to get more predictions.
            var digits = [enteredKeyList]
            var searchLevel = 0
            var maxSearchLevel = 4
            if getNumberOfKeys() == -1 { maxSearchLevel = 2 }

            // Do not search too many mutations.
            while (prediction.count < numPredictionLabels - results.count && searchLevel < maxSearchLevel) {
                var newDigits = [[Int]]()
                for digit in digits {
                    if getNumberOfKeys() == -1 {
                        for letterValue in UnicodeScalar("a").value...UnicodeScalar("z").value {
                            newDigits.append(digit+[Int(letterValue)])
                        }
                    } else {
                        for i in 0 ..< getNumberOfKeys() {
                            newDigits.append(digit+[i])
                        }
                    }
                }
                for digit in newDigits {
                    prediction += wordPredictionEngine.getSuggestions(digit)
                }
                digits = newDigits
                
                searchLevel += 1
            }
            
            // Sort all predictions based on frequency.
            prediction.sort { $0.1 > $1.1 }
            
            for i in 0 ..< results.count {
                prediction.insert(results[i], at: i)
            }
            
            if getNumberOfKeys() == -1 {
                var inputString = ""
                for letterValue in enteredKeyList {
                    inputString += String(describing: UnicodeScalar(letterValue)!)
                }
                if (prediction.count == 0 || prediction[0].0 != inputString) {
                    prediction.insert((inputString, 0), at: 0)
                }
            }
            
            // Cannot find any prediction.
            if (prediction.count == 0) {
                wordLabel.text = trimmedStringForwordLabel(self.wordLabel.text! + "?")
                return
            }
            
            let firstPrediction = prediction[0].0
            if (firstPrediction.characters.count >= enteredKeyList.count) {
                wordLabel.text = trimmedStringForwordLabel(firstPrediction)
            } else {
                wordLabel.text = trimmedStringForwordLabel(self.wordLabel.text! + "?")
            }
        }
        
        // Show predictions in prediction boxs.
        for i in 0 ..< min(numPredictionLabels - 1, prediction.count) {
            predictionLabels[i].text = prediction[i].0
        }
    }
    
    
    
    
    /* --------------------Scanning Mode-------------------- */
    
    func buildWordButtonTouched() {
        if (enteredKeyList.count == 0) { return }
        
        wordPredictionView.isHidden = true
        buildWordConfirmButton.isHidden = false
        buildWordCancelButton.isHidden = false
        
        buildWordProgressIndex = 0
        buildWordTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.scanningLettersOnKey), userInfo: nil, repeats: true)
        DispatchQueue.main.async {
            self.wordLabel.text = "Build Word"
            self.readAloudText("Build Word")
        }
    }
    
    func scanningLettersOnKey() {
        let enteredKey = enteredKeyList[buildWordProgressIndex]
        let lettersOnKey = keyLetterGrouping[enteredKey]
        buildWordLetterIndex += 1
        buildWordLetterIndex %= lettersOnKey.characters.count
        let letter = lettersOnKey[buildWordLetterIndex]
        DispatchQueue.main.async {
            self.readAloudText(String(letter))
            self.wordLabel.text = self.buildWordResult + String(letter)
            
            for key in self.keyViewList {
                key.layer.borderWidth = 0
            }
            self.keyViewList[enteredKey].layer.borderWidth = 3
        }
    }
    
    func resetBuildWordMode() {
        buildWordTimer.invalidate()
        buildWordProgressIndex = 0
        buildWordLetterIndex = 0
        enteredKeyList = [Int]()
        buildWordResult = ""
        for key in keyViewList {
            key.layer.borderWidth = 0
        }
    }
    
    func buildWordConfirmButtonTouched() {
        if buildWordLetterIndex == -1 { return }
        
        let letter = keyLetterGrouping[enteredKeyList[buildWordProgressIndex]][buildWordLetterIndex]
        buildWordResult.append(letter)
        
        // Complete the whole word
        if (buildWordResult.characters.count == enteredKeyList.count) {
            DispatchQueue.main.async {
                self.wordLabel.text = self.buildWordResult
                
                addWordToCSV(self.buildWordResult)
                
                var word = ""
                for letter in self.buildWordResult.characters {
                    word += (String(letter) + ", ")
                }
                self.readAloudText(word + self.buildWordResult)
                
                self.sentenceLabel.text! += (self.buildWordResult + " ")
                
                self.buildWordCancelButtonTouched()
            }
            return
        }
        
        buildWordProgressIndex += 1
        buildWordLetterIndex = -1
        
        DispatchQueue.main.async {
            self.wordLabel.text = self.buildWordResult
            self.buildWordTimer.invalidate()
            
            var word = ""
            for letter in self.buildWordResult.characters {
                word += (String(letter) + ", ")
            }
            self.readAloudText(word + " Next Letter")
            
            sleep(UInt32(self.buildWordResult.characters.count / 2))
            self.buildWordTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.scanningLettersOnKey), userInfo: nil, repeats: true)
        }
    }
    
    func buildWordCancelButtonTouched() {
        resetBuildWordMode()
        
        wordPredictionView.isHidden = false
        buildWordConfirmButton.isHidden = true
        buildWordCancelButton.isHidden = true
        
        DispatchQueue.main.async {
            self.wordLabel.text = ""
            for label in self.predictionLabels {
                label.text = ""
            }
            if let buildWordButton = self.predictionLabels.last {
                buildWordButton.text = buildWordButtonText
                buildWordButton.textAlignment = .center
            }
        }
    }
}

