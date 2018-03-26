//
//  RootViewController.swift
//  Connect5
//
//  Created by Peter Ke on 2017-11-05.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    
    var mainView: UIView! // is actually not the view mainViewController controls. Contains mainViewController
    var mainViewController: MainViewController! // home, where the game takes place
    var menuViewController: MenuViewController! // menu
    var settingsViewController: SettingsViewController! // contains the ContainerView for settingsTableView
    var settingsTableViewController: SettingsTableViewController! // settings
    
    var darkCover: UIView! // darkens the mainView while animation
    var retractGesture: UITapGestureRecognizer! // tap gesture for retracting menu
    var panGesture: UIPanGestureRecognizer! // gesture for opening/closing menu
    
    var disablePan: Bool = false // disabled when menu is not expanded and pan is not on edge - sliding board
    var isOnMainPage: Bool = true
    var menuIsExpanded: Bool = false
    
    let menuWidth: CGFloat = 250
    var screenHeight: CGFloat!
    var screenWidth: CGFloat!
    let mainViewMoveRatio: CGFloat = 0.51 // amount of mainViewController that moves right during animation
    let dockDifficulty: CGFloat = 0.25 // ratio of screenwidth needed to cover for the menu to be autodocked expanded
    let animationCoveredRatio: CGFloat = 0.65 // the amount of screen the menu covers during the animation
    let animationPullDifference = 6 // the higher it is, the less difference there is. Minimum 1
    let animationDuration = 0.3
    let darkCoverAlpha: CGFloat = 0.8 // when fully expanded
    let screenEdgeDistance: CGFloat = 45 // distance from the edge to count as edgepan
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSettings()
        
        screenWidth = view.frame.width
        screenHeight = view.frame.height
        
        mainView = UIView(frame: view.frame)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        mainViewController.rootViewController = self
        
        mainView.addSubview(mainViewController.view)
        
        darkCover = UIView(frame: CGRect(x: 0, y: 0, width: self.screenWidth, height: self.screenHeight))
        darkCover.backgroundColor = UIColor.black
        darkCover.alpha = 0
        mainView.addSubview(darkCover)
        view.addSubview(mainView)
        
        menuViewController = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        menuViewController.view.frame = CGRect(x: -menuWidth, y: 0, width: menuWidth, height: screenHeight)
        menuViewController.rootViewController = self
        menuViewController.mainViewController = mainViewController
        view.addSubview(menuViewController.view)
        
        settingsViewController = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        settingsViewController.view.frame = CGRect(origin: CGPoint(x: view.frame.maxX, y: 0), size: view.frame.size)
        settingsViewController.rootViewController = self
        settingsViewController.tableViewController.rootViewController = self
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.pan(recognizer:)))
        view.addGestureRecognizer(panGesture)
        
        retractGesture = UITapGestureRecognizer(target: self, action: #selector(self.tap(recognizer:)))
        retractGesture.cancelsTouchesInView = false
        mainView.addGestureRecognizer(retractGesture)
        
        applyCurrentTheme()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if firstTimeOpening {
            presentTutorial()
            firstTimeOpening = false
        }
    }
    
    @objc func pan(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: mainView)
        let state = recognizer.state
        if location.x > screenEdgeDistance && state == .began && !menuIsExpanded {
            disablePan = true
        } else if state == .began {
            disablePan = false
        }
        if disablePan || !isOnMainPage {
            return
        }
        
        let translationX = recognizer.translation(in: self.mainView).x
        
        mainViewController.view.endEditing(true)
        if menuIsExpanded {
            if translationX < -20 {
                dockMenu(translationX: 0)
            }
        } else {
            if translationX >= 0 {
                if state == .ended {
                    dockMenu(translationX: translationX)
                } else {
                    animateMenu(x: translationX)
                }
            } else {
                dockMenu(translationX: 0)
            }
        }
        
    }
    
    @objc func tap(recognizer: UITapGestureRecognizer) {
        
        let location = recognizer.location(in: self.mainView)
        // if location.x is bigger than 0, it means that it is in mainView
        if self.menuIsExpanded && location.x >= 0 {
            self.dockMenu(translationX: 0)
        }
    }
    
    func dockMenu(translationX: CGFloat) {
        if translationX >= self.screenHeight * self.dockDifficulty {
            // expands
            UIView.animate(withDuration: self.animationDuration, animations: {
                self.menuViewController.view.frame = CGRect(x: 0, y: 0, width: self.menuWidth, height: self.screenHeight)
                self.mainView.frame = CGRect(x: self.menuWidth*self.mainViewMoveRatio, y: 0, width: self.screenWidth, height: self.screenHeight)
                self.darkCover.alpha = self.darkCoverAlpha * self.menuWidth/self.screenWidth
            }, completion: { (Bool) in
                self.menuIsExpanded = true
            })
        } else {
            // retracts
            UIView.animate(withDuration: self.animationDuration, animations: {
                self.menuViewController.view.frame = CGRect(x: -self.menuWidth, y: 0, width: self.menuWidth, height: self.screenHeight)
                self.mainView.frame = CGRect(x: 0, y: 0, width: self.screenWidth, height: self.screenHeight)
                self.darkCover.alpha = 0
            }, completion: { (Bool) in
                self.menuIsExpanded = false
            })
        }
    }
    
    // animates menu given a x translation
    func animateMenu(x: CGFloat) {
        let completionRatio = -1/((x/screenWidth + 1) * (x/screenWidth + 1)) + 1
        let xPosition = screenWidth * animationCoveredRatio * completionRatio
        menuViewController.view.frame = CGRect(x: xPosition-menuWidth, y: 0, width: menuWidth, height: screenHeight)
        mainView.frame = CGRect(x: menuViewController.view.frame.maxX*mainViewMoveRatio, y: 0,width: screenWidth, height: screenHeight)
        darkCover.alpha = darkCoverAlpha * xPosition/screenWidth
        
    }
    
    func showView(view: UIView) {
        if isOnMainPage {
            self.view.addSubview(view)
        }
        isOnMainPage = false
        UIView.animate(withDuration: animationDuration) {
            self.mainView.center = CGPoint(x: -self.mainView.frame.width*self.mainViewMoveRatio, y: self.view.center.y)
            view.center = self.view.center
            self.darkCover.alpha = self.darkCoverAlpha
        }
    }
    func hideView(view: UIView) {
        UIView.animate(withDuration: animationDuration, animations: {
            self.mainView.center = self.view.center
            view.center = CGPoint(x: self.view.frame.maxX + self.view.frame.width/2, y: self.view.center.y)
            self.darkCover.alpha = 0
        }) { (_) in
            view.removeFromSuperview()
            self.isOnMainPage = true
            self.mainViewController.viewDidAppear(true)
        }
    }
    // animates the return of a view (settings) given pan
    func animateView(view: UIView, recognizer: UIScreenEdgePanGestureRecognizer) {
        let x = recognizer.translation(in: view).x
        let translationX = x > 0 ? x : 0
        let completionRatio = translationX/self.view.frame.width
        
        mainView.center = CGPoint(x: self.view.center.x - mainViewMoveRatio * (1-completionRatio) * mainView.frame.width, y: self.view.center.y)
        view.center = CGPoint(x: self.view.center.x + translationX, y: view.center.y)
        darkCover.alpha = darkCoverAlpha * (1-completionRatio)
        
        if recognizer.state == .ended {
            if translationX < dockDifficulty*self.view.frame.width {
                showView(view: view)
            } else {
                hideView(view: view)
            }
        }
    }
    
    func presentTutorial() {
        performSegue(withIdentifier: "ShowTutorial", sender: self)
    }
    
    func applyCurrentTheme() {
        let theme = ColorTheme.getTheme(name: currentThemeName)
        mainViewController.applyTheme(theme)
        menuViewController.applyTheme(theme)
        settingsViewController.applyTheme(theme)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
