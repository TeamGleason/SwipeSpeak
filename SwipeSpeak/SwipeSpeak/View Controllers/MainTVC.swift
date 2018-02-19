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
    
    // Keys
    @IBOutlet var keysView4Keys: UIView!
    @IBOutlet var keysView6Keys: UIView!
    @IBOutlet var keysView8Keys: UIView!
    @IBOutlet var keysView2Strokes: UIView!

    @IBOutlet weak var sentenceLabel: UILabel!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var backspaceButton: UIButton!
    var wordPredictionView: UIView!
    
    private var swipeView: SwipeView!
    private var settingsButton = UIButton()
    
    @IBOutlet weak var sentencePlaceholderTF: UITextField!
    @IBOutlet weak var wordPlaceholderTF: UITextField!
    
    // Predictive Text Dictionary
    private var wordPredictionEngine: WordPredictionEngine!
    fileprivate var enteredKeyList = [Int]()
    private var keyViewList = [UILabel]()
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

    private var changedLabelFonts = false

    // When selecting a word
    private var highlightedLabel: UILabel?

    var numPredictionLabels: Int {
        return predictionLabels.count
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
        
        if UserPreferences.shared.longerPauseBetweenLetters {
            buildWordPauseSeconds = 3.5
        } else {
            buildWordPauseSeconds = 2.0
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !viewDidAppear {
            viewDidAppear = true
            
            setupUI()
            setupWordPredictionEngine()
            
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: [.curveEaseIn],
                           animations: { self.view.alpha = 1.0 },
                           completion: nil)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
            for word in UserPreferences.shared.userAddedWords {
                do {
                    try self.wordPredictionEngine.insert(word, Constants.maxWordFrequency)
                } catch WordPredictionError.unsupportedWord(let invalidChar) {
                    print("Cannot add word '\(word)', invalid char '\(invalidChar)'")
                } catch {
                    print("Cannot add word '\(word)', error: \(error)")
                }
            }
            
            if let filePath = Bundle.main.path(forResource: "word_frequency_english_ucrel", ofType: "csv") {
                if let wordAndFrequencyList = getWordAndFrequencyListFromCSV(filePath) {
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
        }
    }
    
    private func setupUI() {
        tableView.isScrollEnabled = false
        
        setupKeyboard()
        
        let swipeParentView = self.view! //keyboardView.superview!
        
        swipeView = SwipeView(frame: swipeParentView.frame,
                              keyboardView: keyboardView,
                              keyViewList:  keyViewList,
                              isTwoStrokes: UserPreferences.shared.keyboardLayout == .strokes2)
        swipeView.keyViewListSuperView = self.view
        swipeView.delegate = self
    
        swipeParentView.superview!.addSubview(swipeView)
 
        setSentenceText("")
        
        for label in predictionLabels {
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didPressPredictionLabel)))
            label.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(addWordToSentence(_:))))
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
            keyViewList.removeAll()
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
        
        let width = min(keyboardContainerView.frame.width, keyboardContainerView.frame.height)
        var height = min(keyboardContainerView.frame.width, keyboardContainerView.frame.height)
        
        if UserPreferences.shared.keyboardLayout == .keys6 ||
            UserPreferences.shared.keyboardLayout == .strokes2 {
            height *= 0.7
        }
        
        keyboardView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        keyboardContainerView.addSubview(keyboardView)
        
        keyboardView.center = CGPoint(x: keyboardContainerView.bounds.width/2.0,
                                      y: keyboardContainerView.bounds.height/2.0)
        
        for subview in keyboardView.subviews {
            guard let label = subview as? UILabel else { continue }
            
            label.isUserInteractionEnabled = true
            label.layer.borderColor = UIColor.green.cgColor
            
            keyViewList.append(label)
        }
        
        adjustKeysFont()
    }
    
    private func adjustKeysFont() {
        guard !changedLabelFonts else { return }
        
        guard traitCollection.horizontalSizeClass == .regular &&
            traitCollection.verticalSizeClass == .regular else { return }
        
        let keyboardViews = [keysView4Keys, keysView6Keys, keysView8Keys, keysView2Strokes]
        
        for keyboardView in keyboardViews {
            for subview in keyboardView!.subviews {
                guard let label = subview as? UILabel else { continue }
                
                label.font = label.font.withSize(label.font.pointSize * 1.5)
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
    
    // MARK: - UI Interaction
    
    @objc func settingsButtonTouched() {
        performSegue(withIdentifier: "showSettingsVC", sender: self)
    }
    
    private func updateKeyboardIndicator(_ index: Int) {
        resetKeysBoarder()
        
        if index != -1 {
            // Visual indicator
            keyViewList[index].layer.borderWidth = 3
        }
    }
    
    @IBAction func backspace() {
        if inBuildWordMode { return }
        //if !buildWordConfirmButton.isHidden { return }

        dehighlightLabel()

        updateKeyboardIndicator(-1)
        if enteredKeyList.count == 0 { return }
        
        // Remove first stroke.
        if swipeView.firstStroke != nil {
            swipeView.firstStroke = nil
        } else { // Remove last character.
            enteredKeyList.remove(at: enteredKeyList.endIndex - 1)
            updatePredictions()
        }
        
        if UserPreferences.shared.audioFeedback {
            playSoundBackspace()
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
    
    private func readAloudText(_ text: String) {
        SpeechSynthesizer.shared.speak(text)
    }
    
    @IBAction func didPressPredictionLabel(_ sender: UITapGestureRecognizer) {
        if let label = sender.view as? UILabel, predictionLabels.contains(label) {
            if highlightedLabel != nil && highlightedLabel == label {
                addWordToSentence(from: label)
                return
            } else {
                highlight(label: label)
            }
        }
        if let word = (sender.view as! UILabel).text {
            readAloudText(word)
        }
        

    }
    
    @IBAction func sentenceLabelTouched() {
        guard let text = sentenceLabel.text, !text.isEmpty else { return }

        readAloudText(text)
        sentenceLabelLongPressed()
    }
    
    @IBAction func sentenceLabelLongPressed() {
        guard let text = sentenceLabel.text, !text.isEmpty else { return }
        //if sentenceLabel.text == "" { return }
        
        UserPreferences.shared.addSentence(text)
        //addSentenceToCSV(sentenceLabel.text!)
        
        resetAfterWordAdded()
        setSentenceText("")
    }
    
    func resetAfterWordAdded() {
        dehighlightLabel()
        enteredKeyList = [Int]()
        setWordText("")
        
        for label in predictionLabels {
            label.text = ""
        }
        
        buildWordButton.setTitle("", for: .normal)

        updateKeyboardIndicator(-1)
    }
    
    // Interpreter add word to sentence by long press.
    @IBAction func addWordToSentence(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        if let label = sender.view as? UILabel{
            addWordToSentence(from: label)
        }
    }
    
    private func addWordToSentence(from label: UILabel) {
        guard let word = label.text else { return }
        
        dehighlightLabel()
        
        // Audio feedback after adding a word.
        if UserPreferences.shared.audioFeedback {
            playSoundWordAdded()
        }
        setSentenceText(sentenceLabel.text! + word + " ")

        resetAfterWordAdded()
        resetBuildWordMode()
    }
    
    // Update input box and predictions
    private func updatePredictions() {
        // Initialize.
        var prediction = [(String, Int)]()
        for label in predictionLabels {
            label.text = ""
        }
        
        buildWordButton.setTitle("", for: .normal)

        if enteredKeyList.count == 0 {
            setWordText("")
            return
        }
        
        // Possible words from input letters.
        if UserPreferences.shared.keyboardLayout != .strokes2 {
            buildWordButton.setTitle(MainTVC.buildWordButtonText, for: .normal)
        }
        
        // Possible words from input T9 digits.
        let results = wordPredictionEngine.getSuggestions(enteredKeyList)
        
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
                    inputString += String(describing: UnicodeScalar(letterValue)!)
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
    
    // MARK: - Scanning Mode
    
    @IBAction func buildWordButtonTouched() {
        guard enteredKeyList.count > 0 else {
            return
        }
        
        inBuildWordMode = true
        tableView.reloadData()
        
//        wordPredictionView.isHidden = true
//        buildWordConfirmButton.isHidden = false
//        buildWordCancelButton.isHidden = false
        
        buildWordProgressIndex = 0
        buildWordTimer = Timer.scheduledTimer(timeInterval: buildWordPauseSeconds,
                                              target: self,
                                              selector: #selector(self.scanningLettersOnKey),
                                              userInfo: nil,
                                              repeats: true)

        self.setWordText(NSLocalizedString("Build Word", comment: ""))
        self.readAloudText(self.wordLabel.text!)
    }
    
    @objc func scanningLettersOnKey() {
        let enteredKey = enteredKeyList[buildWordProgressIndex]
        let lettersOnKey = keyLetterGrouping[enteredKey]
      
        buildWordLetterIndex += 1
        buildWordLetterIndex %= lettersOnKey.count
       
        let letter = lettersOnKey[buildWordLetterIndex]
     
        self.readAloudText(String(letter))
        self.setWordText(self.buildWordResult + String(letter))
        
        self.resetKeysBoarder()
        
        self.keyViewList[enteredKey].layer.borderWidth = 3
    }
    
    private func resetBuildWordMode() {
        buildWordTimer.invalidate()
        buildWordProgressIndex = 0
        buildWordLetterIndex = -1
        enteredKeyList = [Int]()
        buildWordResult = ""
        resetKeysBoarder()
    }
    
    private func resetKeysBoarder() {
        for key in keyViewList {
            key.layer.borderWidth = 0
        }
    }
    
    @IBAction func buildWordConfirmButtonTouched() {
        if buildWordLetterIndex == -1 { return }
        
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
            readAloudText(word + buildWordResult)
            
            setSentenceText(sentenceLabel.text! + buildWordResult + " ")
            
            buildWordCancelButtonTouched()
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
        readAloudText(word + " " + NSLocalizedString("Next Letter", comment: ""))
        
        sleep(UInt32(buildWordResult.count / 2))
        buildWordTimer = Timer.scheduledTimer(timeInterval: self.buildWordPauseSeconds,
                                              target: self,
                                              selector: #selector(self.scanningLettersOnKey),
                                              userInfo: nil,
                                              repeats: true)
    }
    
    @IBAction func buildWordCancelButtonTouched() {
        resetBuildWordMode()
        
        inBuildWordMode = false
        tableView.reloadData()
        
        self.setWordText("")
        
        for label in self.predictionLabels {
            label.text = ""
        }
        
        self.buildWordButton.setTitle(MainTVC.buildWordButtonText, for: .normal)
    }
    
    // MARK: - Table View

    /*
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }
    */
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 2:
            return inBuildWordMode ? 0 : 44
        case 3:
            return inBuildWordMode ? 44 : 0
        case 4:
            return view.bounds.height - 255 - 25
        default:
            return 44
        }
    }
}

// MARK: - SwipeViewDelegate
extension MainTVC: SwipeViewDelegate {
    
    func keyEntered(key: Int) {
        enteredKeyList.append(key)
        // Update predictive text for key list.
        updatePredictions()
        updateKeyboardIndicator(key)
        
        // Indicate how many letter entered, if enabled in settings.
        if UserPreferences.shared.announceLettersCount {
            readAloudText("Letter " + String(enteredKeyList.count + 1))
        }
    }
    
    func firstStrokeEntered(key: Int) {
        updateKeyboardIndicator(key)
    }
    
    func secondStrokeEntered(key: Int) {
        enteredKeyList.append(key)
        updateKeyboardIndicator(-1)
        updatePredictions()
        
        // Indicate how many letter entered, if enabled in settings.
        if UserPreferences.shared.announceLettersCount {
            readAloudText("Letter " + String(enteredKeyList.count + 1))
        }
    }
}
