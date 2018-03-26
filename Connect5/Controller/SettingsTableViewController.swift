//
//  SettingsTableViewController.swift
//  Connect5
//
//  Created by Peter Ke on 2017-11-06.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    let colorThemes = ["blue", "green", "orange", "gray"]
    
    var rootViewController: RootViewController!
    
    var boardSizeAlreadyChanged = false // set true when confirm board change is hit
    
    @IBOutlet weak var highlightSwitch: UISwitch!
    @IBAction func enableHighlightLastMove(_ sender: UISwitch) {
        shouldHighlightLastMove = highlightSwitch.isOn
        saveSettings()
    }
    @IBOutlet weak var winningMoveSwitch: UISwitch!
    @IBAction func enableShowWinningMove(_ sender: UISwitch) {
        shouldShowWinningMove = winningMoveSwitch.isOn
        saveSettings()
    }
    @IBOutlet weak var hintsSwitch: UISwitch!
    @IBAction func enableHints(_ sender: UISwitch) {
        shouldAllowHints = hintsSwitch.isOn
        saveSettings()
        
    }
    @IBOutlet weak var undoSwitch: UISwitch!
    @IBAction func enableUndo(_ sender: UISwitch) {
        shouldAllowUndo = undoSwitch.isOn
        saveSettings()
    }
    
    @IBOutlet weak var boardSizePickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        highlightSwitch.isOn = shouldHighlightLastMove
        winningMoveSwitch.isOn = shouldShowWinningMove
        hintsSwitch.isOn = shouldAllowHints
        undoSwitch.isOn = shouldAllowUndo
        
        boardSizePickerView.delegate = self
        boardSizePickerView.dataSource = self
        boardSizePickerView.selectRow((gameBoardSize-9)/2, inComponent: 0, animated: false)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        boardSizeAlreadyChanged = false
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
            return 162
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if indexPath.section == 1 {
            cell.accessoryType = colorThemes[indexPath.row] == currentThemeName ? .checkmark : .none
        } else if indexPath.section == 2 {
            
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 && currentThemeName != colorThemes[indexPath.row] {
            // color themes
            currentThemeName = colorThemes[indexPath.row]
            saveSettings()
            
            tableView.reloadSections([indexPath.section] as IndexSet, with: .none)
            
            // applies new color theme
            rootViewController.applyCurrentTheme()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension SettingsTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 7
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let size = 9 + 2*row
        return "\(size) × \(size)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if !boardSizeAlreadyChanged && gameBoardSize != 9 + 2*row {
            let alert = UIAlertController(title: "Change Size?", message: "Changing the board size will restart the current game.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                self.boardSizePickerView.selectRow((gameBoardSize-9)/2, inComponent: 0, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (_) in
                self.boardSizeAlreadyChanged = true
                gameBoardSize = 9 + 2*row
                saveSettings()
                if !self.rootViewController.mainViewController.isPlayingMultiplayer {
                    self.rootViewController.mainViewController.boardResize()
                }
            }))
            rootViewController.settingsViewController.present(alert, animated: true, completion: nil)
        } else if boardSizeAlreadyChanged {
            gameBoardSize = 9 + 2*row
            saveSettings()
            rootViewController.mainViewController.boardResize()
        }
    }
}
