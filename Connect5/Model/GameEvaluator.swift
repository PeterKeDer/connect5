//
//  GameEvaluator.swift
//  Connect5
//
//  Created by Peter Ke on 2017-11-03.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import UIKit

class GameEvaluator {
    
    var game: Game
    
    init(game: Game) {
        self.game = game
    }
    
    // returns [x, y] after calculating for 3 turns
    func getBestMove(side: Int, game: Game) -> [Int] {
        let oppSide = side == 1 ? 2 : 1
        
        let m = getMandatoryMove(side: side, game: game)
        if m != [] {
            return m
        }
        
        var highestTotalScore = 0
        var highestCs = [[gameBoardSize/2, gameBoardSize/2]]
        
        let list = getMovesAndScores(side: side, game: game)
        for cs in list {
            let copy = game.copy()
            
            copy.setPoint(x: cs[0], y: cs[1], value: side)
            
            let opp = getMoveAndHighestScore(side: oppSide, game: copy)
            copy.setPoint(x: opp[0], y: opp[1], value: oppSide)
            
            var s = getMoveAndHighestScore(side: side, game: game)
            
            let finalScore = cs[2] + s[2] - opp[2]
            if finalScore > highestTotalScore {
                highestTotalScore = finalScore
                highestCs = [[cs[0], cs[1]]]
            } else if finalScore == highestTotalScore {
                highestCs.append([cs[0], cs[1]])
            }
        }
        
        let index = Int(arc4random_uniform(UInt32(highestCs.count)))
        return highestCs[index]
    }
    
    // gets basic move, only current turn
    // if returns default move (which means game can't be won), gets first empty move since it won't matter
    func getMove(side: Int, game: Game) -> [Int] {
        let cs = getMoveAndHighestScore(side: side, game: game)
        if cs[2] == -10000 && !game.boardIsEmpty() {
            if let c = game.firstEmptyC() {
                return c
            }
        }
        return [cs[0], cs[1]]
    }
    
    // calculates the total score of c, given csList and scoreList
    func scoreOfC(c: [Int], csList: [[[Int]]], scoreList: [Int]) -> Int {
        var score = 0
        for i in 0...csList.count-1 {
            let cList = csList[i]
            for coord in cList {
                if coord[0] == c[0] && coord[1] == c[1] {
                    score += scoreList[i]
                }
            }
        }
        return score
    }
    
    // returns an array of [x, y, score]
    // will not return winning moves - considers that they are already calculated
    func getMovesAndScores(side: Int, game: Game) -> [[Int]] {
        let oppSide = side == 1 ? 2 : 1
        
        let one4F = coordinates4OneOpen(side: side, game: game)
        let oppOne4F = coordinates4OneOpen(side: oppSide, game: game)
        let open3 = coordinates3BothOpen(side: side, game: game)
        let oppOpen3 = coordinates3BothOpen(side: oppSide, game: game)
        let open2 = coordinates2(side: side, game: game)
        let oppOpen2 = coordinates2(side: oppSide, game: game)
        
        let csList: [[[Int]]] = [one4F, oppOne4F, open3, oppOpen3, open2, oppOpen2]
        let scoreList: [Int] = [35, 20, 21, 18, 8, 6, 1, 1]
        
        var list = [[Int]]()
        for scoreIndex in 0...csList.count-1 {
            for c in csList[scoreIndex] {
                
                if list.count > 0 {
                    var repeatIndex = -1
                    for i in 0...list.count-1 {
                        let c2 = list[i]
                        if c[0] == c2[0] && c[1] == c2[1] {
                            repeatIndex = i
                        }
                    }
                    if repeatIndex == -1 {
                        list.append(c + [scoreList[scoreIndex]])
                    } else {
                        list[repeatIndex][2] += scoreList[scoreIndex]
                    }
                } else {
                    list.append(c + [scoreList[scoreIndex]])
                }
                
            }
        }
        
        return list
    }
    
    // returns an array, which is [x, y, score]
    func getMoveAndHighestScore(side: Int, game: Game) -> [Int] {
        
        let m = getMandatoryMove(side: side, game: game)
        if m != [] {
            return m
        }
        
        let list = getMovesAndScores(side: side, game: game)
        
        var highestScore = -10000
        var highestCs = [[gameBoardSize/2,gameBoardSize/2]]
        for c in list {
            let score = c[2]
            if score > highestScore {
                highestScore = score
                highestCs = [c]
            } else if score == highestScore {
                highestCs.append(c)
            }
        }
        
        let index = Int(arc4random_uniform(UInt32(highestCs.count)))
        return highestCs[index] + [highestScore]
    }
    
    // returns [x, y, score] that must go that will result in a win, or if not go, opp will win
    // if cannot win, returns []
    func getMandatoryMove(side: Int, game: Game) -> [Int] {
        let oppSide = side == 1 ? 2 : 1
        if let winC = winningCoordinates(side: side, game: game).first {
            // immediate win
            return winC + [10000]
        } else if let oppWinC = winningCoordinates(side: oppSide, game: game).first {
            // opp immediate win
            return oppWinC + [0]
        } else if let winD4 = coordinatesDouble4(side: side, game: game).first {
            // double 4
            return winD4 + [5000]
        } else if let win43 = coordinates43(side: side, game: game).first {
            // 3 4
            return win43 + [2500]
        } else if let win4 = coordinates4BothOpen(side: side, game: game).first {
            // 4 both open
            return win4 + [1000]
        } else if let oppWinD4 = coordinatesDouble4(side: oppSide, game: game).first {
            // opp double 4
            return oppWinD4 + [0]
        } else if let oppWin34 = coordinates43(side: oppSide, game: game).first {
            return oppWin34 + [0]
        }  else if let oppWin4 = coordinates4BothOpen(side: oppSide, game: game).first {
            // opp 4 both open
            return oppWin4 + [0]
        } else if let winD3 = coordinatesDouble3(side: side, game: game).first {
            // double 3
            return winD3 + [690]
        } else if let oppWinD3 = coordinatesDouble3(side: oppSide, game: game).first {
            // opp double 3
            return oppWinD3 + [0]
        }
        return []
    }
    
    
    // checkMode: 0: no additional, 1: one side open, 2: both side open
    func gapCoordsOf(length: Int, side: Int, checkMode: Int) -> [[Int]] {
        if length < 3 {
            return []
        }
        var coords = [[Int]]()
        var lineLists = [[Line]]() // index 0: lines with length 1, index 1: length 2 etc
        for i in 1...length-2 {
            lineLists.append(game.findLines(length: i, side: side))
        }
        for i in 1...length-2 {
            for line in lineLists[i-1] {
                for line2 in lineLists[length-i-2] {
                    if let c = line.gapCWith(line: line2) {
                        switch checkMode {
                        case 0:
                            coords.append(c)
                            break
                        case 1:
                            if line.canExtendBoth() || line2.canExtendBoth() {
                                coords.append(c)
                            }
                            break
                        case 2:
                            if line.canExtendBoth() && line2.canExtendBoth() {
                                coords.append(c)
                            }
                            break
                        default:
                            print("Wrong checkMode")
                            break
                        }
                    }
                }
            }
        }
        return coords
    }
    
    // can get 5, wins instantly
    func winningCoordinates(side: Int, game: Game) -> [[Int]] {
        var coords = [[Int]]()
        for line in game.findLines(length: 4, side: side) {
            if line.canExtendBackward() {
                coords.append(line.backwardC())
            }
            if line.canExtendForward() {
                coords.append(line.forwardC())
            }
        }
        coords.append(contentsOf: gapCoordsOf(length: 5, side: side, checkMode: 0))
        coords.append(contentsOf: gapCoordsOf(length: 6, side: side, checkMode: 0))
        return coords
    }
    
    // can get 4 with both sides open, wins after one turn if opp doesn't win
    func coordinates4BothOpen(side: Int, game: Game) -> [[Int]] {
        var coords = [[Int]]()
        for line in game.findLines(length: 3, side: side) {
            if line.canExtendBoth() {
                if line.afterExtendingForward(1).canExtendForward() {
                    coords.append(line.forwardC())
                }
                if line.afterExtendingBackward(1).canExtendBackward() {
                    coords.append(line.backwardC())
                }
            }
        }
        coords.append(contentsOf: gapCoordsOf(length: 4, side: side, checkMode: 2))
        return coords
    }
    
    // can get two 4 length lines with either side open, can win
    func coordinatesDouble4(side: Int, game: Game) -> [[Int]] {
        var coords = [[Int]]()
        let cs = coordinates4OneOpen(side: side, game: game)
        if cs.count < 2 {
            return []
        }
        for i in 0...cs.count-2 {
            for j in i+1...cs.count-1 {
                if cs[i] == cs[j] {
                    coords.append(cs[i])
                }
            }
        }
        return coords
    }
    
    // can get 4 with one side open
    func coordinates4OneOpen(side: Int, game: Game) -> [[Int]] {
        var coords = [[Int]]()
        for line in game.findLines(length: 3, side: side) {
            if line.canExtendForward() {
                if line.afterExtendingForward(1).canExtendForward() {
                    coords.append(line.forwardC())
                }
            }
            if line.canExtendBackward() {
                if line.afterExtendingBackward(1).canExtendBackward() {
                    coords.append(line.backwardC())
                }
            }
        }
        coords.append(contentsOf: gapCoordsOf(length: 4, side: side, checkMode: 1))
        return coords
    }
    
    // a one side open 4 and a both open 3 - can win game
    func coordinates43(side: Int, game: Game) -> [[Int]] {
        var coords = [[Int]]()
        let cs3 = coordinates3BothOpen(side: side, game: game)
        let cs4 = coordinates4OneOpen(side: side, game: game)
        if cs3.count < 1 || cs4.count < 1 {
            return []
        }
        for c3 in cs3 {
            for c4 in cs4 {
                if c3 == c4 {
                    coords.append(c3)
                }
            }
        }
        return coords
    }
    
    // can get 2 open lines with length 3 both open, which means can win in 3 moves
    func coordinatesDouble3(side: Int, game: Game) -> [[Int]] {
        var coords = [[Int]]()
        let cs = coordinates3BothOpen(side: side, game: game)
        // has less than 2 cs - impossible to form double 3
        if cs.count < 2 {
            return []
        }
        // count-2 since last one has none to compare to
        for i in 0...cs.count-2 {
            for j in i+1...cs.count-1 {
                if cs[i] == cs[j] {
                    coords.append(cs[i])
                }
            }
        }
        return coords
    }
    
    // can get 3 with both sides open and potential to become a five if left unanswered
    func coordinates3BothOpen(side: Int, game: Game) -> [[Int]] {
        var coords = [[Int]]()
        for line in game.findLines(length: 2, side: side) {
            if line.canExtendBoth() {
                if line.afterExtendingForward(2).canBeValidLine() {
                    coords.append(line.forwardC())
                }
                if line.afterExtendingBackward(2).canBeValidLine() {
                    coords.append(line.backwardC())
                }
            }
        }
        coords.append(contentsOf: gapCoordsOf(length: 3, side: side, checkMode: 2))
        return coords
    }
    
    func coordinates2(side: Int, game: Game) -> [[Int]] {
        var coords = [[Int]]()
        for line in game.findLines(length: 1, side: side) {
            if line.afterExtendingForward(4).canBeValidLine() {
                coords.append(line.forwardC())
            }
            if line.afterExtendingBackward(4).canBeValidLine() {
                coords.append(line.backwardC())
            }
            
        }
        return coords
    }
    
    func test() {
        print("GameEvaluator is testing win rate")
        var current = 1
        var firstSide = 1
        let game = Game()
        var win1 = 0
        var win2 = 0
        while true {
            var c = [Int]()
            if current == firstSide {
                c = getBestMove(side: current, game: game)
            } else {
                c = getMove(side: current, game: game)
            }
            game.setPoint(x: c[0], y: c[1], value: current)
            if game.winningCoordinates() != nil {
                if current == firstSide {
                    win1 += 1
                } else {
                    win2 += 1
                }
                firstSide = firstSide == 1 ? 2 : 1
                print("Game finished. Current score: \(win1):\(win2)")
                game.reset()
                current = 1
            } else {
                current = current == 1 ? 2 : 1
            }
        }
    }
    
}
