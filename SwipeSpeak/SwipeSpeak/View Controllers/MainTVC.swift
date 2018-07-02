//
//  ViewController.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Updated by Daniel Tsirulnikov on 11/9/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import UIKit
import AVFoundation

class MainTVC: UITableViewController {
    
    // MARK: Constants
    
    private static let buildWordButtonText = NSLocalizedString("Build Word", comment: "")

    // MARK: - Properties
    
    private var viewDidAppear = false
    private var changedLabelFonts = false

    // Keys
    private var swipeView: SwipeView!

    @IBOutlet var keysView4Keys: UIView!
    @IBOutlet var keysView6Keys: UIView!
    @IBOutlet var keysView8Keys: UIView!
    @IBOutlet var keysView2Strokes: UIView!

    @IBOutlet weak var sentenceLabel: UILabel!
    @IBOutlet weak var wordLabel: UILabel!
    
    @IBOutlet weak var sentencePlaceholderTF: UITextField!
    @IBOutlet weak var wordPlaceholderTF: UITextField!
    
    @IBOutlet weak var backspaceButton: UIButton!
    
    // Predictive Text Dictionary
    private var wordPredictionEngine: WordPredictionEngine!
    fileprivate var enteredKeyList = [Int]()
    private var keyboardLabels = [UILabel]()
    private var keyboardView: UIView!
    @IBOutlet weak var keyboardContainerView: UIView!
    
    private var keyLetterGrouping = [String]()
    @IBOutlet var predictionLabels: [UILabel]!
    
    // Build Word Mode
    @IBOutlet weak var buildWordButton: UIButton!
    @IBOutlet weak var buildWordConfirmButton: UIButton!
    @IBOutlet weak var buildWordCancelButton: UIButton!
    
    private var inBuildWordMode = false

    private var buildWordTimer = Timer()
    private var buildWordProgressIndex = 0
    private var buildWordLetterIndex = -1
    private var buildWordResult = ""
    private var buildWordPauseSeconds = 3.5

    // When selecting a word
    private var highlightedLabel: UILabel?

    var numPredictionLabels: Int {
        return predictionLabels.count
    }
    
    var highlightableLabels: [UILabel] {
        return predictionLabels + [wordLabel]
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the speech engine
        _ = SpeechSynthesizer.shared
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardLayoutDidChange(_:)),
                                               name: NSNotification.Name.KeyboardLayoutDidChange,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userAddedWordsUpdated(_:)),
                                               name: NSNotification.Name.UserAddedWordsUpdated,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !viewDidAppear {
            // This will be animated to value 1.0 in `viewDidAppear`
            self.view.alpha = 0.0
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !viewDidAppear {
            viewDidAppear = true
            
            buildWordPauseSeconds = UserPreferences.shared.longerPauseBetweenLetters ? 3.5 : 2.0

            setupUI()
            setupWordPredictionEngine()
            
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: [.curveEaseIn],
                           animations: { self.view.alpha = 1.0 },
                           completion: nil)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if inBuildWordMode {
            cancelBuildWordMode()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            self.view.alpha = 0.0   
        }) { (context) in
            self.setupUI()

            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: [.curveEaseIn],
                           animations: { self.view.alpha = 1.0 },
                           completion: { (completed) in
            })
        }
    }
    
    // MARK: - Setup

    private func setupWordPredictionEngine() {
        wordPredictionEngine = WordPredictionEngine()
        wordPredictionEngine.setKeyLetterGrouping(keyLetterGrouping)
        
        DispatchQueue.global(qos: .userInitiated).async {
            for wordDict in UserPreferences.shared.userAddedWords {
                let word = wordDict[WordKeys.word] as! String
                let freq = wordDict[WordKeys.frequency] as! Int
                
                do {
                    try self.wordPredictionEngine.insert(word, freq)
                } catch WordPredictionError.unsupportedWord(let invalidChar) {
                    print("Cannot add word '\(word)', invalid char '\(invalidChar)'")
                } catch {
                    print("Cannot add word '\(word)', error: \(error)")
                }
            }
            
            guard let filePath = Bundle.main.path(forResource: "word_frequency_english_ucrel", ofType: "csv") else { return }
            guard let wordAndFrequencyList = getWordAndFrequencyListFromCSV(filePath) else { return }
            
            for (word, frequency) in wordAndFrequencyList {
                do {
                    try self.wordPredictionEngine.insert(word, frequency)
                } catch WordPredictionError.unsupportedWord(_) {
                    //print("Cannot add word '\(word)', invalid char '\(invalidChar)'")
                } catch {
                    print("Cannot add word '\(word)', error: \(error)")
                }
            }
        }
    }
    
    private func setupUI() {
        tableView.isScrollEnabled = false
        
        setupKeyboard()
        
        let swipeParentView = self.view! //keyboardView.superview!
        
        swipeView = SwipeView(frame: swipeParentView.frame,
                              keyboardContainerView: self.view,
                              keyboardLabels:  keyboardLabels,
                              isTwoStrokes: UserPreferences.shared.keyboardLayout == .strokes2,
                              delegate: self)
    
        swipeParentView.superview!.addSubview(swipeView)
 
        setSentenceText("")
        
        for label in highlightableLabels {
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLabelTapAction(_:))))
            label.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLabelLongPressAction(_:))))
        }
        
        if let buildTitleLabel = buildWordButton.titleLabel {
            buildTitleLabel.adjustsFontSizeToFitWidth = true
            buildTitleLabel.minimumScaleFactor = 0.75
        }
        
        backspaceAll()
        resetBuildWordMode()
        dehighlightLabel()
    }
    
    private func setupKeyboard() {
        if keyboardView != nil && keyboardView.superview != nil {
            swipeView.removeFromSuperview()
            keyboardView.removeFromSuperview()
            keyboardLabels.removeAll()
        }
        
        switch UserPreferences.shared.keyboardLayout {
        case .keys4:
            keyboardView = keysView4Keys
            keyLetterGrouping = Constants.keyLetterGrouping4Keys
            break
        case .keys6:
            keyboardView = keysView6Keys
            keyLetterGrouping = Constants.keyLetterGrouping6Keys
            break
        case .keys8:
            keyboardView = keysView8Keys
            keyLetterGrouping = Constants.keyLetterGrouping8Keys
            break
        case .strokes2:
            keyboardView = keysView2Strokes
            keyLetterGrouping = Constants.keyLetterGroupingSteve
            break
        }
        
        keyboardContainerView.backgroundColor = UIColor.white
        keyboardView.backgroundColor = UIColor.white
        
        let keyboardSize = MainTVC.keyboardSize(keyboardContainerView)
        keyboardView.frame = CGRect(x: 0, y: 0, width: keyboardSize.width, height: keyboardSize.height)
        
        keyboardContainerView.addSubview(keyboardView)
        
        keyboardView.center = CGPoint(x: keyboardContainerView.bounds.width/2.0,
                                      y: keyboardContainerView.bounds.height/2.0)
        
        for subview in keyboardView.subviews {
            guard let label = subview as? UILabel else { continue }
            
            label.isUserInteractionEnabled = true
            label.layer.borderColor = UIColor.green.cgColor
            
            keyboardLabels.append(label)
        }
        
        adjustKeysFont()
    }
    
    private static func keyboardSize(_ keyboardContainerView: UIView) -> CGSize {
        let containerWidth = keyboardContainerView.frame.width
        let containerHeight = keyboardContainerView.frame.height
        
        var width = min(keyboardContainerView.frame.width, keyboardContainerView.frame.height)
        var height = min(keyboardContainerView.frame.width, keyboardContainerView.frame.height)
        
        if UserPreferences.shared.keyboardLayout == .keys6 ||
            UserPreferences.shared.keyboardLayout == .strokes2 {
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                // iPhone 8 Plus
                if containerHeight > 390 {
                    height *= 0.7
                }
                // iPhone 8
                else if containerHeight > 322 {
                    height *= 0.7
                    width *= 1.1
                }
                // iPhone 5
                else {
                    height *= 0.9
                    width *= 1.4
                }
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                let landscape = containerWidth/containerHeight > 2.0
                
                if landscape {
                    height *= 0.9
                    width *= 1.3
                } else {
                    height *= 0.75
                    width *= 1.05
                }
            }
        }
        
        // Just in case, make sure the size is within bounds
        width = min(width, containerWidth)
        height = min(height, containerHeight)

        return CGSize(width: width, height: height)
    }
    
    private func adjustKeysFont() {
        guard !changedLabelFonts else { return }
        
        let iPhone5ScreenHeight: CGFloat = 568
        let multiplier: CGFloat
        
        // Make fonts bigger for bigger devices (iPads)
        if traitCollection.horizontalSizeClass == .regular &&
            traitCollection.verticalSizeClass == .regular {
            multiplier = 1.5
        }
        // Make fonts smaller for small devices (iPhone 5 and below)
        else if UIScreen.main.bounds.size.height <= iPhone5ScreenHeight {
            multiplier = 0.9
        } else {
            return
        }
        
        let keyboardViews = [keysView4Keys, keysView6Keys, keysView8Keys, keysView2Strokes]
        
        for keyboardView in keyboardViews {
            for subview in keyboardView!.subviews {
                guard let label = subview as? UILabel else { continue }
                
                label.font = label.font.withSize(label.font.pointSize * multiplier)
            }
        }
        
        changedLabelFonts = true
    }
    
    // MARK: - Notifications

    @objc private func keyboardLayoutDidChange(_ notification: Notification) {
        setupUI()
        setupWordPredictionEngine()
    }
    
    @objc private func userAddedWordsUpdated(_ notification: Notification) {
        setupUI()
        setupWordPredictionEngine()
    }
    
    // MARK: User UI Interaction

    @IBAction func backspace() {
        if inBuildWordMode { return }
        //if !buildWordConfirmButton.isHidden { return }
        
        dehighlightLabel()
        
        updateKeyboardIndicator(-1)
        if enteredKeyList.count == 0 && !wordLabelContainsArrowSuffix() {
            return
        }
        
        // Remove first stroke.
        if swipeView.firstStroke != nil {
            swipeView.firstStroke = nil
        } else { // Remove last character.
            enteredKeyList.removeLast()
            updatePredictions()
        }
        
        if UserPreferences.shared.audioFeedback {
            playSoundBackspace()
        }
        
        if UserPreferences.shared.keyboardLayout == .strokes2 {
            removeArrowSuffix()
        } else {
            showCurrentArrows()
        }
    }
    
    @IBAction func backspaceAll() {
        if inBuildWordMode { return }
        // if !buildWordConfirmButton.isHidden { return }
        
        if !enteredKeyList.isEmpty {
            if UserPreferences.shared.audioFeedback {
                playSoundBackspace()
            }
        }
        
        enteredKeyList.removeAll()
        updatePredictions()
        updateKeyboardIndicator(-1)
        swipeView.firstStroke = nil
    }
    
    @IBAction func handleLabelTapAction(_ sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel else { return }
        guard let text = label.text, !text.isEmpty else { return }
        guard !text.containsArrow() else { return }
        
        guard highlightableLabels.contains(label) else {
            return
        }
        
        if highlightedLabel != nil && highlightedLabel == label {
            _ = addWordToSentence(from: label, announce: true)
        } else {
            highlight(label: label)
            announce(text)
        }
    }
    
    @IBAction func handleLabelLongPressAction(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        guard let label = sender.view as? UILabel else { return }
        
        _ = addWordToSentence(from: label)
    }

    @IBAction func sentenceLabelTouched() {
        guard let text = sentenceLabel.text, !text.isEmpty else { return }
        
        announce(text)
        sentenceLabelLongPressed()
    }
    
    @IBAction func sentenceLabelLongPressed() {
        completeSentance()
    }
    
    // MARK: UI Actions

    private func updateKeyboardIndicator(_ index: Int) {
        resetKeysBoarder()
        
        if index != -1 {
            // Visual indicator
            keyboardLabels[index].layer.borderWidth = 3
        }
    }
    
    private func removeArrowSuffix() {
        guard wordLabelContainsArrowSuffix(), let wordLabelText = wordLabel.text else {
            return
        }
        
        setWordText(String(wordLabelText.dropLast()))
    }
    
    // Input box should has same length as entered keys.
    // E.g. if key list is [down, right, left], "unit" is the first prediction.
    // But there are only 3 keys in list, so we should show "uni" in input box.
    private func trimmedStringForwordLabel(_ result: String) -> String {
        guard !result.isEmpty else {
            return ""
        }
        
        let toIndex = result.index(result.startIndex, offsetBy: enteredKeyList.count)
        return String(result[..<toIndex])
    }
    
    private func announceDirection(for key: Int, with keyboardLayout: KeyboardLayout) {
        guard UserPreferences.shared.announceLettersCount else {
            return
        }
        
        let arrows: [Int: String]

        switch keyboardLayout {
        case .keys4:
            arrows = MainTVC.arrows4KeysTextMap
        case .strokes2:
            arrows = MainTVC.arrows2StrokesTextMap
        default:
            return
        }
        
        guard let arrowText = arrows[key] else { return }
        announce(NSLocalizedString(arrowText, comment: ""))
    }
    
    private func announce(_ text: String) {
        SpeechSynthesizer.shared.speak(text)
    }
    
    private func resetAfterWordAdded() {
        dehighlightLabel()
        enteredKeyList = [Int]()
        setWordText("")
        
        for label in predictionLabels {
            label.text = ""
        }
        
        buildWordButton.setTitle("", for: .normal)

        updateKeyboardIndicator(-1)
    }
    
    private func addWordToSentence(from label: UILabel, announce: Bool = false) -> Bool {
        guard let word = label.text else { return false }
        
        return addWordToSentence(word: word, announce: announce)
    }
    
    private func addWordToSentence(word: String, announce: Bool = false) -> Bool {
        guard !word.isEmpty, !word.containsArrow() else {
            return false
        }
        
        dehighlightLabel()
        
        // Audio feedback after adding a word.
        if UserPreferences.shared.audioFeedback {
            if announce {
                self.announce(word)
            } else {
                playSoundWordAdded()
            }
        }
        
        setSentenceText(sentenceLabel.text! + word + " ")
        
        resetAfterWordAdded()
        resetBuildWordMode()
        
        if UserPreferences.shared.userAddedWordsArray.contains(word) {
            UserPreferences.shared.incrementWord(word)
        }
        
        swipeView.firstStroke = nil
        
        return true
    }
    
    private func completeSentance() {
        guard let text = sentenceLabel.text, !text.isEmpty else { return }
        
        UserPreferences.shared.addSentence(text)
        
        resetAfterWordAdded()
        setSentenceText("")
    }
    
    // Update input box and predictions
    private func updatePredictions() {
        // Initialize.
        for label in predictionLabels {
            label.text = ""
        }
        
        buildWordButton.setTitle("", for: .normal)

        guard !enteredKeyList.isEmpty else {
            setWordText("")
            return
        }
        
        // Possible words from input letters.
        if UserPreferences.shared.keyboardLayout != .strokes2 {
            buildWordButton.setTitle(MainTVC.buildWordButtonText, for: .normal)
        }
        
        // Possible words from input T9 digits.
        let results = wordPredictionEngine.getSuggestions(enteredKeyList)
        
        var prediction = [(String, Int)]()

        // Show first result in input box.
        if results.count >= numPredictionLabels {
            // If we already get enough results, we do not need add characters to search predictions.
            setWordText(results[0].0)
            // Results is already sorted.
            for i in 0 ..< numPredictionLabels {
                prediction.append(results[i])
            }
        } else {
            // Add characters after input to get more predictions.
            var digits = [enteredKeyList]
            var searchLevel = 0
            var maxSearchLevel = 4
            
            if UserPreferences.shared.keyboardLayout == .strokes2 {
                maxSearchLevel = 2
            }
            
            // Do not search too many mutations.
            while (prediction.count < numPredictionLabels - results.count && searchLevel < maxSearchLevel) {
                var newDigits = [[Int]]()
                for digit in digits {
                    if UserPreferences.shared.keyboardLayout == .strokes2 {
                        for letterValue in UnicodeScalar("a").value...UnicodeScalar("z").value {
                            newDigits.append(digit+[Int(letterValue)])
                        }
                    } else {
                        for i in 0 ..< UserPreferences.shared.keyboardLayout.rawValue {
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
            
            if UserPreferences.shared.keyboardLayout == .strokes2 {
                var inputString = ""
                for letterValue in enteredKeyList {
                    inputString += letter(from: letterValue)!
                }
                
                if (prediction.count == 0 || prediction[0].0 != inputString) {
                    prediction.insert((inputString, 0), at: 0)
                }
            }
            
            // Cannot find any prediction.
            if (prediction.count == 0) {
                setWordText(trimmedStringForwordLabel(self.wordLabel.text! + "?"))
                return
            }
            
            let firstPrediction = prediction[0].0
            if firstPrediction.count >= enteredKeyList.count {
                setWordText(trimmedStringForwordLabel(firstPrediction))
            } else {
                setWordText(trimmedStringForwordLabel(self.wordLabel.text! + "?"))
            }
        }
        
        // Show predictions in prediction boxs.
        for i in 0 ..< min(numPredictionLabels - 1, prediction.count) {
            predictionLabels[i].text = prediction[i].0
        }
    }
    
    private func highlight(label: UILabel) {
        dehighlightLabel()
        highlightedLabel = label
        label.font = UIFont.boldSystemFont(ofSize: label.font.pointSize + 4)
    }
    
    private func dehighlightLabel() {
        guard highlightedLabel != nil else { return }
        
        highlightedLabel!.font = UIFont.preferredFont(forTextStyle: .body)
        highlightedLabel = nil
    }
    
    private func setSentenceText(_ text: String) {
        sentencePlaceholderTF.placeholder = text.isEmpty ? NSLocalizedString("Sentence", comment: "") : ""
        sentenceLabel.text = text
    }
    
    private func setWordText(_ text: String) {
        wordPlaceholderTF.placeholder = text.isEmpty ? NSLocalizedString("Word", comment: "") : ""
        wordLabel.text = text
    }
    
    private func resetKeysBoarder() {
        for key in keyboardLabels {
            key.layer.borderWidth = 0
        }
    }
    
    private func showCurrentArrows() {
        let arrows = directionArrows(for: enteredKeyList)
        setWordText(arrows)
    }
    
    // MARK: - Scanning Mode
    
    @IBAction func buildWordButtonTouched() {
        guard  UserPreferences.shared.keyboardLayout != .strokes2 else {
            return
        }
        
        guard enteredKeyList.count > 0 else {
            return
        }
        
        inBuildWordMode = true
        tableView.reloadData()
        
        buildWordProgressIndex = 0
        buildWordTimer = Timer.scheduledTimer(timeInterval: buildWordPauseSeconds,
                                              target: self,
                                              selector: #selector(self.scanningLettersOnKey),
                                              userInfo: nil,
                                              repeats: true)

        self.setWordText(MainTVC.buildWordButtonText)
        self.announce(self.wordLabel.text!)
    }
    
    @objc func scanningLettersOnKey() {
        guard enteredKeyList.indices.contains(buildWordProgressIndex) else { return }
        let enteredKey = enteredKeyList[buildWordProgressIndex]
        
        guard keyLetterGrouping.indices.contains(enteredKey) else { return }
        let lettersOnKey = keyLetterGrouping[enteredKey]
      
        buildWordLetterIndex += 1
        buildWordLetterIndex %= lettersOnKey.count
       
        guard buildWordLetterIndex < lettersOnKey.count else { return }
        let letter = lettersOnKey[buildWordLetterIndex]
     
        self.announce(String(letter))
        self.setWordText(self.buildWordResult + String(letter))
        
        self.resetKeysBoarder()
        
        guard keyboardLabels.indices.contains(enteredKey) else { return }
        self.keyboardLabels[enteredKey].layer.borderWidth = 3
    }
    
    private func resetBuildWordMode() {
        buildWordTimer.invalidate()
        buildWordProgressIndex = 0
        buildWordLetterIndex = -1
        enteredKeyList = [Int]()
        buildWordResult = ""
        resetKeysBoarder()
    }
    
    @IBAction func buildWordConfirmButtonTouched() {
        guard buildWordLetterIndex != -1 else { return }
        
        let letter = keyLetterGrouping[enteredKeyList[buildWordProgressIndex]][buildWordLetterIndex]
        buildWordResult.append(letter)
        
        // Complete the whole word
        guard buildWordResult.count < enteredKeyList.count else {
            let buildWordResult = String(self.buildWordResult)
            UserPreferences.shared.addWord(self.buildWordResult)
         
            setWordText(buildWordResult)
            
            var word = ""
            for letter in buildWordResult {
                word += (String(letter) + ", ")
            }
            announce(word + buildWordResult)
            
            setSentenceText(sentenceLabel.text! + buildWordResult + " ")
            
            cancelBuildWordMode()
            return
        }
        
        buildWordProgressIndex += 1
        buildWordLetterIndex = -1
        
        setWordText(buildWordResult)
        
        buildWordTimer.invalidate()
        
        var word = ""
        for letter in buildWordResult {
            word += (String(letter) + ", ")
        }
        announce(word + " " + NSLocalizedString("Next Letter", comment: ""))
        
        sleep(UInt32(buildWordResult.count / 2))
        buildWordTimer = Timer.scheduledTimer(timeInterval: self.buildWordPauseSeconds,
                                              target: self,
                                              selector: #selector(self.scanningLettersOnKey),
                                              userInfo: nil,
                                              repeats: true)
    }
    
    @IBAction func cancelBuildWordMode() {
        resetBuildWordMode()
        
        inBuildWordMode = false
        tableView.reloadData()
        
        self.setWordText("")
        
        for label in self.predictionLabels {
            label.text = ""
        }
        
        buildWordButton.setTitle("", for: .normal)
    }
    
    
    // MARK: - Helper Methods

    private func wordLabelContainsArrowSuffix() -> Bool {
        guard let char = wordLabel.text?.last else { return false }
        return String(char).containsArrow()
    }
    
    private func letter(from key: Int) -> String? {
        guard let scalar = UnicodeScalar(key) else { return nil }
        return String(describing: scalar)
    }
    
    private func directionArrows(for keys: [Int]) -> String {
        guard !keys.isEmpty else {
            return ""
        }
        
        let arrows = keys.map { MainTVC.arrows4KeysMap[$0]! }
        
        return arrows.joined(separator: "")
    }
    
    // MARK: - Table View

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 2: // Prediction labels
            return inBuildWordMode ? 0 : 44
        case 3: // Build word buttons
            return inBuildWordMode ? 44 : 0
        case 4: // Keyboard view
            return view.bounds.height - 255 - 25
        default:
            return 44
        }
    }
    
}

// MARK: - SwipeViewDelegate

extension MainTVC: SwipeViewDelegate {
    
    // MARK: Constants
    
    static let arrows4KeysMap = [0: "↑",
                                 1: "→",
                                 2: "←",
                                 3: "↓"]
    
    static let arrows4KeysTextMap = [0: "Up",
                                     1: "Right",
                                     2: "Left",
                                     3: "Down"]
    
    static let arrows2StrokesMap = [0: "↗︎",
                                    1: "↑",
                                    2: "↖︎",
                                    3: "↘︎",
                                    4: "↓",
                                    5: "↙︎"]
    
    static let arrows2StrokesTextMap = [0: "Up Right",
                                        1: "Up",
                                        2: "Up Left",
                                        3: "Down Right",
                                        4: "Down",
                                        5: "Down left"]
    
    // MARK: Methods

    func keyEntered(key: Int) {
        enteredKeyList.append(key)
        
        // Update predictive text for key list.
        updatePredictions()
        updateKeyboardIndicator(key)
        
        announceDirection(for: key, with: .keys4)
    
        showCurrentArrows()
    }
    
    func firstStrokeEntered(key: Int) {
        updateKeyboardIndicator(key)
        
        guard let arrow = MainTVC.arrows2StrokesMap[key] else { return }
        let text = (wordLabel.text ?? "") + arrow
        setWordText(text)
        
        announceDirection(for: key, with: .strokes2)
    }
    
    func secondStrokeEntered(key: Int) {
        enteredKeyList.append(key)
        updateKeyboardIndicator(-1)
        updatePredictions()
        
        guard let letter = letter(from: key) else { return }
        announce(letter)
    }
    
    func longPressBegan() {
        // Try to select word
        if !addWordToSentence(from: wordLabel, announce: true) {
            // Try to complete phrase
            sentenceLabelTouched()
        }
    }
    
}

extension CharacterSet {
    static let arrowCharacters = CharacterSet(charactersIn: "↑↗︎→↘︎↓↙︎←↖︎")
}

extension String {
    func containsArrow() -> Bool {
        return self.rangeOfCharacter(from: CharacterSet.arrowCharacters) != nil
    }
}
