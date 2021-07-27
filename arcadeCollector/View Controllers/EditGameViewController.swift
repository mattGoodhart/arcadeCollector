//
//  EditGamePopOver.swift
//  arcadeCollector
//
//  Created by TrixxMac on 4/11/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

class EditGameViewController: UIViewController {
    
    var tabBar : UITabBar!
    let dataController = DataController.shared
    let masterCollection = CollectionManager.shared
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var viewedGame: Game!
    
    @IBOutlet weak var hasBoard: UISwitch!
    @IBOutlet weak var isBootleg: UISwitch!
    @IBOutlet weak var functionalCondition: UISegmentedControl!
    @IBOutlet weak var hasCabinetArt: UISwitch!
    @IBOutlet weak var hasControlPanelOverlay: UISwitch!
    @IBOutlet weak var hasControls: UISwitch!
    @IBOutlet weak var hasCabinetHardware: UISwitch!
    @IBOutlet weak var hasCabinet: UISwitch!
    @IBOutlet weak var hasBezel: UISwitch!
    @IBOutlet weak var hasMonitorFlag: UISwitch!
    @IBOutlet weak var hasMarquee: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        setSwitches()
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appDelegate.allowedOrientations = .portrait
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        getGameAttributeValuesFromSwitches()
        if viewedGame.hasBoard || viewedGame.hasCabinetHardware {
            
            if !masterCollection.myGames.contains(viewedGame) {
                masterCollection.myGames.append(viewedGame) // can I do this only ifNecessary?
                masterCollection.myGamesCollection.addToGames(viewedGame)
            }
            
        } else if !viewedGame.hasBoard && !viewedGame.hasCabinetHardware {
            if let removalIndex = masterCollection.myGames.firstIndex(of: viewedGame) {
                masterCollection.myGames.remove(at: removalIndex)
                masterCollection.myGamesCollection.removeFromGames(viewedGame)
            }
        }
        
        try? dataController.viewContext.save()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func boardSwitchTapped(_ sender: UISwitch) {
        if sender.isOn {
            enableBoardTraits(state: true)
        } else {
            enableBoardTraits(state: false)
        }
    }
    
    @IBAction func cabinetHardwareSwitchTapped(_ sender: UISwitch) {
        if sender.isOn {
            enableCabinetTraits(state: true)
        } else {
            enableCabinetTraits(state: false)
        }
    }
        
        func enableBoardTraits(state: Bool) {
            isBootleg.isEnabled = state
            functionalCondition.isEnabled = state
        }
    
    func enableCabinetTraits(state: Bool) {
        hasCabinet.isEnabled = state
        hasMonitorFlag.isEnabled = state
        hasControls.isEnabled = state
        hasBezel.isEnabled = state
        hasControlPanelOverlay.isEnabled = state
        hasCabinetArt.isEnabled = state
        hasMarquee.isEnabled = state
    }
    
    func getGameAttributeValuesFromSwitches() {
        if hasBoard.isOn {viewedGame.hasBoard = true} else {viewedGame.hasBoard = false}
        if isBootleg.isOn {viewedGame.isBootleg = true} else {viewedGame.isBootleg = false}
        if hasCabinetArt.isOn {viewedGame.hasCabinetArt = true} else {viewedGame.hasCabinetArt = false}
        if hasControlPanelOverlay.isOn {viewedGame.hasControlPanelOverlay = true} else {viewedGame.hasControlPanelOverlay = false}
        if hasControls.isOn {viewedGame.hasControls = true} else {viewedGame.hasControls = false}
        if hasCabinetHardware.isOn {viewedGame.hasCabinetHardware = true} else {viewedGame.hasCabinetHardware = false}
        if hasCabinet.isOn {viewedGame.hasCabinet = true} else {viewedGame.hasCabinet = false}
        if hasBezel.isOn {viewedGame.hasBezel = true} else {viewedGame.hasBezel = false}
        if hasMonitorFlag.isOn {viewedGame.hasMonitorFlag = true} else {viewedGame.hasMonitorFlag = false}
        viewedGame.functionalCondition = Int16(functionalCondition.selectedSegmentIndex)
    }
    
    func setSwitches() { //values set to false / 0 upon json decode
        if viewedGame.hasBoard {hasBoard.isOn = true; enableBoardTraits(state: true)} else {hasBoard.isOn = false; enableBoardTraits(state: false)}
        if viewedGame.isBootleg {isBootleg.isOn = true} else {isBootleg.isOn = false}
        if viewedGame.hasCabinetArt {hasCabinetArt.isOn = true} else {hasCabinetArt.isOn = false}
        if viewedGame.hasControlPanelOverlay {hasControlPanelOverlay.isOn = true} else {hasControlPanelOverlay.isOn = false}
        if viewedGame.hasControls {hasControls.isOn = true} else {hasControls.isOn = false}
        if viewedGame.hasCabinetHardware {hasCabinetHardware.isOn = true;} else {hasCabinetHardware.isOn = false;}
        if viewedGame.hasCabinet {hasCabinet.isOn = true} else {hasCabinet.isOn = false}
        if viewedGame.hasBezel {hasBezel.isOn = true} else {hasBezel.isOn = false}
        if viewedGame.hasMonitorFlag {hasMonitorFlag.isOn = true} else {hasMonitorFlag.isOn = false}
        if viewedGame.hasMarquee {hasMarquee.isOn = true} else {hasMarquee.isOn = false}
        functionalCondition.selectedSegmentIndex = Int(viewedGame.functionalCondition)
    }
}
