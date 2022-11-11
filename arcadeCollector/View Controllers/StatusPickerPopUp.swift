//
//  StatusPickerPopUp.swift
//  arcadeCollector
//
//  Created by Matt Goodhart on 11/9/22.
//  Copyright © 2022 CatBoiz. All rights reserved.
//

import UIKit

enum StatusType {
    case audio
    case video
    case controls
    case bootStatus
    case extendedPlay
}

class StatusPickerPopup: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var dismissButton: UIButton!
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    weak var delegate: StatusSelectionDelegate?
    
    var statusType: StatusType!
    var arrayOfStringsForPicker: [String] = []
    var chosenStatus: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.dataSource = self
        setPickerValues()
    }
    
    @IBAction func dismissButtonTapped(_sender: UIButton) {
        //chosenStatus = pickerView.selectedRow(inComponent: 0)
        delegate?.didSelect(statusType: statusType, status: pickerView.selectedRow(inComponent: 0))
        dismiss(animated: true)
        
        
//        getGameAttributeValuesFromSwitches()
//        if (viewedGame.hasBoard && !masterCollection.myGames.contains(viewedGame)) {
//
//            masterCollection.myGames.append(viewedGame)
//            masterCollection.myGamesCollection.addToGames(viewedGame)
//
//        } else if !viewedGame.hasBoard, let removalIndex = masterCollection.myGames.firstIndex(of: viewedGame) {
//
//            masterCollection.myGames.remove(at: removalIndex)
//            masterCollection.myGamesCollection.removeFromGames(viewedGame)
//        }
//
//        try? dataController.viewContext.save()
//        delegate?.didFinishEditingGame()
//        dismiss(animated: true, completion: nil)
    }


    
    
    func setPickerValues() {
        switch statusType {
        case .audio:
            for status in AudioStatuses.allCases {
                arrayOfStringsForPicker+=[status.rawValue]
            }
        case.video:
            for status in VideoStatuses.allCases {
                arrayOfStringsForPicker+=[status.rawValue]
            }
        case.bootStatus:
            for status in BootStatuses.allCases {
                arrayOfStringsForPicker+=[status.rawValue]
            }
        case .controls:
            for status in ControlsStatuses.allCases {
                arrayOfStringsForPicker+=[status.rawValue]
            }
        case .extendedPlay:
            for status in ExtendedPlayStatuses.allCases {
                arrayOfStringsForPicker+=[status.rawValue]
            }
        case .none:
            return
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return arrayOfStringsForPicker.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return arrayOfStringsForPicker[row]
    }
}



enum AudioStatuses: String, CaseIterable {
    case untested = "Untested"
    case noAudio = "No Audio"
    case someAudio = "Some Audio"
    case working = "Working"
}

enum VideoStatuses: String, CaseIterable {
    case untested = "Untested"
    case noVideo = "No Video"
    case someVideo = "Some Video"
    case working = "Working"
}

enum ControlsStatuses : String, CaseIterable {
    case untested = "Untested"
    case noControls = "No Controls"
    case someControl = "Some Controls"
    case working = "Working"
}

enum BootStatuses : String, CaseIterable {
    case untested = "Untested"
    case nonBooting = "Non-Booting"
    case watchdog = "Boot Error / Watchdog"
    case working = "Booting"
}

enum ExtendedPlayStatuses : String, CaseIterable {
    case untested = "Untested"
    case crashing = "Crashing"
    case playthrough = "Playthrough Tested"
    case extended = "Extended Test - 8Hrs+"
}
    

