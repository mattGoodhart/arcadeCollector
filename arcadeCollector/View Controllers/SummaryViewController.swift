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
    var workingBoardsCount = 0
    var partiallyWorkingBoardsCount = 0
    var nonWorkingBoardsCount = 0

    // Move to asset catalog and play with night mode / naming based on use case and not value
    let chartGreen = UIColor(displayP3Red: 0, green: (104/255), blue: (56/255), alpha: 1)
    let chartYellow = UIColor(displayP3Red: (202/255), green: (179/255), blue: (74/255), alpha: 1)
    let chartBlue = UIColor(displayP3Red: (183/255), green: (237/255), blue: (224/255), alpha: 1)
    let chartLightGreen = UIColor(displayP3Red: (42/255), green: (134/255), blue: (74/255), alpha: 1)
    let chartLightYellow = UIColor(displayP3Red: 1, green: (223/255), blue: (93/255), alpha: 1)
    let chartOrange = UIColor(displayP3Red: (248/255), green: (155/255), blue: (101/255), alpha: 1)
    let chartSeaFoam = UIColor(displayP3Red: (100/255), green: (177/255), blue: (148/255), alpha: 1)
    let chartPink = UIColor(displayP3Red: (245/255), green: (151/255), blue: (180/255), alpha: 1)
    let chartLightOrange = UIColor(displayP3Red: (231/255), green: 148/255, blue: 33/255, alpha: 1)

    required init?(coder: NSCoder) { // why is this better than self.title = ... ?
        super.init(coder: coder)

        title = "Summary"

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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
        boardsPieChart.isHidden = false
        var boardDataEntries: [ChartDataEntry] = []
        var boardPieChartData = PieChartData()
        var boardConditionsInCollection: [String] = []
        var colorsForBoards: [UIColor] = []

        // isEmpty
        guard !masterCollection.boardsInCollection.isEmpty else {

            boardsPieChart.noDataText = "No Boards in Collection Yet!"
            boardsPieChart.noDataFont = .italicSystemFont(ofSize: 18)
            boardsPieChart.noDataTextColor = .white
            return
        }

//        struct Thing {
//            let name: String
//            let count: Int
//        let color:
//        }
//
//        [Thing]

        // i would make structs for these
        let boardConditionArray = ["Working", "Booting", "Not Working"]
        let boardConditionCounts = [Double(masterCollection.workingBoards.count), Double(masterCollection.partiallyWorkingBoards.count), Double(masterCollection.nonWorkingBoards.count)]

        let boardConditionDictionary: [String: Double] = Dictionary(uniqueKeysWithValues: zip(boardConditionArray, boardConditionCounts))

        for entry in boardConditionDictionary {

            if entry.value != 0 {
                let boardDataEntry = PieChartDataEntry(value: entry.value, label: entry.key, data: entry.key)
                boardDataEntries.append(boardDataEntry)
                boardConditionsInCollection.append(entry.key)
            }
        }

        for condition in boardConditionsInCollection {
            switch condition {
            case "Working" : colorsForBoards.append(chartGreen)
            case "Not Working": colorsForBoards.append(UIColor.red)
            case "Booting": colorsForBoards.append(chartLightOrange)
            default: return
            }
        }

        let boardPieChartDataSet = PieChartDataSet(boardDataEntries)

        boardPieChartDataSet.colors = colorsForBoards
        boardPieChartDataSet.entryLabelColor = .white
        boardPieChartDataSet.entryLabelFont = .italicSystemFont(ofSize: 14)
        boardPieChartDataSet.valueLineColor = .white
        boardPieChartDataSet.valueLinePart1OffsetPercentage = 0.5
        boardPieChartDataSet.valueLinePart1Length = 0.3
        boardPieChartDataSet.valueLinePart2Length = 0.5
        boardPieChartDataSet.xValuePosition = .outsideSlice
        boardPieChartDataSet.yValuePosition = .outsideSlice

        boardPieChartData = PieChartData(dataSet: boardPieChartDataSet)

        let format = NumberFormatter()
        format.numberStyle = .none

        let formatter = DefaultValueFormatter(formatter: format)
        boardPieChartData.setValueFormatter(formatter)

        boardPieChartData.setValueTextColor(.white)

        boardsPieChart.data = boardPieChartData
        boardsPieChart.centerText = "Boards"
        boardsPieChart.legend.enabled = false

        attachImageToCenterOfPieChart(imageName: "noHardwareDefaultImage", pieChart: boardsPieChart)
    }

    func attachImageToCenterOfPieChart(imageName: String, pieChart: PieChartView) {

        // this seems hacky --
        let attachment = NSTextAttachment()
        let boardImage = UIImage(named: imageName) ?? UIImage()
        let centerSize = CGSize(width: (UIScreen.main.bounds.width/6.5), height: (UIScreen.main.bounds.height/10))

        let centeredBoardImage = boardImage.resizeImage(image: boardImage, newSize: centerSize)
        attachment.image = centeredBoardImage

        let attachmentString = NSAttributedString(attachment: attachment)
        let labelImg = NSMutableAttributedString(string: "")
        labelImg.append(attachmentString)
        pieChart.centerAttributedText = labelImg
    }

    func buildAllHardwareChart() { // review this closer.. compare to older versions

        let (hardwareCountsTotal, allHardwareDataEntries) = masterCollection
            .hardwareCountsDictionary
            .reduce((Double(0), [PieChartDataEntry]())) { partialResult, entry in
                guard entry.value != 0.0 else {
                    return partialResult
                }

                let (count, entires) = partialResult

                let entry = PieChartDataEntry(value: entry.value,
                                              label: entry.key,
                                              data: entry.key)

                return (count + entry.value, entires + [entry])
            }

        allHardwarePieChart.isHidden = false

        guard hardwareCountsTotal != 0.0 else {
            allHardwarePieChart.noDataText = "No Hardware in Collection Yet!"
            allHardwarePieChart.noDataFont = .italicSystemFont(ofSize: 18)
            allHardwarePieChart.noDataTextColor = .white
            return
        }

        let allHardwareChartDataSet = PieChartDataSet(allHardwareDataEntries)
        let allHardwareChartData = PieChartData(dataSet: allHardwareChartDataSet)

        allHardwareChartDataSet.colors = [chartGreen, chartLightGreen, chartSeaFoam, chartBlue, chartLightYellow, chartYellow, chartOrange, chartPink]
        allHardwareChartDataSet.entryLabelColor = .white
        allHardwareChartDataSet.entryLabelFont = .italicSystemFont(ofSize: 14)
        allHardwareChartDataSet.valueLineColor = .white
        allHardwareChartDataSet.valueLinePart1OffsetPercentage = 0.5
        allHardwareChartDataSet.valueLinePart1Length = 0.3
        allHardwareChartDataSet.valueLinePart2Length = 0.5
        allHardwareChartDataSet.xValuePosition = .outsideSlice
        allHardwareChartDataSet.yValuePosition = .outsideSlice

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

    @IBAction func aboutButtonPressed(_sender: UIButton) {
        performSegue(withIdentifier: "AboutSegue", sender: _sender)
    }
}
