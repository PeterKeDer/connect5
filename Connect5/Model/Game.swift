//
//  Stuff.swift
//  Connect5
//
//  Created by Peter Ke on 2017-09-23.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import UIKit


class Game {
    
    // constants
    var boardSize: Int = gameBoardSize
    let sizeToWin: Int = 5
    
    var board: [Int] = [] // 0-none, 1-black, 2-white
    
    var linesArray: [[Line]?] = [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil] // represents length 1,2,3,4,5,side2 1,2,3,4,5 (length is index+1)
    
    init() {
        reset()
    }
    
    func reset() {
        board = []
        resetLinesArray()
        for _ in 0..<boardSize*boardSize {
            board.append(0)
        }
    }
    
    func load(moves: [[Int]]) {
        for i in 0...moves.count-1 {
            let (x, y) = (moves[i][0], moves[i][1])
            // first move is 1, second is 2, third is 1, etc
            setPoint(x: x, y: y, value: (i%2)+1)
        }
    }
    
    func getPoint(x: Int, y: Int) -> Int {
        if 0 <= x && x < boardSize && 0 <= y && y < boardSize {
            return board[x + y*boardSize]
        }
        return -1
    }
    
    func getPoint(c: [Int]) -> Int {
        return getPoint(x: c[0], y: c[1])
    }
    
    func setPoint(x: Int, y: Int, value: Int) {
        if 0 <= value && value <= 2 {
            board[x + y*boardSize] = value
        }
        resetLinesArray() // since lines before are not valid anymore
    }
    
    // returns a straight line of coordinates
    func getCoordinates(x: Int, y: Int, xChange: Int, yChange: Int, length: Int) -> [[Int]] {
        var coords = [[x,y]]
        if length <= 0 {
            return []
        }
        for c in getCoordinates(x: x+xChange, y: y+yChange, xChange: xChange, yChange: yChange, length: length-1) {
            coords.append(c)
        }
        return coords
    }
    
    // checks if point is connected to 5 with direction (using xChange and yChange)
    // recursive - iteration starts from 0, when iteration reaches sizeToWin, returns true
    func checkPoint(checkValue: Int, x: Int, y: Int, xChange: Int, yChange: Int, iteration: Int) -> Bool {
        if getPoint(x: x, y: y) == checkValue {
            return checkPoint(checkValue: checkValue, x: x + xChange, y: y + yChange, xChange: xChange, yChange: yChange, iteration: iteration + 1)
        } else if iteration >= sizeToWin {
            return true
        }
        return false
    }
    
    func check(checkValue: Int, x: Int, y: Int, xChange: Int, yChange: Int, iteration: Int) -> [[Int]]? {
        if checkPoint(checkValue: checkValue, x: x, y: y, xChange: xChange, yChange: yChange, iteration: iteration) {
            return getCoordinates(x: x, y: y, xChange: xChange, yChange: yChange, length: sizeToWin)
        } else {
            return nil
        }
    }
    
    // returns coordinates of winning connection, if exists
    func winningCoordinates() -> [[Int]]? {
        for x in 0...boardSize-1 {
            for y in 0...boardSize-1 {
                let value = getPoint(x: x, y: y)
                if value != 0 {
                    // horizontal
                    if let coords = check(checkValue: value, x: x, y: y, xChange: 1, yChange: 0, iteration: 0) {
                        return coords
                    }
                    // vertical
                    if let coords = check(checkValue: value, x: x, y: y, xChange: 0, yChange: 1, iteration: 0) {
                        return coords
                    }
                    // diagonal - from bottom left to top right
                    if let coords = check(checkValue: value, x: x, y: y, xChange: 1, yChange: -1, iteration: 0) {
                        return coords
                    }
                    // diagonal - from top left to bottom right
                    if let coords = check(checkValue: value, x: x, y: y, xChange: 1, yChange: 1, iteration: 0) {
                        return coords
                    }
                }
            }
        }
        
        return nil
    }
    
    // returns true if there are no more 0s on the board
    func boardIsFull() -> Bool {
        return !board.contains(0)
    }
    
    func boardIsEmpty() -> Bool {
        for v in board {
            if v != 0 {
                return false
            }
        }
        return true
    }
    
    
    
    // utility section used for GameEvaluator
    
    // values of an array of points
    func getPoints(coords: [[Int]]) -> [Int] {
        var values = [Int]()
        for c in coords {
            values.append(getPoint(c: c))
        }
        return values
    }
    
    
    // try to find in linesArray, if nil then use getLines
    func findLines(length: Int, side: Int) -> [Line] {
        if let lines = linesArray[length-1+(side-1)*5] {
            return lines
        }
        let lines = getLines(length: length, side: side)
        return lines
    }
    func resetLinesArray() {
        linesArray = [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
    }
    // get a list of lines
    func getLines(length: Int, side: Int) -> [Line] {
        var lines = [Line]()
        for x in 0...boardSize-1 {
            for y in 0...boardSize-1 {
                // horizontal
                let l1 = Line(x: x, y: y, xChange: 1, yChange: 0, value: side, length: length, game: self)
                if l1.isValidLine() && !l1.isPartOfBiggerLine() {
                    lines.append(l1)
                }
                // vertical
                let l2 = Line(x: x, y: y, xChange: 0, yChange: 1, value: side, length: length, game: self)
                if l2.isValidLine() && !l2.isPartOfBiggerLine() {
                    lines.append(l2)
                }
                // diagonal - from bottom left to top right
                let l3 = Line(x: x, y: y, xChange: 1, yChange: -1, value: side, length: length, game: self)
                if l3.isValidLine() && !l3.isPartOfBiggerLine() {
                    lines.append(l3)
                }
                // diagonal - from top left to bottom right
                let l4 = Line(x: x, y: y, xChange: 1, yChange: 1, value: side, length: length, game: self)
                if l4.isValidLine() && !l4.isPartOfBiggerLine() {
                    lines.append(l4)
                }
            }
        }
        linesArray[length-1+(side-1)*5] = lines
        return lines
    }
    
    func copy() -> Game {
        let newGame = Game()
        newGame.board = self.board
        return newGame
    }
    
    func firstEmptyC() -> [Int]? {
        for x in 0..<boardSize {
            for y in 0..<boardSize {
                if getPoint(x: x, y: y) == 0 {
                    return [x,y]
                }
            }
        }
        return nil
    }
    
    static func indexToC(_ index: Int, size: Int) -> [Int] {
        let x = index%size
        let y = (index-x)/size
        return [x,y]
    }
    static func cToIndex(_ c: [Int], size: Int) -> Int {
        return c[0] + c[1]*size
    }
    
}


// line, a struct used by Game and GameEvaluator to calculate best moves more easily
struct Line {
    var x: Int
    var y: Int
    var xChange: Int
    var yChange: Int
    var value: Int
    var length: Int
    var game: Game
    
    init(x: Int, y: Int, xChange: Int, yChange: Int, value: Int, length: Int, game: Game) {
        self.x = x
        self.y = y
        self.xChange = xChange
        self.yChange = yChange
        self.value = value
        self.length = length
        self.game = game
    }
    
    func getC() -> [Int] {
        return [x,y]
    }
    
    func getCs() -> [[Int]] {
        return game.getCoordinates(x: x, y: y, xChange: xChange, yChange: yChange, length: length)
    }
    
    func canExtendBackward() -> Bool {
        return game.getPoint(x: x - xChange, y: y - yChange) == 0
    }
    
    func canExtendForward() -> Bool {
        return game.getPoint(x: x + length*xChange, y: y + length*yChange) == 0
    }
    
    func canExtendBoth() -> Bool {
        return canExtendForward() && canExtendBackward()
    }
    
    func canExtendEither() -> Bool {
        return canExtendForward() || canExtendBackward()
    }
    
    func forwardC() -> [Int] {
        return [x+length*xChange, y+length*yChange]
    }
    
    func backwardC() -> [Int] {
        return [x-xChange, y-yChange]
    }
    
    func sameDirectionWithLine(_ line: Line) -> Bool {
        return xChange == line.xChange && yChange == line.yChange
    }
    
    mutating func extendForward(_ length: Int) {
        self.length += length
    }
    
    mutating func extendBackward(_ length: Int) {
        self.length += length
        self.x -= length*xChange
        self.y -= length*yChange
    }
    
    func copy() -> Line {
        return Line(x: x, y: y, xChange: xChange, yChange: yChange, value: value, length: length, game: game)
    }
    
    func afterExtendingForward(_ length: Int) -> Line {
        var newLine = copy()
        newLine.extendForward(length)
        return newLine
    }
    
    func afterExtendingBackward(_ length: Int) -> Line {
        var newLine = copy()
        newLine.extendBackward(length)
        return newLine
    }
    
    func isPartOfBiggerLine() -> Bool {
        return game.getPoint(c: forwardC()) == value || game.getPoint(c: backwardC()) == value
    }
    
    // has the space to get l length
    // 0 if no potential, -1 if backward, 1 if forward
    func potentialForLength(_ l: Int) -> Int {
        let remaining = l - length
        for i in 0...remaining {
            if afterExtendingForward(i).afterExtendingBackward(remaining-i).canBeValidLine() {
                return i > l/2 ? 1 : -1
            }
        }
        return 0
    }
    
    // all the values of the points in game is same as the value of the line
    // aka line actually exists on board
    func isValidLine() -> Bool {
        for v in game.getPoints(coords: getCs()) {
            if v != value {
                return false
            }
        }
        return true
    }
    
    // all the values are 0 or value
    func canBeValidLine() -> Bool {
        for v in game.getPoints(coords: getCs()) {
            if v != value && v != 0 {
                return false
            }
        }
        return true
    }
    
    // only compares once, because duplicates happen in function in evaluator
    func gapCWith(line: Line) -> [Int]? {
        if xChange == line.xChange && yChange == line.yChange {
            let fc = forwardC()
            if fc == line.backwardC() && game.getPoint(c: fc) == 0 {
                return fc
            }
        }
        return nil
    }

}





