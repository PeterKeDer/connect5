//
//  MenuViewController.swift
//  Connect5
//
//  Created by Peter Ke on 2017-11-05.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var rootViewController: RootViewController!
    var mainViewController: MainViewController!
    
    // note - all icon labels are shifted down 1 unit using autolayout to look better
    var cellHeight: CGFloat = 45
    var iconFont = UIFont.fontAwesome(ofSize: 22)
    var titleFont = UIFont(name: "Futura", size: 20)
    var cellTextColor = UIColor.black
    var icons = [String.fontAwesomeIcon(name: .playCircleO), String.fontAwesomeIcon(name: .list), String.fontAwesomeIcon(name: .users), String.fontAwesomeIcon(name: .gear), String.fontAwesomeIcon(name: .questionCircleO)]
    var titles = ["New Game","Game Mode", "Multiplayer", "Settings", "Help"]
    var tableBgColor = UIColor.clear
    var separatorColor = UIColor.clear
    
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.isScrollEnabled = false
        tableView.separatorColor = separatorColor
        tableView.backgroundColor = tableBgColor
    }
    
    func handleAction(index: Int) {
        rootViewController.dockMenu(translationX: 0)
        tableView.deselectRow(at: IndexPath(row: index, section: 0), animated: true)
        
        switch index {
        case 0:
            if !mainViewController.isPlayingMultiplayer {
                mainViewController.resetGame()
            }
            break
        case 1:
            mainViewController.switchGameMode()
            break
        case 2:
            mainViewController.showMultiplayer()
            break
        case 3:
            rootViewController.showView(view: rootViewController.settingsViewController.view)
            break
        case 4:
            rootViewController.presentTutorial()
            break
        default:
            break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func applyTheme(_ theme: ColorTheme) {
        view.backgroundColor = theme.bgColor
        topBarView.backgroundColor = theme.barColor
        titleLabel.textColor = theme.textColor
        cellTextColor = theme.bgTextColor
        tableView.reloadData()
    }
    
    // tableView functions
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuTableViewCell") as! MenuTableViewCell
        cell.iconLabel.text = icons[indexPath.row]
        cell.iconLabel.font = iconFont
        cell.iconLabel.textColor = cellTextColor
        cell.titleLabel.text = titles[indexPath.row]
        cell.titleLabel.font = titleFont
        cell.titleLabel.textColor = cellTextColor
        cell.backgroundColor = tableBgColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return icons.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleAction(index: indexPath.row)
    }

}
