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

    @IBOutlet weak var chartsStackView: UIStackView!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var boardsPieChart: PieChartView!
    @IBOutlet weak var allHardwarePieChart: PieChartView!
    
    let masterCollection = CollectionManager.shared
    let dataController = DataController.shared
    var workingBoardsCount = 0
    var partiallyWorkingBoardsCount = 0
    var nonWorkingBoardsCount = 0
    
    let chartGreen = UIColor(displayP3Red: 0, green: (104/255), blue: (56/255), alpha: 1)
    let chartYellow = UIColor(displayP3Red: (202/255), green: (179/255), blue: (74/255), alpha: 1)
    let chartBlue = UIColor(displayP3Red: (183/255), green: (237/255), blue: (224/255), alpha: 1)
    let chartLightGreen = UIColor(displayP3Red: (42/255), green: (134/255), blue: (74/255), alpha: 1)
    let chartLightYellow = UIColor(displayP3Red: 1, green: (223/255), blue: (93/255), alpha: 1)
    let chartOrange = UIColor(displayP3Red: (248/255), green: (155/255), blue: (101/255), alpha: 1)
    let chartSeaFoam = UIColor(displayP3Red: (100/255), green: (177/255), blue: (148/255), alpha: 1)
    let chartPink = UIColor(displayP3Red: (245/255), green: (151/255), blue: (180/255), alpha: 1)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Summary"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        masterCollection.getBoardsByWorkingCondition()
        masterCollection.getCabinetHardware()
        setWantedGamesCount()
        buildDataForCharts()
    }
    
        
    func buildDataForCharts() {
        buildBoardChart()
        buildAllHardwareChart()
        boardsPieChart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        allHardwarePieChart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
    }
    
    func buildBoardChart() {
    //    masterCollection.getBoardsByWorkingCondition()
        boardsPieChart.isHidden = false
        var boardDataEntries: [ChartDataEntry] = []
     //   let boardPieChartDataSet = PieChartDataSet()
        var boardPieChartData = PieChartData()
        
        guard masterCollection.boardsInCollection.count != 0 else {
            
            boardsPieChart.noDataText = "No Boards in Collection Yet!"
           // boardsPieChart.isHidden = true
            return
        }
        
       
        
        let boardConditionArray = ["Working", "Booting", "Not Working"]
        let boardConditionCounts = [Double(masterCollection.workingBoards.count), Double(masterCollection.partiallyWorkingBoards.count), Double(masterCollection.nonWorkingBoards.count)]
        
        let boardConditionDictionary: [String : Double] = Dictionary(uniqueKeysWithValues: zip(boardConditionArray, boardConditionCounts))
    
       // var boardDataEntries: [ChartDataEntry] = []
        
        for entry in boardConditionDictionary {
            
            if entry.value != 0 {
                let boardDataEntry = PieChartDataEntry(value: entry.value, label: entry.key, data: entry.key)
                boardDataEntries.append(boardDataEntry)
            }
        } // this is where the data array seems to get out of order (so colors not assigning correctly)
        
        let boardPieChartDataSet = PieChartDataSet(boardDataEntries)
        boardPieChartDataSet.colors = [chartGreen, chartLightYellow, UIColor.red]
        
//        boardPieChartDataSet.valueLinePart1OffsetPercentage = 0.5
//        boardPieChartDataSet.valueLinePart1Length = 0.2
//        boardPieChartDataSet.valueLinePart2Length = 0.4
//        boardPieChartDataSet.yValuePosition = .outsideSlice
        
        boardPieChartData = PieChartData(dataSet: boardPieChartDataSet)
        
        let format = NumberFormatter()
        format.numberStyle = .none
        let formatter = DefaultValueFormatter(formatter: format)
        boardPieChartData.setValueFormatter(formatter)
        
        boardsPieChart.data = boardPieChartData
       // boardsPieChart.data?.setValueTextColor(.black)
        
        boardsPieChart.centerText = "Boards"
        boardsPieChart.legend.enabled = false
        
        
        attachImageToCenterOfPieChart(imageName: "noHardwareDefaultImage", pieChart: boardsPieChart)
        
        
        
    }
    
    func attachImageToCenterOfPieChart(imageName: String, pieChart: PieChartView) {
        
        //this is hacky --
        let attachment = NSTextAttachment()
        let boardImage = UIImage(named: imageName)! // can this be not bung
        let centerSize = CGSize(width: (UIScreen.main.bounds.width/6.5), height: (UIScreen.main.bounds.height/10))
        
        
        
        let centeredBoardImage = boardImage.resizeImage(image: boardImage, newSize: centerSize)
        attachment.image = centeredBoardImage

        let attachmentString = NSAttributedString(attachment: attachment)
        let labelImg = NSMutableAttributedString(string: "")
        labelImg.append(attachmentString)
        pieChart.centerAttributedText = labelImg
    }
    
    func buildAllHardwareChart() {
        
        var hardwareCountsTotal: Double = 0.0
        var allHardwareDataEntries: [ChartDataEntry] = []
        
        for entry in masterCollection.hardwareCountsDictionary {
            if entry.value != 0.0 {
                
                let hardwareDataEntry = PieChartDataEntry(value: entry.value, label: entry.key, data: entry.key)
                allHardwareDataEntries.append(hardwareDataEntry)
                hardwareCountsTotal += entry.value
            }
        }
        allHardwarePieChart.isHidden = false
        
        guard hardwareCountsTotal != 0.0 else {
            allHardwarePieChart.noDataText = "No Hardware in Collection Yet!"
          //  allHardwarePieChart.isHidden = true
            return
        }
    
        let allHardwareChartDataSet = PieChartDataSet(allHardwareDataEntries)
        let allHardwareChartData = PieChartData(dataSet: allHardwareChartDataSet)
        
        allHardwareChartDataSet.colors = [chartGreen, chartLightGreen, chartSeaFoam, chartBlue, chartLightYellow, chartYellow, chartOrange, chartPink]
        
        let format = NumberFormatter()
        format.numberStyle = .none
        let formatter = DefaultValueFormatter(formatter: format)
        allHardwareChartData.setValueFormatter(formatter)

        allHardwarePieChart.data = allHardwareChartData
        allHardwarePieChart.legend.enabled = false
        allHardwarePieChart.centerText = "Hardware"
        
        attachImageToCenterOfPieChart(imageName: "Cab", pieChart: allHardwarePieChart)
      
    }
    
    func setWantedGamesCount() {
        if masterCollection.wantedGames.count != 1 {
            self.wantedGamesLabel.text = "\(masterCollection.wantedGames.count) Wanted Games"
        } else {
            self.wantedGamesLabel.text = "\(masterCollection.wantedGames.count) Wanted Game"
        }
    }
    
    // make this a UIImage extension
//    func resizeImage(image: UIImage, newSize: CGSize) -> UIImage {
//
//        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
//        image.draw(in: CGRect(x: 0.0, y: 0.0, width: newSize.width, height: newSize.height))
//        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
//        UIGraphicsEndImageContext()
//        return newImage
//    }
    

    @IBAction func aboutButtonPressed(_sender: UIButton) {
        performSegue(withIdentifier: "AboutSegue", sender: _sender)
    }
}
