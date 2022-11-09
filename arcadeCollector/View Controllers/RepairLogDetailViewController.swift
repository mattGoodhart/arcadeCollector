//
//  RepairLogDetailViewController.swift
//  arcadeCollector
//
//  Created by Matt Goodhart on 11/8/22.
//  Copyright © 2022 CatBoiz. All rights reserved.
//

import UIKit

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

class RepairLogDetailViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    
    
    @IBOutlet weak var myBoardPhotoView: UIImageView!
    @IBOutlet weak var controlsPickerView: UIPickerView!
    @IBOutlet weak var audioPickerView: UIPickerView!
    @IBOutlet weak var videoPickerView: UIPickerView!
    @IBOutlet weak var bootPickerView: UIPickerView!
    @IBOutlet weak var extendedPlayPickerView: UIPickerView!

    var dataController = DataController.shared
    var viewedGame: Game!
    var repairLogs: [RepairLog]!
    //var stringArrayForPicker: [String] = []
    var arrayOfExtendedPlayStatuses: [String] = []
    var arrayOfBootStatuses: [String] = []
    var arrayOfAudioStatuses: [String] = []
    var arrayOfControlsStatuses: [String] = []
    var arrayOfVideoStatuses: [String] = []
    
    override func viewDidLoad() {
        setPickerValues()
        
        // buildViewController()
        // init with defaults
        // setPickers, Board photo
        // setLogs / scroll view height
    }
    
    func buildViewController() {
        setMainPhoto()
        setPickerValues()
    }
    
    func setMainPhoto() {
        guard let photoData = viewedGame.myPCBPhoto, let boardPhoto = UIImage(data: photoData) else {
            myBoardPhotoView.image = UIImage(named: "noHardwareDefaultImage")
            return
        }
        myBoardPhotoView.image = boardPhoto
    }
    
    func setPickerValues() {
        
        for audioStatus in AudioStatuses.allCases {
            arrayOfAudioStatuses+=[audioStatus.rawValue]
        }
        
        for videoStatus in VideoStatuses.allCases {
            arrayOfVideoStatuses+=[videoStatus.rawValue]
        }
        
        for controlsStatus in ControlsStatuses.allCases {
            arrayOfControlsStatuses+=[controlsStatus.rawValue]
        }
        
        for bootStatus in BootStatuses.allCases {
            arrayOfBootStatuses+=[bootStatus.rawValue]
        }
        
        for playStatus in ExtendedPlayStatuses.allCases {
            arrayOfExtendedPlayStatuses+=[playStatus.rawValue]
        }
        
//        bootPickerView.selectRow(0, inComponent: 0, animated: false)
//        audioPickerView.selectRow(0, inComponent: 0, animated: false)
//        videoPickerView.selectRow(0, inComponent: 0, animated: false)
//        controlsPickerView.selectRow(0, inComponent: 0, animated: false)
//        extendedPlayPickerView.selectRow(0, inComponent: 0, animated: false)
    }
    

    
    // func newLog()
    
        //need to programatically adjust scroll height and scroll to bottom
    
    // dismissAndSave
        // check for changes and save, no matter how dismissed
    
    //MARK: PickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView{
        case bootPickerView: return arrayOfBootStatuses.count
        case audioPickerView: return arrayOfAudioStatuses.count
        case videoPickerView: return arrayOfVideoStatuses.count
        case controlsPickerView: return arrayOfControlsStatuses.count
        case extendedPlayPickerView: return arrayOfExtendedPlayStatuses.count
        default: return 4
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView{
        case bootPickerView: return arrayOfBootStatuses[row]
        case audioPickerView: return arrayOfAudioStatuses[row]
        case videoPickerView: return arrayOfVideoStatuses[row]
        case controlsPickerView: return arrayOfControlsStatuses[row]
        case extendedPlayPickerView: return arrayOfExtendedPlayStatuses[row]
        default: return "LoL"
        }
    }
}



