//
//  BoardView.swift
//  Connect5
//
//  Created by Peter Ke on 2017-11-01.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import UIKit

@IBDesignable
class BoardView: UIView {
    
    // constants
    var boardSize: Int = gameBoardSize
    let lineWidth: CGFloat = 0.8
    let lineColor: UIColor = UIColor.darkGray
    let bgColor: UIColor = #colorLiteral(red: 0.9755859375, green: 0.8289822208, blue: 0.6235000292, alpha: 1)
    let tempPieceAlpha: CGFloat = 0.65
    let animationDuration: TimeInterval = 0.15
    let boardCornerRadius: CGFloat = 5
    let highlightBorderWidth: CGFloat = 35/CGFloat(gameBoardSize)
    let highlightBorderColor: UIColor = UIColor.orange
    
    var blockSize: CGFloat = 300/CGFloat(gameBoardSize)
    var pieceSize: CGFloat = (300/CGFloat(gameBoardSize))*0.75
    var targetView: UIImageView!
    
    var pieceTargetInPlace: Bool = false
    
    var pieces: [UIView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear // real bg will be set in draw, this is to make sure there are no outside of corner radius
    }
    
    override func draw(_ rect: CGRect) {
        let bgPath = UIBezierPath(roundedRect: rect, cornerRadius: boardCornerRadius)
        bgColor.setFill()
        bgPath.fill()
        
        blockSize = rect.width/CGFloat(boardSize)
        pieceSize = blockSize * 0.75
        let half = blockSize/2
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        
        for i in 0...boardSize-1 {
            let l = CGFloat(i)
            // vertical line
            path.move(to: CGPoint(x: l*blockSize + half, y: half))
            path.addLine(to: CGPoint(x: l*blockSize + half, y: rect.width - half))
            // horizontal line
            path.move(to: CGPoint(x: half, y: l*blockSize + half))
            path.addLine(to: CGPoint(x: rect.height - half, y: l*blockSize + half))
        }
        
        lineColor.setStroke()
        path.stroke()
        
        backgroundColor = bgColor
    }
    
    func load(moves: [[Int]]) {
        for i in 0...moves.count-1 {
            let (x, y) = (moves[i][0], moves[i][1])
            // first move is 1, second is 2, third is 1, etc
            addPiece(x: x, y: y, move: (i%2)+1)
        }
    }
    
    func displayBoard(game: Game) {
        for x in 0...boardSize-1 {
            for y in 0...boardSize-1 {
                let p = game.getPoint(x: x, y: y)
                addPiece(x: x, y: y, move: p)
            }
        }
    }
    
    func addPiece(x: Int, y: Int, move: Int) {
        let piece = UIView(frame: CGRect(x: 0, y: 0, width: pieceSize, height: pieceSize))
        piece.center = pointOfCoordinate(c: [x,y])
        piece.layer.cornerRadius = pieceSize/2
        piece.backgroundColor = move == 1 ? UIColor.black : UIColor.white
        pieces.append(piece)
        
        self.addSubview(piece)
    }
    
    // targets - user confirmation
    func addTarget(c: [Int], completion: (()->())?) {
        
        targetView = UIImageView(frame: CGRect(x: 0, y: 0, width: blockSize-1, height: blockSize-1))
        targetView.center = pointOfCoordinate(c: c)
        targetView.image = #imageLiteral(resourceName: "Target")
        targetView.tag = 1 // tag 1 is target or highlight
        
        addViewWithAnimation(view: targetView, completion: completion)
        
    }
    
    func addHighlight(c: [Int]) {
        
        let highlightView = UIView(frame: CGRect(x: 0, y: 0, width: blockSize-2, height: blockSize-2))
        highlightView.center = pointOfCoordinate(c: c)
        highlightView.layer.cornerRadius = (blockSize-2)/2
        highlightView.layer.borderWidth = highlightBorderWidth
        highlightView.layer.borderColor = highlightBorderColor.cgColor
        highlightView.tag = 3 // 3 for highlight, since it shouldn't be cleared when target moves, or with target when pan/pinch
        
        addViewWithAnimation(view: highlightView)
    }
    
    // used as confirmation for users, click again to play move
    func setPieceTarget(c: [Int], move: Int, completion: (()->())?) {
        if pieceTargetInPlace {
            clearTempPiece()
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
                self.targetView.center = self.pointOfCoordinate(c: c)
            }, completion: { (_) in
                if let complete = completion {
                    complete()
                }
            })
        } else {
            clearTarget()
            addTarget(c: c, completion: completion)
            pieceTargetInPlace = true
        }
        addTempPiece(c: c, move: move)
    }
    func setPieceTarget(c: [Int], move: Int) {
        setPieceTarget(c: c, move: move, completion: nil)
    }
    
    
    
    // temporary piece for target with alpha
    func addTempPiece(c: [Int], move: Int) {
        let piece = UIView(frame: CGRect(x: 0, y: 0, width: pieceSize, height: pieceSize))
        piece.center = pointOfCoordinate(c: c)
        piece.layer.cornerRadius = pieceSize/2
        piece.backgroundColor = move == 1 ? UIColor.black : UIColor.white
        piece.tag = 2 // tag 2 for temp piece
        piece.alpha = tempPieceAlpha
        
        addViewWithAnimation(view: piece)
    }
    
    func highlightC(c: [Int]) {
        clearHighlight()
        if shouldHighlightLastMove {
            addHighlight(c: c)
        }
    }
    
    func highlightCoordinates(coords: [[Int]]) {
        clearHighlight()
        if shouldShowWinningMove {
            for c in coords {
                addHighlight(c: c)
            }
        }
    }
    
    func clearHighlight() {
        for view in subviews {
            if view.tag == 3 {
                removeViewWithAnimation(view: view)
            }
        }
    }
    
    func clearTarget() {
        clearTarget(completion: nil)
    }
    
    func clearTarget(completion: (()->())?) {
        pieceTargetInPlace = false
        var viewsToRemove = [UIView]() // this is needed because of completion
        for view in subviews {
            if view.tag == 1 || view.tag == 2 {
                viewsToRemove.append(view)
            }
        }
        if viewsToRemove.count > 0 {
            for i in 0...viewsToRemove.count-1 {
                if i == viewsToRemove.count-1 {
                    removeViewWithAnimation(view: viewsToRemove[i], completion: completion)
                } else {
                    removeViewWithAnimation(view: viewsToRemove[i])
                }
            }
        } else {
            // no animation, does completion
            if let complete = completion {
                complete()
            }
        }
    }
    
    func clearTempPiece() {
        for view in subviews {
            if view.tag == 2 {
                removeViewWithAnimation(view: view)
            }
        }
    }
    
    func addViewWithAnimation(view: UIView) {
        addViewWithAnimation(view: view, completion: nil)
    }
    func addViewWithAnimation(view: UIView, completion: (()->())?) {
        self.addSubview(view)
        view.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: animationDuration, animations: {
            view.transform = CGAffineTransform.identity
        }, completion: { (_) in
            if let complete = completion {
                complete()
            }
        })
    }
    
    func removeViewWithAnimation(view: UIView) {
        removeViewWithAnimation(view: view, completion: nil)
    }
    
    func removeViewWithAnimation(view: UIView, completion: (()->())?) {
        UIView.animate(withDuration: animationDuration, animations: {
            view.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
        }, completion: { (_) in
            view.removeFromSuperview()
            if let complete = completion {
                complete()
            }
        })
    }
    
    func undo() {
        if let view = pieces.last {
            removeViewWithAnimation(view: view)
            pieces.removeLast()
        }
    }
    
    func reset() {
        pieceTargetInPlace = false
        for view in subviews {
            removeViewWithAnimation(view: view)
        }
        pieces = []
    }
    
    func pointOfCoordinate(c: [Int]) -> CGPoint {
        return CGPoint(x: (CGFloat(c[0])+0.5)*blockSize, y: (CGFloat(c[1])+0.5)*blockSize)
    }
    
    // location in view to board coordinate
    func boardCoords(from location: CGPoint) -> [Int]? {
        let half = blockSize/2
        let x = Int((location.x-half)/blockSize + 0.5)
        let y = Int((location.y-half)/blockSize + 0.5)
        if x >= 0 && x < boardSize && y >= 0 && y < boardSize {
            return [x,y]
        }
        return nil
    }
    
 

}
