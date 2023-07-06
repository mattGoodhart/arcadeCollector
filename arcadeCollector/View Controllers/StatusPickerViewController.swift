//
//  StatusPickerViewController.swift
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

class StatusPickerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
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
    
    override func viewDidDisappear(_ animated: Bool) {
        if isBeingDismissed{
            delegate?.didSelect(statusType: statusType, status: pickerView.selectedRow(inComponent: 0))
        }
    }
    
    @IBAction func dismissButtonTapped(_sender: UIButton) {
        dismiss(animated: true)
    }
    
    
    func setPickerValues() {
        var stringArray: [String] = []
        
        switch statusType {
        case .audio:
            for status in AudioStatuses.allCases {
                stringArray+=[status.rawValue]
            }
        case.video:
            for status in VideoStatuses.allCases {
                stringArray+=[status.rawValue]
            }
        case.bootStatus:
            for status in BootStatuses.allCases {
                stringArray+=[status.rawValue]
            }
        case .controls:
            for status in ControlsStatuses.allCases {
                stringArray+=[status.rawValue]
            }
        case .extendedPlay:
            for status in ExtendedPlayStatuses.allCases {
                stringArray+=[status.rawValue]
            }
        case .none:
            return
        }
        arrayOfStringsForPicker = stringArray
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
    
