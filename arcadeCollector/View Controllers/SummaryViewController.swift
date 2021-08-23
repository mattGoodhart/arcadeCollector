//
//  SummaryViewController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/4/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit
import CoreData

class SummaryViewController: UIViewController {
    
    @IBOutlet weak var allGamesLabel: UILabel!
    @IBOutlet weak var myCollectionLabel: UILabel!
    @IBOutlet weak var wantedGamesLabel: UILabel!
    @IBOutlet weak var aboutButton: UIButton!
    @IBOutlet weak var workingBoardsLabel: UILabel!
    @IBOutlet weak var partiallyWorkingBoardsLabel: UILabel!
    @IBOutlet weak var nonWorkingBoardsLabel: UILabel!
    @IBOutlet weak var boardsStatus: UILabel!
    
    let masterCollection = CollectionManager.shared
    let dataController = DataController.shared
    var workingBoardsCount = 0
    var partiallyWorkingBoardsCount = 0
    var nonWorkingBoardsCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Summary"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        (UIApplication.shared.delegate as? AppDelegate)?.allowedOrientations = .portrait
        setBoardFunctionalityCounts()
        masterCollection.getCabinetHardware()
        masterCollection.getAllHardwareCount()
        setGameCollectionCounts()
    }
    
    func setGameCollectionCounts() {
        self.allGamesLabel.text = "\(masterCollection.allGames.count) Unique Games in Reference"
        self.myCollectionLabel.text = "\(masterCollection.allHardwareInCollection.count) Pieces of Hardware in Collection"
        self.wantedGamesLabel.text = "\(masterCollection.wantedGames.count) Wanted Games"
    }
    
    func setBoardFunctionalityCounts() {
        masterCollection.getBoardsByWorkingCondition()
        
        self.workingBoardsLabel.text = String(masterCollection.workingBoards.count) + " Working Boards"
        self.partiallyWorkingBoardsLabel.text = String(masterCollection.partiallyWorkingBoards.count) + "  Boards that Boot But Don't Fully Work"
        self.nonWorkingBoardsLabel.text = String(masterCollection.nonWorkingBoards.count) + " Non-Working Boards"
        
        self.boardsStatus.text = String(masterCollection.boardsInCollection.count) + " Boards in Collection"
    }

    @IBAction func aboutButtonPressed(_sender: UIButton) {
        performSegue(withIdentifier: "AboutSegue", sender: _sender)
    }
}
