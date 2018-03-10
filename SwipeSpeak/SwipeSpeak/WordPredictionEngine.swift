//
//  WordPredictionEngine.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Updated by Daniel Tsirulnikov on 1/2/18.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation

enum WordPredictionError: Error {
    case unsupportedWord(invalidChar: Character)
}

class WordPredictionEngine {
    
    private class TrieNode {
        var children = [Int: TrieNode]()
        var words = [(String, Int)]()
    }

    private var rootNode = TrieNode()
    
    private var keyLetterGrouping = [Character:Int]()
    
    func setKeyLetterGrouping(_ grouping: [String]) {
        if UserPreferences.shared.keyboardLayout == .strokes2 {
            keyLetterGrouping = [Character:Int]()
            for letterValue in UnicodeScalar("a").value...UnicodeScalar("z").value {
                keyLetterGrouping[Character(UnicodeScalar(letterValue)!)] = Int(letterValue)
            }
        } else {
            keyLetterGrouping = [Character:Int]()
            for i in 0 ..< grouping.count {
                for letter in grouping[i] {
                    keyLetterGrouping[letter] = i
                }
            }
        }
    }
    
    private func findNodeToAddWord(_ word: String, node: TrieNode) throws -> TrieNode {
        var node = node
        
        // Traverse existing nodes as far as possible.
        var i = 0
        let length = word.count
        while (i < length) {
            let char = word[i]
            
            guard keyLetterGrouping.keys.contains(char) else {
                throw WordPredictionError.unsupportedWord(invalidChar: char)
            }
            
            let key = keyLetterGrouping[char]!
            
            let c = node.children[key]
            if (c != nil) {
                node = c!
            } else {
                break
            }
            i+=1
        }
        
        while (i < length) {
            let char = word[i]

            guard keyLetterGrouping.keys.contains(char) else {
                throw WordPredictionError.unsupportedWord(invalidChar: char)
            }
            
            let key = keyLetterGrouping[word[i]]!
            
            let newNode = TrieNode()
            node.children[key] = newNode
            node = newNode
            i+=1
        }
        
        return node;
    }
    
    private func insertWordIntoNodeByFrequency(_ node: TrieNode, word: String, useFrequency: Int) {
        let wordToInsert = (word, useFrequency)
        for i in 0 ..< node.words.count {
            let comparedFrequency = node.words[i].1
            let insertFrequency = wordToInsert.1
            
            if insertFrequency >= comparedFrequency {
                node.words.insert(wordToInsert, at: i)
                return
            }
        }
        
        node.words.append(wordToInsert)
    }
    
    func insert(_ word: String, _ frequency: Int) throws {
        let nodeToAddWord = try findNodeToAddWord(word, node: rootNode)
        insertWordIntoNodeByFrequency(nodeToAddWord, word: word, useFrequency: frequency)
    }
    
    func getSuggestions(_ keyString: [Int]) -> [(String, Int)] {
        var node = rootNode
        
        for i in 0 ..< keyString.count {
            if let nextNode = node.children[keyString[i]] {
                node = nextNode
            } else {
                return []
            }
        }
        
        return node.words
    }
    
    /*
    func getSuggestionsFromLetter(_ keyString: [Int]) -> [(String, Int)] {
        var inputString = ""
        for letterValue in keyString {
            inputString += String(describing: UnicodeScalar(letterValue)!)
        }
        print(inputString)
        return [(inputString, 200), ("dsd", 200), ("ss", 200), ("wwe", 200)]
    }*/
    
}
