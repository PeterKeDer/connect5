//
//  ViewController.swift
//  Connect5
//
//  Created by Peter Ke on 2017-09-23.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import UIKit
import FontAwesome
import Firebase

class MainViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var game: Game! // model for the game
    var gameEvaluator: GameEvaluator! // used for bots or hints
    
    var boardView: BoardView!
    
    var rootViewController: RootViewController!
    
    var winLabel: UILabel! // label to  `e displayed on panelView when one side won
    
    var isPlayingWithBot: Bool = false
    var botSide: Int = 2
    
    var currentMove: Int = 1 // either 1 or 2
    var gameIsOn: Bool = true // also disabled when menu is opened
    var shouldMoveBoard: Bool = true // used when menu is presenting, disable board movement
    
    // MULTIPLAYER VARIABLES
    var isPlayingMultiplayer: Bool = false
    var shouldAllowMoves: Bool = false
    var currentRoom: Room?
    var currentRoomKey: String? // uid used to access child ref
    var multiplayerSide: Int = 0 // 1 or 2, when connected, or 0 when not connected
    
    let boardViewSize: CGFloat = 300
    let panelViewCornerRadius: CGFloat = 12
    let panelViewAlpha: CGFloat = 0.85
    let winLabelFontSize: CGFloat = 32
    let toolBarFontSize: CGFloat = 22
    var winLabelColor: UIColor = UIColor.black
    
    let maxScale: CGFloat = 4
    var maxDistance: CGFloat! // max distance of edge of board from edge for x, (width-boardSize)/2
    var maxDistanceBottom: CGFloat! // height-boardSize-maxDistance
    var maxDistanceTop: CGFloat! // minDistanceBottom, consider ui height of top
    let sensitivity: CGFloat = 1
    let animationDuration: TimeInterval = 0.15
    var currentScale: CGFloat = 1 // min 1, but can be lower during animations
    var lastPinchScale: CGFloat = 0
    
    var hasTarget: Bool = false // if there is a target (for confirming move) on the board
    var pendingC: [Int] = [-1,-1] // if confirmed (tapped again), will be sent to GameController as a move
    var gameMoves: [[Int]] = [] // contains all the previous moves. To get last move - moves.last
    
    var pinchGesture: UIPinchGestureRecognizer!
    var panGesture: UIPanGestureRecognizer!
    var tapGesture: UITapGestureRecognizer!
    
    @IBOutlet weak var titleLabel: UILabel!
//    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var panelView: UIView!
    @IBOutlet weak var currentMoveIndicator: UIView!
    @IBOutlet weak var currentMoveLabel: UILabel!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var bottomBarView: UIView!
    
    
    @IBOutlet weak var undoButton: UIButton!
    @IBAction func undoAction(_ sender: Any) {
        if !gameIsOn {
            return
        }
        if isPlayingMultiplayer {
            return
        }
        if isPlayingWithBot {
            // bot is currently moving - should wait
            if botShouldMove() {
                return
            }
            // when playing with bots, undo removes 2
            if gameMoves.count < 2 {
                return
            }
        }
        if gameMoves.count < 1 {
            return
        }
        
        if !shouldAllowUndo {
            let alert = UIAlertController.alertView(title: "Undo Disabled", message: "To enable undo, turn on Allow Undo in Settings.")
            present(alert, animated: true, completion: nil)
            return
        }
        undo()
    }
    
    @IBOutlet weak var menuButton: UIButton!
    @IBAction func menuAction(_ sender: Any) {
        rootViewController.dockMenu(translationX: view.frame.width)
    }
    
    @IBOutlet weak var hintButton: UIButton!
    @IBAction func hintAction(_ sender: Any) {
        if gameIsOn {
            if shouldAllowHints {
                let c = gameEvaluator.getMove(side: currentMove, game: game)
                setPieceTarget(c: c)
            } else {
                let alert = UIAlertController.alertView(title: "Hints Disabled", message: "To enable hints, turn on Allow Hints in Settings.")
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // animation setup
        maxDistance = (view.frame.width-boardViewSize)/2
        maxDistanceTop = view.frame.height - maxDistance - boardViewSize - bottomBarView.frame.height
        maxDistanceBottom = view.frame.height - maxDistance - boardViewSize - topBarView.frame.height
        
        
        // UI setup
        undoButton.titleLabel?.font = UIFont.fontAwesome(ofSize: toolBarFontSize)
        undoButton.setTitle(String.fontAwesomeIcon(name: .undo), for: .normal)
        undoButton.sizeToFit()
        menuButton.titleLabel?.font = UIFont.fontAwesome(ofSize: toolBarFontSize)
        menuButton.setTitle(String.fontAwesomeIcon(name: .thList), for: .normal)
        menuButton.sizeToFit()
        hintButton.titleLabel?.font = UIFont.fontAwesome(ofSize: toolBarFontSize)
        hintButton.setTitle(String.fontAwesomeIcon(name: .question), for: .normal)
        hintButton.sizeToFit()
        
        boardView = BoardView(frame: CGRect(x: 0, y: 0, width: boardViewSize, height: boardViewSize))
        boardView.center = view.center
        view.addSubview(boardView)
        
        panelView.layer.cornerRadius = panelViewCornerRadius
        panelView.alpha = panelViewAlpha
        
        bringViewsToTop()
        
        currentMoveIndicator.cornerRadius = currentMoveIndicator.frame.width/2
        
        refreshIndicator()
        
        // gesture recognizers
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(recognizer:)))
        pinchGesture.delegate = self
        view.addGestureRecognizer(pinchGesture)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.pan(recognizer:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tap(recognizer:)))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        // game setup
        game = Game()
        gameEvaluator = GameEvaluator(game: game)
        
        DataService.instance.isConnected(handler: {_ in})
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // only load game after UI is done setting up
        if shouldLoadGame {
            loadGame()
            shouldLoadGame = false
        }
    }
    
    // board size changed - reset game and board by creating new instances
    func boardResize() {
        if !isPlayingMultiplayer {
            loadSettings()
        }
        
        boardView.transform = CGAffineTransform.identity
        boardView.removeFromSuperview()
        boardView = BoardView(frame: boardView.frame)
        boardView.center = view.center
        view.addSubview(boardView)
        bringViewsToTop()
        
        resetGame() // clearing moves, pendingC etc
        game = Game()
        gameEvaluator.game = game
        
        saveCurrentGame()
    }
    
    func bringViewsToTop() {
        view.bringSubview(toFront: panelView)
        view.bringSubview(toFront: topBarView)
        view.bringSubview(toFront: bottomBarView)
    }
    
    @objc func pan(recognizer: UIPanGestureRecognizer) {
        // screen edge pan doesn't move the board, since it's used for opening menu
        let location = recognizer.location(in: view)
        let state = recognizer.state
        if location.x <= rootViewController.screenEdgeDistance && state == .began && !rootViewController.menuIsExpanded{
            shouldMoveBoard = false
        } else if state == .began {
            shouldMoveBoard = true
        }
        if !shouldMoveBoard {
            return
        }
        
        let translation = recognizer.translation(in: view)
        boardView.center = CGPoint(x: boardView.center.x + translation.x, y: boardView.center.y + translation.y)
        recognizer.setTranslation(CGPoint.zero, in: self.view)
        if state == .ended {
            snap()
        }
        clearTarget()
    }
    
    @objc func pinch(recognizer: UIPinchGestureRecognizer) {
        let scale = 1-sensitivity*(1-recognizer.scale)
        boardView.transform = boardView.transform.scaledBy(x: scale, y: scale)
        recognizer.scale = 1
        if recognizer.state == .ended {
            snap()
        }
        clearTarget()
    }
    
    @objc func tap(recognizer: UITapGestureRecognizer) {
        if gameIsOn && !botShouldMove() && !(isPlayingMultiplayer && !shouldAllowMoves) {
            if let c = boardView.boardCoords(from: recognizer.location(in: boardView)), !pointIsInView(point: recognizer.location(in: view), view: panelView) {
                let (x, y) = (c[0], c[1])
                if game.getPoint(x: x, y: y) == 0 {
                    // selected point is empty
                    // user confirms pendingC by tapping again
                    if c == pendingC {
                        if !isPlayingMultiplayer {
                            selectPoint(c: c)
                        } else {
                            multiplayerUploadMove(c: c, completion: { (message) in
                                if let message = message {
                                    self.shouldAllowMoves = true
                                    let alert = UIAlertController.alertView(title: "Error", message: message)
                                    self.present(alert, animated: true, completion: nil)
                                    self.clearTarget()
                                }
                            })
                        }
                    } else {
                        // adding a target for confirmation
                        setPieceTarget(c: c)
                    }
                } else {
                    // the point is already taken
                    clearTarget()
                }
            } else {
                // clicked somewhere outside of the board, or on the panel
                clearTarget()
            }
        } else if !isPlayingMultiplayer {
            // if game is over, tap panel to restart game
            if pointIsInView(point: recognizer.location(in: view), view: panelView) {
                resetGame()
            }
        }
    }
    
    func selectPoint(c: [Int]) {
        // selects the point
        let (x, y) = (c[0], c[1])
        game.setPoint(x: x, y: y, value: currentMove)
        boardView.addPiece(x: x, y: y, move: currentMove)
        
        gameMoves.append(c)
        
        // since bot is too quick, highlight on own piece doesn't look good
        if !(isPlayingWithBot && currentMove != botSide) || isPlayingMultiplayer {
            boardView.highlightC(c: c)
        }
        
        currentMove = currentMove == 1 ? 2 : 1
        saveCurrentGame()
        
        refreshIndicator()
        
        clearTarget {
            if self.botShouldMove() && self.gameIsOn {
                self.botMove()
            }
        }
        
        // win/tie test
        // put down here to avoid clearTarget clearing win highlights
        if let winC = game.winningCoordinates() {
            // logically, currentMove will be the winner, but currentmove was changed on top
            win(side: currentMove == 1 ? 2 : 1, winC: winC)
        } else if game.boardIsFull() {
            // board is full and no one won - tie
            win(side: 0, winC: [])
        }
        
    }
    
    func undo() {
        dataUndo()
        // twice with bots
        if isPlayingWithBot {
            dataUndo()
        }
        
        refreshIndicator()
        clearTarget()
            
        if let c = gameMoves.last {
            boardView.highlightC(c: c)
        } else {
            boardView.clearHighlight()
        }
        saveCurrentGame()
    }
    // undoes the data, but doesn't update view
    // should be called twice when playing with bot
    func dataUndo() {
        if gameMoves.count > 0 {
            let lastMove = gameMoves.last!
            gameMoves.removeLast()
            
            boardView.undo()
            game.setPoint(x: lastMove[0], y: lastMove[1], value: 0)
            
            currentMove = currentMove == 1 ? 2 : 1
        }
    }
    
    // snaps the grid to place if it is off
    func snap() {
        UIView.animate(withDuration: animationDuration) {
            // scale
            let s = self.scale(from: self.boardView.transform)
            if s > self.maxScale {
                self.boardView.transform = CGAffineTransform(scaleX: self.maxScale, y: self.maxScale)
            } else if s < 1 {
                self.boardView.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
            // translation
            var x = self.boardView.center.x
            var y = self.boardView.center.y
            if self.boardView.frame.minX > self.maxDistance {
                x = self.maxDistance + s*self.boardViewSize/2
            } else if self.boardView.frame.maxX < self.view.frame.width - self.maxDistance {
                x = self.view.frame.width - self.maxDistance - s*self.boardViewSize/2
            }
            if self.view.frame.height - self.boardView.frame.maxY > self.maxDistanceBottom {
                y = self.view.frame.height - self.maxDistanceBottom - s*self.boardViewSize/2
            } else if self.boardView.frame.minY > self.maxDistanceTop {
                y = self.maxDistanceTop + s*self.boardViewSize/2
            }
            self.boardView.center = CGPoint(x: x, y: y)
        }
    }
    
    // allows moving and pinching at the same time
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer: UIGestureRecognizer) -> Bool {
        if shouldRecognizeSimultaneouslyWithGestureRecognizer is UITapGestureRecognizer {
            return false
        }
        return true
    }
    
    func pauseGame(_ pause: Bool) {
        if pause {
            gameIsOn = false
        } else {
            gameIsOn = true
            if botShouldMove() {
                botMove()
            }
        }
    }
    
    func botShouldMove() -> Bool {
        if isPlayingWithBot && !isPlayingMultiplayer {
            return botSide == 0 || botSide == currentMove
        }
        return false
    }
    
    func setPieceTarget(c: [Int]) {
        pendingC = c
        boardView.setPieceTarget(c: c, move: currentMove)
        hasTarget = true
    }
    
    func clearTarget() {
        clearTarget(completion: nil)
    }
    
    func clearTarget(completion: (()->())?) {
        if hasTarget {
            boardView.clearTarget(completion: completion)
            pendingC = [-1, -1]
            hasTarget = false
        }
    }
    
    func refreshIndicator() {
        if !isPlayingMultiplayer {
            if isPlayingWithBot {
                statusLabel.text = "Playing with computer..."
            } else {
                statusLabel.text = "Playing 2 players locally..."
            }
        }
        UIView.animate(withDuration: animationDuration, animations: {
            self.currentMoveIndicator.transform = CGAffineTransform.init(scaleX: 0.1, y: 0.1)
        }) { (_) in
            self.currentMoveIndicator.backgroundColor = self.currentMove == 1 ? UIColor.black : UIColor.white
            UIView.animate(withDuration: self.animationDuration, animations: {
                self.currentMoveIndicator.transform = CGAffineTransform.identity
            })
        }
    }
    
    // if side is 0 and winC is empty, means tie
    func win(side: Int, winC: [[Int]]) {
        
        boardView.highlightCoordinates(coords: winC)
        gameIsOn = false
        
        handlePanelWin(side: side)
        
        gameMoves = []
        saveCurrentGame()
        
        if isPlayingMultiplayer {
            multiplayerFinish()
        }
    }
    
    func handlePanelWin(side: Int) {
        var displayStr = ""
        if side != 0 {
            displayStr = side == 1 ? "Black Victory!" : "White Victory!"
        } else {
            displayStr = "Tie!"
        }
        winLabel = UILabel(frame: panelView.frame)
        winLabel.center = CGPoint(x: winLabel.frame.width/2, y: winLabel.frame.height/2)
        winLabel.font = currentMoveLabel.font.withSize(winLabelFontSize)
        winLabel.text = displayStr
        winLabel.textAlignment = .center
        winLabel.textColor = winLabelColor
        panelView.addSubview(winLabel)
        
        currentMoveLabel.alpha = 0
        currentMoveIndicator.alpha = 0
        lineView.alpha = 0
        statusLabel.alpha = 0
    }
    
    func panelReset() {
        if winLabel != nil {
            winLabel.removeFromSuperview()
        }
        lineView.alpha = 1
        statusLabel.alpha = 1
        currentMoveLabel.alpha = 1
        currentMoveIndicator.alpha = 1
        refreshIndicator()
    }
    
    func switchGameMode() {
        if isPlayingMultiplayer {
            let alert = UIAlertController(title: "Currently in Multiplayer", message: "To change to single player, you must first quit the room.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Quit", style: .destructive, handler: { (_) in
                self.resetMultiplayer()
            }))
            present(alert, animated: true, completion: nil)
            return
        }
        let alert = UIAlertController(title: "Select Game Mode", message: "Switching game mode will also restart the game.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Play with Bot as Black", style: .default, handler: { (action) in
            gameMode = 0
            saveSettings()
            self.resetGame()
        }))
        alert.addAction(UIAlertAction(title: "Play with Bot as White", style: .default, handler: { (_) in
            gameMode = 1
            saveSettings()
            self.resetGame()
        }))
        alert.addAction(UIAlertAction(title: "2 Players", style: .default, handler: { (_) in
            gameMode = 2
            saveSettings()
            self.resetGame()
        }))
//        alert.addAction(UIAlertAction(title: "Watch Game", style: .default, handler: { (_) in
//            gameMode = 3
//            saveSettings()
//            self.resetGame()
//        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func resetGame() {
        game.reset()
        boardView.reset()
        gameMoves = []
        saveCurrentGame()
        
        prepareGameMode()
        currentMove = 1
        panelReset()
        UIView.animate(withDuration: animationDuration) {
            self.boardView.transform = CGAffineTransform.identity
            self.boardView.center = self.view.center
        }
        gameIsOn = true
        if botShouldMove() {
            botMove()
        }
    }
    
    func prepareGameMode() {
        switch gameMode {
        case 0:
            // player vs bot as black
            isPlayingWithBot = true
            botSide = 2
            break
        case 1:
            // player vs bot as white
            isPlayingWithBot = true
            botSide = 1
            break
        case 2:
            // 2 players
            isPlayingWithBot = false
            break
        case 3:
            // currently disabled
            isPlayingWithBot = true
            botSide = 0
            break
        default:
            break
        }
    }
    
    func botMove() {
        let c = gameEvaluator.getMove(side: currentMove, game: game)
        hasTarget = true
        boardView.setPieceTarget(c: c, move: botSide) {
            self.selectPoint(c: c)
        }
    }
    
    func saveCurrentGame() {
        if !isPlayingMultiplayer {
            if gameMoves.count > 0 {
                UserDefaults.standard.set(currentMove, forKey: "currentMove")
                UserDefaults.standard.set(gameMoves, forKey: "gameMoves")
            } else {
                UserDefaults.standard.set(0, forKey: "currentMove")
            }
        }
    }
    
    func loadGame() {
        let m = UserDefaults.standard.integer(forKey: "currentMove")
        if m != 0 {
            // some game is saved
            currentMove = m
            gameMoves = UserDefaults.standard.array(forKey: "gameMoves") as! [[Int]]
            
            prepareGameMode()
            boardView.load(moves: gameMoves)
            game.load(moves: gameMoves)
            panelReset()
            
            boardView.addHighlight(c: gameMoves.last!)
            
            if botShouldMove() {
                botMove()
            }
        } else {
            // no game saved
            currentMove = 1
            gameMoves = []
            
            resetGame()
        }
    }
    
    func showMultiplayer() {
        // check connectivity
        DataService.instance.isConnected { (isConnected) in
            if !isConnected {
                let alert = UIAlertController.alertView(title: "Error", message: "Unable to connect to the server. Please check your internet connection and try again.")
                self.present(alert, animated: true, completion: nil)
            } else {
            
                if self.isPlayingMultiplayer {
                    // already in multiplayer - option to quit
                    let alert = UIAlertController(title: "Room Id: \(self.currentRoom!.roomId)", message: nil, preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "Quit", style: .destructive, handler: { (_) in
                        let confirm = UIAlertController(title: "Quit Room", message: "Are you sure you want to disconnect from the room? Multiplayer games are not saved.", preferredStyle: .alert)
                        confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        confirm.addAction(UIAlertAction(title: "Quit", style: .destructive, handler: { (_) in
                            DataService.instance.deleteAllRoomsByUser(id: AuthService.instance.id, completion: {})
                            self.resetMultiplayer()
                        }))
                        self.present(confirm, animated: true, completion: nil)
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else if AuthService.instance.isLoggedOn {
                    // presents alert to choose to create/join
                    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "Create Room", style: .default, handler: { (action) in
                        // create room options
                        let idPrompt = UIAlertController(title: "Create Room", message: "Choose a room id with at most 8 characters. This will be used when joining the room.", preferredStyle: .alert)
                        idPrompt.addTextField(configurationHandler: { (textField) in
                            textField.placeholder = "Room id"
                        })
                        idPrompt.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        idPrompt.addAction(UIAlertAction(title: "Create", style: .default, handler: { (action) in
                            let textField = idPrompt.textFields![0]
                            if textField.text! == "" || textField.text!.count > 8 {
                                let a = UIAlertController.alertView(title: "Error", message: "Cannot create room because room id is invalid.")
                                self.present(a, animated: true, completion: nil)
                            } else  {
                                // id is valid - attempts to create room
                                let loading = UIAlertController.loadingView(message: "Creating Room...")
                                self.present(loading, animated: true, completion: nil)
                                DataService.instance.createAndJoinRoom(id: textField.text!, completion: { (room, message, key) in
                                    loading.dismiss(animated: true, completion: {
                                        if let room = room {
                                            // successfully created and joined room
                                            self.configureForMultiplayer(room: room, move: 1, key: key!)
                                            
                                        } else {
                                            let a = UIAlertController.alertView(title: "Error", message: message!)
                                            self.present(a, animated: true, completion: nil)
                                        }
                                    })
                                })
                            }
                        }))
                        self.present(idPrompt, animated: true, completion: nil)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Join Room", style: .default, handler: { (action) in
                        // join room options
                        let idPrompt = UIAlertController(title: "Join Room", message: "Enter the id for the room. This is chosen when creating the room.", preferredStyle: .alert)
                        idPrompt.addTextField(configurationHandler: { (textField) in
                            textField.placeholder = "Room id"
                        })
                        idPrompt.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        idPrompt.addAction(UIAlertAction(title: "Join", style: .default, handler: { (action) in
                            let textField = idPrompt.textFields![0]
                            if textField.text != "" {
                                // presents loading view
                                let loading = UIAlertController.loadingView(message: "Joining Room...")
                                self.present(loading, animated: true, completion: nil)
                                // attempt to join room
                                DataService.instance.getAndJoinRoom(textField.text!, completion: { (room, message, key, move) in
                                    loading.dismiss(animated: true, completion: {
                                        guard let room = room, let key = key else {
                                            let a = UIAlertController.alertView(title: "Error", message: message)
                                            self.present(a, animated: true, completion: nil)
                                            return
                                        }
                                        // successfully joined room. Now configures
                                        self.configureForMultiplayer(room: room, move: move, key: key)
                                    })
                                })
                            } else {
                                // id is empty
                                let error = UIAlertController.alertView(title: "Error", message: "Cannot join room with empty id.")
                                self.present(error, animated: true, completion: nil)
                            }
                        }))
                        self.present(idPrompt, animated: true, completion: nil)
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    AuthService.instance.logIn(completion: { (success) in
                        if success {
                            // attempts to go multiplayer again
                            self.showMultiplayer()
                        } else {
                            // probably has no internet connection
                            let alert = UIAlertController.alertView(title: "Error", message: "Unable to connect to multiplayer. Please check your connection and try again later.")
                            self.present(alert, animated: true, completion: nil)
                        }
                    })
                }
            }
        }
    }
    
    // make ready for multiplayer - resets game, sets variables etc
    func configureForMultiplayer(room: Room, move: Int, key: String) {
        isPlayingMultiplayer = true
        shouldAllowMoves = room.isFull
        currentRoom = room
        currentRoomKey = key
        multiplayerSide = move
        
        gameBoardSize = 15 // universal
        boardResize()
        
        resetGame()
        
        DataService.instance.startObservingRoom(key: key) { (snapshot) in
            self.roomChangeObserved(snapshot: snapshot)
        }
        
    }
    
    func multiplayerUploadMove(c: [Int], completion: @escaping (_ message: String?)->()) {
        var newGame = currentRoom!.game
        newGame.append(Game.cToIndex(c, size: 15))
        DataService.instance.updateGame(key: currentRoomKey!, game: newGame) { (message) in
            completion(message)
        }
    }
    
    func multiplayerFinish() {
        let restartPrompt = UIAlertController(title: "Game Finished", message: "Do you want to restart?", preferredStyle: .alert)
        restartPrompt.addAction(UIAlertAction(title: "Restart", style: .default, handler: { (_) in
            DataService.instance.restartGame(key: self.currentRoomKey!, completion: { (message) in
                // if have error restarting, will switch to single player
                if let message = message {
                    let alert = UIAlertController.alertView(title: "Error", message: message)
                    self.present(alert, animated: true, completion: nil)
                    self.resetMultiplayer()
                    return
                }
            })
        }))
        restartPrompt.addAction(UIAlertAction(title: "Quit", style: .cancel, handler: { (_) in
            self.resetMultiplayer()
        }))
        present(restartPrompt, animated: true, completion: nil)
    }
    
    func roomChangeObserved(snapshot: FIRDataSnapshot) {
        guard let room = Room(snapshot: snapshot) else {
            // room probably deleted, or finished
            if currentRoom != nil {
                let alert = UIAlertController.alertView(title: "Game Finished", message: "You have been disconnected from the room.")
                present(alert, animated: true, completion: {
                    self.resetMultiplayer()
                })
            }
            return
        }
        // restart
        if currentRoom!.game.count != 0 && room.game.count == 0 {
            // set up for restart
            self.resetGame()
        }
        // someone quit the game after the game is full
        if currentRoom!.isFull && !room.isFull {
            let alert = UIAlertController.alertView(title: "Game Finished", message: "Your opponent disconnected from the room.")
            self.present(alert, animated: true, completion: {
                self.resetMultiplayer()
            })
        }
        // room not full, shouldn't start yet
        if !room.isFull {
            statusLabel.text = "Waiting for another player to join..."
            return
        }
        // room is full and it's player's side - allow moves
        if room.currentSide == multiplayerSide {
            statusLabel.text = "Your turn - select a point."
            shouldAllowMoves = true
        } else {
            // last move was done by user - shouldn't really do anything
            statusLabel.text = "Waiting for opponent..."
            shouldAllowMoves = false
        }
        // checks to see if a new move has been made - then select that point
        if room.game.count > currentRoom!.game.count {
            // at most one move - otherwise the game is corrupt anyway
            // selects that point
            let lastC = Game.indexToC(room.game.last!, size: 15)
            selectPoint(c: lastC)
        }
        
        currentRoom = room
    }
    
    // reset multiplayer vars
    func resetMultiplayer() {
        DataService.instance.stopObservingRoom(key: currentRoomKey!)
        DataService.instance.deleteAllRoomsByUser(id: AuthService.instance.id, completion: {})
        currentRoom = nil
        currentRoomKey = nil
        multiplayerSide = 0
        isPlayingMultiplayer = false
        loadSettings() // to restore board size
        
        boardResize()
        resetGame()
    }
    
    
    func applyTheme(_ theme: ColorTheme) {
        view.backgroundColor = theme.bgColor
        
        topBarView.backgroundColor = theme.barColor
        bottomBarView.backgroundColor = theme.barColor
        
        panelView.backgroundColor = theme.panelColor
        
        titleLabel.textColor = theme.textColor
        undoButton.setTitleColor(theme.textColor, for: .normal)
        undoButton.setTitleColor(theme.btnDisabledColor, for: .disabled)
        menuButton.setTitleColor(theme.textColor, for: .normal)
        hintButton.setTitleColor(theme.textColor, for: .normal)
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // https://www.hackingwithswift.com/example-code/core-graphics/how-to-find-the-scale-from-a-cgaffinetransform
    func scale(from transform: CGAffineTransform) -> CGFloat {
        return CGFloat(sqrt(Double(transform.a * transform.a + transform.c * transform.c)))
    }
    // https://www.hackingwithswift.com/example-code/core-graphics/how-to-find-the-translation-from-a-cgaffinetransform
    func translation(from transform: CGAffineTransform) -> CGPoint {
        return CGPoint(x: transform.tx, y: transform.ty)
    }
    
}


