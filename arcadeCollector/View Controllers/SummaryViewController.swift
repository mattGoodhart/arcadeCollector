//
//  SummaryViewController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/4/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit
import CoreData
import Charts

class SummaryViewController: UIViewController {

    @IBOutlet weak var wantedGamesLabel: UILabel!
    @IBOutlet weak var aboutButton: UIButton!
    @IBOutlet weak var boardsPieChart: PieChartView!
    @IBOutlet weak var allHardwarePieChart: PieChartView!
    
    
    let masterCollection = CollectionManager.shared
    let dataController = DataController.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Summary"
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)

        setWantedGamesCount()
        buildDataForCharts()
    }
    

    func buildDataForCharts() {
        buildBoardChart()
        buildAllHardwareChart()
    }
    
    func buildBoardChart() {
        masterCollection.getBoardsByWorkingCondition()
        
        guard masterCollection.numberOfBoardsInCollection != 0  else {
            boardsPieChart.isHidden = true
            return
        }
        
        let boardConditionArray = ["Working", "Booting", "Not Working"]
        let boardConditionCounts = [Double(masterCollection.numberOfWorkingBoards), Double(masterCollection.numberOfBootingBoards), Double(masterCollection.numberOfNonWorkingBoards)]
        
        let boardConditionDictionary: [String : Double] = Dictionary(uniqueKeysWithValues: zip(boardConditionArray, boardConditionCounts))
    
        var boardDataEntries: [ChartDataEntry] = []
        
            for entry in boardConditionDictionary {
                let boardDataEntry = PieChartDataEntry(value: entry.value, label: entry.key, data: entry.key)
                boardDataEntries.append(boardDataEntry)
            } // this is where the data array seems to get out of order (so colors not assigning correctly)
        
        let boardPieChartDataSet = PieChartDataSet(boardDataEntries)
        boardPieChartDataSet.colors = [UIColor.green, UIColor.yellow, UIColor.red]
        
        let boardPieChartData = PieChartData(dataSet: boardPieChartDataSet)
        
        let format = NumberFormatter()
        format.numberStyle = .none
        let formatter = DefaultValueFormatter(formatter: format)
        boardPieChartData.setValueFormatter(formatter)
        
        boardsPieChart.data = boardPieChartData
        
    }
    
    func buildAllHardwareChart() {
       
        masterCollection.getCabinetHardware()
        
        var allHardwareDataEntries: [ChartDataEntry] = []
        
        for entry in masterCollection.hardwareCountsDictionary {
            let hardwareDataEntry = PieChartDataEntry(value: entry.value, label: entry.key, data: entry.key)
            allHardwareDataEntries.append(hardwareDataEntry)
        }
        
        let allHardwareChartDataSet = PieChartDataSet(allHardwareDataEntries)
        let allHardwareChartData = PieChartData(dataSet: allHardwareChartDataSet)
        
        allHardwareChartDataSet.colors = [UIColor.green, UIColor.yellow, UIColor.red]
        
        let format = NumberFormatter()
        format.numberStyle = .none
        let formatter = DefaultValueFormatter(formatter: format)
        allHardwareChartData.setValueFormatter(formatter)
        
        allHardwarePieChart.data = allHardwareChartData
        
//code to hie this pie chart if no hardware
    }
    
    func setWantedGamesCount() {
        if masterCollection.wantedGames.count != 1 {
            self.wantedGamesLabel.text = "\(masterCollection.wantedGames.count) Wanted Games"
        } else {
            self.wantedGamesLabel.text = "\(masterCollection.wantedGames.count) Wanted Game"
        }
    }
    
//
//    func setGameCollectionCounts() {
//        self.allGamesLabel.text = "\(masterCollection.allGames.count) Unique Games in Reference"
//
////        if masterCollection.allHardwareInCollection.count != 1 { self.myCollectionLabel.text = "\(masterCollection.allHardwareInCollection.count) Pieces of Hardware in Collection" }
////        else { self.myCollectionLabel.text = "\(masterCollection.allHardwareInCollection.count) Piece of Hardware in Collection" }
//
//        if masterCollection.wantedGames.count != 1 {
//            self.wantedGamesLabel.text = "\(masterCollection.wantedGames.count) Wanted Games"
//        } else {
//            self.wantedGamesLabel.text = "\(masterCollection.wantedGames.count) Wanted Game"
//        }
//    }
    
//    func setBoardFunctionalityCounts() {
//        masterCollection.getBoardsByWorkingCondition()
//
//        if masterCollection.workingBoards.count != 1 {
//            self.workingBoardsLabel.text = String(masterCollection.workingBoards.count) + " Fully Working Boards"
//        } else {
//            self.workingBoardsLabel.text = String(masterCollection.workingBoards.count) + " Fully Working Board"
//        }
//
//        if masterCollection.partiallyWorkingBoards.count != 1 {
//            self.partiallyWorkingBoardsLabel.text = String(masterCollection.partiallyWorkingBoards.count) + " Partially Working Boards"
//        } else {
//            self.partiallyWorkingBoardsLabel.text = String(masterCollection.partiallyWorkingBoards.count) + " Partially Working Board"
//        }
//
//        if masterCollection.nonWorkingBoards.count != 1{
//            self.nonWorkingBoardsLabel.text = String(masterCollection.nonWorkingBoards.count) + " Non-Working Boards"
//        } else {
//            self.nonWorkingBoardsLabel.text = String(masterCollection.nonWorkingBoards.count) + " Non-Working Board"
//        }
//
//        if masterCollection.boardsInCollection.count != 1 {
//            self.boardsStatus.text = String(masterCollection.boardsInCollection.count) + " Boards in Collection"
//        } else {
//            self.boardsStatus.text = String(masterCollection.boardsInCollection.count) + " Board in Collection"
//        }
//    }

    @IBAction func aboutButtonPressed(_sender: UIButton) {
        performSegue(withIdentifier: "AboutSegue", sender: _sender)
    }
}
