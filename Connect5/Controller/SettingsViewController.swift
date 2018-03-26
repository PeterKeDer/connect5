//
//  SettingsViewController.swift
//  Connect5
//
//  Created by Peter Ke on 2017-11-05.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var rootViewController: RootViewController!
    var tableViewController: SettingsTableViewController!
    var tableView: UITableView!
    
    var panGesture: UIScreenEdgePanGestureRecognizer!
    
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    @IBAction func backAction(_ sender: Any) {
        rootViewController.hideView(view: view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 22)
        backButton.setTitle(String.fontAwesomeIcon(name: .chevronLeft), for: .normal)
        
        panGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.pan(recognizer:)))
        panGesture.edges = .left
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }
    
    @objc func pan(recognizer: UIScreenEdgePanGestureRecognizer) {
        let state = recognizer.state
        if state == .began {
            tableView.isScrollEnabled = false
        } else if state == .ended || state == .cancelled {
            tableView.isScrollEnabled = true
        }
        
        rootViewController.animateView(view: view, recognizer: recognizer)
    }
    
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func applyTheme(_ theme: ColorTheme) {
        backButton.setTitleColor(theme.textColor, for: .normal)
        topBarView.backgroundColor = theme.barColor
//        view.backgroundColor = theme.bgColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // setting table view, to be used to disable scroll
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SettingsTableViewController {
            tableView = vc.tableView
            tableView.isScrollEnabled = true
            tableViewController = vc
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
