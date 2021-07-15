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
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
        
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        getGameAttributeValuesFromSwitches()
        if viewedGame.hasBoard || viewedGame.hasCabinetHardware {
            masterCollection.myGames.append(viewedGame)
            masterCollection.myGamesCollection.addToGames(viewedGame)
        } else if !viewedGame.hasBoard && !viewedGame.hasCabinetHardware {
            let removalIndex = masterCollection.myGames.firstIndex(of: viewedGame)
            masterCollection.myGames.remove(at: removalIndex!)
            masterCollection.myGamesCollection.removeFromGames(viewedGame)
        }
        try? dataController.viewContext.save()
        dismiss(animated: true, completion: nil)
        }
    
    @IBAction func enableBoardTraits(_ sender: UISwitch) {
        if sender.isOn == true {
            isBootleg.isEnabled = true
            functionalCondition.isEnabled = true
        } else {
            isBootleg.isEnabled = false; isBootleg.isOn = false
            functionalCondition.isEnabled = false
            
            }
        }
    
    @IBAction func enableCabinetTraits(_ sender: UISwitch) {
        if sender.isOn == true {
            hasCabinet.isEnabled = true
            hasMonitorFlag.isEnabled = true
            hasControls.isEnabled = true
            hasBezel.isEnabled = true
            hasControlPanelOverlay.isEnabled = true
            hasCabinetArt.isEnabled = true
            hasMarquee.isEnabled = true
        } else {
            hasCabinet.isEnabled = false; hasCabinet.isOn = false
            hasMonitorFlag.isEnabled = false; hasMonitorFlag.isOn = false
            hasControls.isEnabled = false; hasControls.isOn = false
            hasBezel.isEnabled = false; hasBezel.isOn = false
            hasControlPanelOverlay.isEnabled = false; hasControlPanelOverlay.isOn = false
            hasCabinetArt.isEnabled = false; hasCabinetArt.isOn = false
            hasMarquee.isEnabled = false; hasMarquee.isOn = false
        }
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
    
    func setSwitches() {
        //values set to false / 0 upon json decode
        
        if viewedGame.hasBoard {hasBoard.isOn = true} else {hasBoard.isOn = false}
        if viewedGame.isBootleg {isBootleg.isOn = true} else {isBootleg.isOn = false}
        if viewedGame.hasCabinetArt {hasCabinetArt.isOn = true} else {hasCabinetArt.isOn = false}
        if viewedGame.hasControlPanelOverlay {hasControlPanelOverlay.isOn = true} else {hasControlPanelOverlay.isOn = false}
        if viewedGame.hasControls {hasControls.isOn = true} else {hasControls.isOn = false}
        if viewedGame.hasBoard {hasCabinetHardware.isOn = true} else {hasCabinetHardware.isOn = false}
        if viewedGame.hasCabinet {hasCabinet.isOn = true} else {hasCabinet.isOn = false}
        if viewedGame.hasBezel {hasBezel.isOn = true} else {hasBezel.isOn = false}
        if viewedGame.hasMonitorFlag {hasMonitorFlag.isOn = true} else {hasMonitorFlag.isOn = false}
        if viewedGame.hasMarquee {hasMarquee.isOn = true} else {hasMarquee.isOn = false}
        functionalCondition.selectedSegmentIndex = 0
    }
}
