//
//  Stuffs.swift
//  Connect5
//
//  Created by Peter Ke on 2017-11-05.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import UIKit

var shouldLoadGame = true // only loads the first time game opens, since viewDidAppear is called when tutorial is closed
var firstTimeOpening = false

let currentVersion: String = "1.1"

// settings
var shouldHighlightLastMove: Bool = true
var shouldShowWinningMove: Bool = true
var shouldAllowHints: Bool = true
var shouldAllowUndo: Bool = true
var currentThemeName: String = "blue"
var gameBoardSize: Int = 15 // from 9 - 21, default 15
var gameMode: Int = 0 // 0: play AI as black, 1: as white, 2: 2 players, 3: bot vs bot

func saveSettings() {
    UserDefaults.standard.set(shouldHighlightLastMove, forKey: "shouldHighlightLastMove")
    UserDefaults.standard.set(shouldShowWinningMove, forKey: "shouldShowWinningMove")
    UserDefaults.standard.set(shouldAllowHints, forKey: "shouldAllowHints")
    UserDefaults.standard.set(shouldAllowUndo, forKey: "shouldAllowUndo")
    UserDefaults.standard.set(currentThemeName, forKey: "currentColorTheme")
    UserDefaults.standard.set(gameBoardSize, forKey: "gameBoardSize")
    UserDefaults.standard.set(gameMode, forKey: "gameMode")
    
}
func loadSettings() {
    loadVersion()
    if let theme = UserDefaults.standard.string(forKey: "currentColorTheme") {
        currentThemeName = theme
        shouldHighlightLastMove = UserDefaults.standard.bool(forKey: "shouldHighlightLastMove")
        shouldShowWinningMove = UserDefaults.standard.bool(forKey: "shouldShowWinningMove")
        shouldAllowHints = UserDefaults.standard.bool(forKey: "shouldAllowHints")
        shouldAllowUndo = UserDefaults.standard.bool(forKey: "shouldAllowUndo")
        gameBoardSize = UserDefaults.standard.integer(forKey: "gameBoardSize")
        gameMode = UserDefaults.standard.integer(forKey: "gameMode")
    } else {
        // first time
        firstTimeOpening = true
        saveSettings()
    }
}

func loadVersion() {
    if let version = UserDefaults.standard.string(forKey: "currentVersion"), version == currentVersion {
        
    } else {
        firstTimeOpeningAfterUpdate()
    }
}
func firstTimeOpeningAfterUpdate() {
    // first time in new version
    // configure data...
    
}

func alert(title: String?, message: String?, vc: UIViewController) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: nil))
    vc.present(alert, animated: true, completion: nil)
}

struct ColorTheme {
    var bgColor: UIColor
    var bgTextColor: UIColor
    var barColor: UIColor
    var textColor: UIColor
    var btnDisabledColor: UIColor
    var panelColor: UIColor
    
    static func blue() -> ColorTheme {
        return ColorTheme(bgColor: #colorLiteral(red: 0.9141396164, green: 1, blue: 1, alpha: 1), bgTextColor: UIColor.black, barColor: #colorLiteral(red: 0.368627451, green: 0.8509803922, blue: 1, alpha: 1), textColor: UIColor.white, btnDisabledColor: #colorLiteral(red: 0.2697035846, green: 0.6229511336, blue: 0.8287185968, alpha: 1), panelColor: #colorLiteral(red: 0.6806736366, green: 0.8573532603, blue: 0.9682617188, alpha: 1))
    }
    
    static func green() -> ColorTheme {
        return ColorTheme(bgColor: #colorLiteral(red: 0.9402825649, green: 1, blue: 0.8748295803, alpha: 1), bgTextColor: UIColor.black, barColor: #colorLiteral(red: 0.6432562934, green: 0.9333496093, blue: 0.5089518229, alpha: 1), textColor: UIColor.white, btnDisabledColor: #colorLiteral(red: 0.5, green: 0.7600097656, blue: 0.5239800347, alpha: 1), panelColor: #colorLiteral(red: 0.7548260224, green: 0.9339361919, blue: 0.6838995086, alpha: 1))
    }
    
    static func orange() -> ColorTheme {
        return ColorTheme(bgColor: #colorLiteral(red: 1, green: 0.9145507812, blue: 0.8119023906, alpha: 1), bgTextColor: UIColor.black, barColor: #colorLiteral(red: 1, green: 0.7113130027, blue: 0.2845966618, alpha: 1), textColor: UIColor.white, btnDisabledColor: #colorLiteral(red: 0.8225700855, green: 0.5419874191, blue: 0.09898546007, alpha: 1), panelColor: #colorLiteral(red: 0.9453798401, green: 0.7845696874, blue: 0.5353378488, alpha: 1))
    }
    
    static func gray() -> ColorTheme {
        return ColorTheme(bgColor: #colorLiteral(red: 0.9019607843, green: 0.9019607843, blue: 0.9019607843, alpha: 1), bgTextColor: UIColor.black, barColor: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1), textColor: UIColor.white, btnDisabledColor: #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), panelColor: #colorLiteral(red: 0.7843137255, green: 0.7843137255, blue: 0.7843137255, alpha: 1))
    }
    
    static func getTheme(name: String) -> ColorTheme {
        switch name {
        case "blue":
            return blue()
        case "green":
            return green()
        case "orange":
            return orange()
        case "gray":
            return gray()
        default:
            return blue()
        }
    }
    
}

struct Tutorial {
    var title: String
    var text: String
    var image: UIImage
    
    init(title: String, text: String, image: UIImage) {
        self.title = title
        self.text = text
        self.image = image
    }
    
    static func fetchTutorials() -> [Tutorial] {
        return [
            Tutorial(title: "Connect 5.",
                     text: "Welcome to Connect 5, a simple game\nthat involves strategy and planning.\nSuitable for everyone.",
                     image: UIImage(named: "1")!),
            Tutorial(title: "Simple Rules.",
                     text: "Two players put down pieces on the\nboard alternately. The first player who\nconnects 5 pieces in a row wins.",
                     image: UIImage(named: "2")!),
            Tutorial(title: "Intuitive Controls.",
                     text: "Slide to move the board. Pinch to zoom.\nTap once to select a point, tap again to\nconfirm. When the game is finished, tap\non the panel to restart.",
                     image: UIImage(named: "3")!),
            Tutorial(title: "Game Modes.",
                     text: "Practice the game with our smart AI.\nOr play with a friend locally or using\nonline multiplayer.",
                     image: UIImage(named: "4")!),
            Tutorial(title: "Extra Features.",
                     text: "Go into settings to customize the colour\ntheme, enable undo and hints, and even\nchange the board size!",
                     image: UIImage(named: "5")!)
        ]
    }
}


func pointIsInView(point: CGPoint, view: UIView) -> Bool {
    let f = view.frame
    return point.x >= f.minX && point.x <= f.maxX && point.y >= f.minY && point.y <= f.maxY
}

func average(a: [Int]) -> Double {
    var total: Double = 0
    for n in a {
        total += Double(n)
    }
    return total/Double(a.count)
}

extension UIAlertController {
    static func loadingView(message: String) -> UIAlertController {
        let loading = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        return loading
    }
    static func alertView(title: String?, message: String?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: nil))
        return alert
    }
}


// enables to add borders from storyboard
// from http://stackoverflow.com/questions/28854469/change-uibutton-bordercolor-in-storyboard
extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}





