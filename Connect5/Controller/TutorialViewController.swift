//
//  TutorialViewController.swift
//  Connect5
//
//  Created by Peter Ke on 2017-11-18.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    var panGesture: UIPanGestureRecognizer!
    
    var tutorials = Tutorial.fetchTutorials()
    var viewsToMove: [UIView] = []
    
    var currentXIndex: Int = 0 // index of current picture presented on screen
    var lastX: CGFloat = 0
    var screenHeight: CGFloat!
    var screenWidth: CGFloat!
    // image width and height are the same
    let imageLength: CGFloat = 490
    let imageYOffsetFromCenter: CGFloat = 80
    let titleYOffsetFromTop: CGFloat = 55
    let textTopYOffsetFromTitle: CGFloat = 10
    let buttonHeight: CGFloat = 60
    let buttonWidth: CGFloat = 120
    let buttonCornerRadius: CGFloat = 12
    let minimumPanRatio: CGFloat = 0.2 // minimum amount of screen to slide to go to next page
    let animationDuration: TimeInterval = 0.15
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screenWidth = view.frame.width
        screenHeight = view.frame.height
        
        pageControl.numberOfPages = tutorials.count + 1
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan(recognizer:)))
        view.addGestureRecognizer(panGesture)
        
        initiateViews()
        
        let theme = ColorTheme.getTheme(name: currentThemeName)
        view.backgroundColor = theme.bgColor
        pageControl.pageIndicatorTintColor = theme.panelColor
        pageControl.currentPageIndicatorTintColor = theme.barColor
    }
    
    @objc func pan(recognizer: UIPanGestureRecognizer) {
        let translationX = recognizer.translation(in: view).x
        let state = recognizer.state
        if state == .began || state == .changed {
            moveView(x: translationX - lastX)
            lastX = translationX
        } else {
            // end
            var t = -lastX // distance to be translated in the end
            if translationX >= minimumPanRatio*screenWidth {
                // direction right - scrolls left
                if currentXIndex > 0 {
                    currentXIndex -= 1
                    t += screenWidth
                } else {
                    // currentX can't be smaller
                    currentXIndex = 0
                }
            } else if translationX <= -minimumPanRatio*screenWidth {
                // direction left - scrolls right
                if currentXIndex < tutorials.count {
                    currentXIndex += 1
                    t -= screenWidth
                    
                    // quits when reached the end
                    if currentXIndex == tutorials.count {
                        quit()
                    }
                } else {
                    // currentX can't be bigger
                    currentXIndex = tutorials.count
                }
                
            } else {
                // stay on same page - currentX doesn't change
            }
            updatePageControll(currentPage: currentXIndex)
            
            lastX = 0
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.moveView(x: t) // resets position
            })
        }
    }
    
    // positions all views x by x
    func moveView(x: CGFloat) {
        for view in self.viewsToMove {
            view.center.x += x
        }
    }
    
    func initiateViews() {
        for i in 0...tutorials.count-1 {
            let guide = tutorials[i]
            let imageView = UIImageView(image: guide.image)
            imageView.frame = CGRect(x: 0, y: 0, width: imageLength, height: imageLength)
            imageView.center = CGPoint(x: (CGFloat(i)+0.5)*screenWidth, y: screenHeight/2 + imageYOffsetFromCenter)
            viewsToMove.append(imageView)
            view.addSubview(imageView)
            
            let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            titleLabel.font = UIFont(name: "Futura-Bold", size: 30)
            titleLabel.text = guide.title
            titleLabel.sizeToFit()
            titleLabel.center = CGPoint(x: (CGFloat(i)+0.5)*screenWidth, y: titleYOffsetFromTop)
            titleLabel.textAlignment = .center
            viewsToMove.append(titleLabel)
            view.addSubview(titleLabel)
            
            let textLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            textLabel.numberOfLines = 0
            textLabel.textAlignment = .center
            textLabel.font = UIFont(name: "Futura", size: 18)
            textLabel.text = guide.text
            textLabel.sizeToFit()
            textLabel.center = CGPoint(x: (CGFloat(i)+0.5)*screenWidth, y: textTopYOffsetFromTitle + titleLabel.frame.maxY + textLabel.frame.height/2)
            viewsToMove.append(textLabel)
            view.addSubview(textLabel)
        }
        // when scrolled to final page, will automatically quit
    }
    
    @objc func quit() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func updatePageControll(currentPage: Int) {
        pageControl.currentPage = currentPage
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
