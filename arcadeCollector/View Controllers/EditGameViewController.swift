//
//  EditGamePopOver.swift
//  arcadeCollector
//
//  Created by Matt Goodhart on 4/11/21.
//  Copyright © 2021 CatBoiz. All rights reserved.

import UIKit

class EditGameViewController: UIViewController {

    @IBOutlet weak var hasBoard: UISwitch!
    @IBOutlet weak var authenticity: UISegmentedControl!
    @IBOutlet weak var functionalCondition: UISegmentedControl!

    weak var delegate: EditGameDelegate?

    var tabBar: UITabBar!
    let dataController = DataController.shared
    let masterCollection = CollectionManager.shared
    var viewedGame: Game!

    override func viewDidLoad() {
        super.viewDidLoad()
        setSwitches()
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        getGameAttributeValuesFromSwitches()
        if (viewedGame.hasBoard && !masterCollection.myGames.contains(viewedGame)) {
            
            masterCollection.myGames.append(viewedGame)
            masterCollection.myGamesCollection.addToGames(viewedGame)
            
        } else if !viewedGame.hasBoard, let removalIndex = masterCollection.myGames.firstIndex(of: viewedGame) {
            
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
        viewedGame.isBootleg = authenticity.selectedSegmentIndex == 1
        viewedGame.functionalCondition = Int16(functionalCondition.selectedSegmentIndex)
    }

    func setSwitches() { // values set to false / 0 upon json decode
        hasBoard.isOn = viewedGame.hasBoard
        enableBoardTraits(state: hasBoard.isOn)
        if viewedGame.isBootleg {
            authenticity.selectedSegmentIndex = 1
        } else {
            authenticity.selectedSegmentIndex = 0
        }
        functionalCondition.selectedSegmentIndex = Int(viewedGame.functionalCondition)
    }
}
