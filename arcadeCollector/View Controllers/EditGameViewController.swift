//
//  EditGamePopOver.swift
//  arcadeCollector
//
//  Created by TrixxMac on 4/11/21.
//  Copyright © 2021 CatBoiz. All rights reserved.

import UIKit

class EditGameViewController: UIViewController {
    
    @IBOutlet weak var hasBoard: UISwitch!
    @IBOutlet weak var authenticity: UISegmentedControl!
    @IBOutlet weak var functionalCondition: UISegmentedControl!
    @IBOutlet weak var hasCabinetArt: UISwitch!
    @IBOutlet weak var hasControlPanelOverlay: UISwitch!
    @IBOutlet weak var hasControls: UISwitch!
    @IBOutlet weak var hasCabinet: UISwitch!
    @IBOutlet weak var hasBezel: UISwitch!
    @IBOutlet weak var hasMonitorFlag: UISwitch!
    @IBOutlet weak var hasMarquee: UISwitch!
    @IBOutlet weak var monitorStack: UIStackView!
    @IBOutlet weak var controlsStack: UIStackView!
    @IBOutlet weak var cabinetArtworkStack: UIStackView!
    @IBOutlet weak var bezelStack: UIStackView!
    @IBOutlet weak var controlPanelOverlayStack: UIStackView!
    
    weak var delegate: EditGameDelegate?
    
    var tabBar : UITabBar!
    let dataController = DataController.shared
    let masterCollection = CollectionManager.shared
    var viewedGame: Game!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setSwitches()
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        getGameAttributeValuesFromSwitches()
        if (viewedGame.hasBoard || viewedGame.hasCabinet || viewedGame.hasMarquee || viewedGame.hasMonitorFlag || viewedGame.hasControls || viewedGame.hasControlPanelOverlay || viewedGame.hasCabinetArt || viewedGame.hasBezel) && !masterCollection.myGames.contains(viewedGame) {
            
            masterCollection.myGames.append(viewedGame)
            masterCollection.myGamesCollection.addToGames(viewedGame)
            
        } else if (!viewedGame.hasBoard && !viewedGame.hasCabinet && !viewedGame.hasMarquee && !viewedGame.hasMonitorFlag && !viewedGame.hasControls && !viewedGame.hasControlPanelOverlay && !viewedGame.hasCabinetArt && !viewedGame.hasBezel), let removalIndex = masterCollection.myGames.firstIndex(of: viewedGame) {
            
            masterCollection.myGames.remove(at: removalIndex)
            masterCollection.myGamesCollection.removeFromGames(viewedGame)
        }
        
        try? dataController.viewContext.save()
        delegate?.didFinishEditingGame()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func boardSwitchTapped(_ sender: UISwitch) {
        if sender.isOn {
            enableBoardTraits(state: true)
        } else {
            enableBoardTraits(state: false)
        }
    }
    
    func enableBoardTraits(state: Bool) {
        authenticity.isEnabled = state
        functionalCondition.isEnabled = state
    }

    func getGameAttributeValuesFromSwitches() {
        viewedGame.hasBoard = hasBoard.isOn
        viewedGame.isBootleg = authenticity.selectedSegmentIndex == 1//isBootleg.isOn
        viewedGame.hasCabinetArt = hasCabinetArt.isOn
        viewedGame.hasControlPanelOverlay = hasControlPanelOverlay.isOn
        viewedGame.hasControls = hasControls.isOn
        viewedGame.hasCabinet = hasCabinet.isOn
        viewedGame.hasBezel = hasBezel.isOn
        viewedGame.hasMonitorFlag = hasMonitorFlag.isOn
        viewedGame.hasMarquee = hasMarquee.isOn
        viewedGame.functionalCondition = Int16(functionalCondition.selectedSegmentIndex)
    }
    
    func setSwitches() { //values set to false / 0 upon json decode
        hasBoard.isOn = viewedGame.hasBoard
        enableBoardTraits(state: hasBoard.isOn)
        if viewedGame.isBootleg {
            authenticity.selectedSegmentIndex = 1
        } else {
            authenticity.selectedSegmentIndex = 0
        }
        hasCabinetArt.isOn = viewedGame.hasCabinetArt
        hasControlPanelOverlay.isOn = viewedGame.hasControlPanelOverlay
        hasControls.isOn = viewedGame.hasControls
        hasCabinet.isOn = viewedGame.hasCabinet
        hasBezel.isOn = viewedGame.hasBezel
        hasMonitorFlag.isOn = viewedGame.hasMonitorFlag
        hasMarquee.isOn = viewedGame.hasMarquee
        functionalCondition.selectedSegmentIndex = Int(viewedGame.functionalCondition)
    }
}
