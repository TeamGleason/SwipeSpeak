//
//  WordPredictionEngine.swift
//  SwipeSpeak
//
//  Created by Xiaoyi Zhang on 7/5/17.
//  Copyright © 2017 TeamGleason. All rights reserved.
//

import Foundation

class TrieNode {
    var children = [Int: TrieNode]()
    var words = [(String, Int)]()
}

extension String {
    subscript (i: Int) -> Character {
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }
}

class WordPredictionEngine {
    var rootNode = TrieNode()
    
    var keyLetterGrouping = [Character:Int]()
    
    func setKeyLetterGrouping(_ grouping: [String]) {
        keyLetterGrouping = [Character:Int]()
        for i in 0 ..< grouping.count {
            for letter in grouping[i].characters {
                keyLetterGrouping[letter] = i
            }
        }
    }
    
    func findNodeToAddWord(_ word: String, node: TrieNode) -> TrieNode {
        var node = node
        
        // Traverse existing nodes as far as possible.
        var i = 0
        let length = word.characters.count
        while (i < length) {
            var key:Int
            key = keyLetterGrouping[word[i]]!
            
            let c = node.children[key]
            if (c != nil) {
                node = c!
            } else {
                break
            }
            i+=1
        }
        
        while (i < length) {
            var key:Int
            key = keyLetterGrouping[word[i]]!
            
            let newNode = TrieNode()
            node.children[key] = newNode
            node = newNode
            i+=1
        }
        
        return node;
    }
    
    func insertWordIntoNodeByFrequency(_ node: TrieNode, word: String, useFrequency: Int) {
        let wordToInsert = (word, useFrequency)
        for i in 0 ..< node.words.count {
            let comparedFrequency = node.words[i].1
            let insertFrequency = wordToInsert.1
            
            if(insertFrequency >= comparedFrequency) {
                node.words.insert(wordToInsert, at: i)
                return
            }
        }
        
        node.words.append(wordToInsert)
    }
    
    func insert(_ word: String, frequency: Int) {
        let nodeToAddWord = findNodeToAddWord(word, node: rootNode)
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
}
