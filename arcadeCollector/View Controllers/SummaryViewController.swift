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
    
    let masterCollection = CollectionManager.shared
    let dataController = DataController.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Summary"
      
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(false)
          getGameCollectionCounts()
    }
    
    func getGameCollectionCounts() {
        self.allGamesLabel.text = "\(masterCollection.allGames.count) Unique Games in Reference"
        self.myCollectionLabel.text = "\(masterCollection.myGames.count) Games in Collection"
        self.wantedGamesLabel.text = "\(masterCollection.wantedGames.count) Wanted Games"
    }
    
    @IBAction func aboutButtonPressed(_sender: UIButton) {
        performSegue(withIdentifier: "AboutSegue", sender: _sender)
    }
}
