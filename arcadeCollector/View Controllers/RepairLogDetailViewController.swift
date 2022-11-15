//
//  RepairLogDetailViewController.swift
//  arcadeCollector
//
//  Created by Matt Goodhart on 11/8/22.
//  Copyright © 2022 CatBoiz. All rights reserved.
//

import UIKit


protocol StatusSelectionDelegate: AnyObject {
    func didSelect(statusType: StatusType, status: Int)
}

class RepairLogDetailViewController: UIViewController, StatusSelectionDelegate {

    
    
    @IBOutlet weak var myBoardPhotoView: UIImageView!
    @IBOutlet weak var bootStatusButton: UIButton!
    @IBOutlet weak var controlsStatusButton: UIButton!
    @IBOutlet weak var audioStatusButton: UIButton!
    @IBOutlet weak var videoStatusButton: UIButton!
    @IBOutlet weak var extendedPlayStatusButton: UIButton!
   
    let masterCollection = CollectionManager.shared
    var dataController = DataController.shared
    var viewedGame: Game!
    var repairLogs: [RepairLogEntry]!
    var hasAnyInfo: Bool = false
   

    
    override func viewDidLoad() {
        checkForAnyInfo()
        
        if hasAnyInfo {
            buildViewControllerWithExistingInfo()
        }
     
    //    createRepairLogCoreDataUponFirstChange()
        // buildViewController()
        // init with defaults
        // setStatus, Board photo
        // setLogs / scroll view height
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // if Game is in GamesInRepairCollection and all statuses are zero and there are no entires, remove Game from collection.
        
        // if Game is not in collection and any of the above changes exist, add to collection
        
        
        try? dataController.viewContext.save()
    }
    
    @IBAction func bootStatusButtonTapped(_ sender: UIButton) {
        presentStatusPickerPopUp(statusType: .bootStatus)
    }
    @IBAction func audioStatusButtonTapped(_ sender: UIButton) {
        presentStatusPickerPopUp(statusType: .audio)
    }
    
    @IBAction func videoStatusButtonTapped(_ sender: UIButton) {
        presentStatusPickerPopUp(statusType: .video)
    }
    
    @IBAction func controlsStatusButtonTapped(_ sender: UIButton) {
        presentStatusPickerPopUp(statusType: .controls)
    }
    
    @IBAction func extendedPlayStatusButtonTapped(_ sender: UIButton) {
        presentStatusPickerPopUp(statusType: .extendedPlay)
    }
    
    func presentStatusPickerPopUp(statusType: StatusType) {
        let statusPickerPopup = storyboard!.instantiateViewController(withIdentifier: "StatusPickerViewController") as! StatusPickerViewController
        statusPickerPopup.statusType = statusType
        statusPickerPopup.delegate = self
        statusPickerPopup.setPickerValues()
        statusPickerPopup.modalTransitionStyle = .crossDissolve
        present(statusPickerPopup, animated: true, completion: nil)
    }
    
    func addGameToGamesInRepairCollection(){
        
        //check if this game is in gamesInRpeiarColleciton
        if let gamesInRepair = masterCollection.fetchGamesForCollection(collection: masterCollection.gamesInRepairCollection), !gamesInRepair.isEmpty {
            
            guard !gamesInRepair.contains(viewedGame) else {
                return
            }
            masterCollection.gamesInRepair.append(viewedGame)
            masterCollection.gamesInRepairCollection.addToGames(viewedGame)
            
            try? dataController.viewContext.save()
        }
    }
    
    func checkForAnyInfo() {
        hasAnyInfo = viewedGame.bootStatus != 0 || viewedGame.audioStatus != 0 || viewedGame.videoStatus != 0 || viewedGame.controlsStatus != 0 || viewedGame.extendedPlayStatus != 0 || !repairLogs.isEmpty
    }
    
    func buildViewControllerWithExistingInfo() {
        let statusButtons: [UIButton] = [bootStatusButton, audioStatusButton, videoStatusButton, controlsStatusButton, extendedPlayStatusButton]
        
        var status: Int16
        var statusType: StatusType
        
        for button in statusButtons {
            switch button {
            case bootStatusButton: status = viewedGame.bootStatus; statusType = .bootStatus
            case audioStatusButton: status = viewedGame.audioStatus; statusType = .audio
            case videoStatusButton: status = viewedGame.videoStatus; statusType = .video
            case controlsStatusButton: status = viewedGame.controlsStatus; statusType = .controls
            case extendedPlayStatusButton: status = viewedGame.extendedPlayStatus; statusType = .extendedPlay
            default:
                return
            }
            
            let statusInt = Int(status)
                updateStatusButtonAppearance(statusType: statusType, status: statusInt)
        }
        guard let pcbPhotoData = viewedGame.myPCBPhoto, let pcbImage = UIImage(data: pcbPhotoData) else {
            return
        }
        myBoardPhotoView.image = pcbImage
    }
    
    
//    func createCollectionsIfNeeded() {
//        if let collections = fetchCollectionsFromCoreData(), !collections.isEmpty {
//            self.collections = collections
//            load(from: collections)
//            fetchGamesForAllCollections()
//        } else {
//            createCollections()
//        }
//    }
//
//    //ddToWantedTapped(_ sender: UIButton) {
//    if  !isWanted {
//        masterCollection.wantedGames.append(viewedGame)
//        masterCollection.wantedGamesCollection.addToGames(viewedGame)
//        isWanted = true
//        DispatchQueue.main.async {
//            self.wantedButton.setImage(UIImage(named: "icons8-favorite-filled"), for: .normal)
//        }
//    } else {
//        let removalIndex = masterCollection.wantedGames.firstIndex(of: viewedGame)
//        masterCollection.wantedGames.remove(at: removalIndex!)
//        masterCollection.wantedGamesCollection.removeFromGames(viewedGame)
//        isWanted = false
//        DispatchQueue.main.async {
//            self.wantedButton.setImage(UIImage(named: "icons8-favorite"), for: .normal)
//        }
    
    func buildViewController() {
        setMainPhoto()

    }
    
    func setMainPhoto() {
        guard let photoData = viewedGame.myPCBPhoto, let boardPhoto = UIImage(data: photoData) else {
            myBoardPhotoView.image = UIImage(named: "noHardwareDefaultImage")
            return
        }
        myBoardPhotoView.image = boardPhoto
    }
    
    func newLog() {
        
        //need to programatically adjust scroll height and push new log to top of the main stackview
        
    }
    
    func RemoveGameFromGamesInRepairCollection() {
        
        
        try? dataController.viewContext.save()
    }
    
    func updateStatusButtonAppearance(statusType: StatusType, status: Int) {
        let buttonToUpdate : UIButton
        
        switch statusType {
        case .bootStatus: buttonToUpdate = bootStatusButton
            viewedGame.bootStatus = Int16(status)
        case .extendedPlay: buttonToUpdate = extendedPlayStatusButton
            viewedGame.extendedPlayStatus = Int16(status)
        case .controls: buttonToUpdate = controlsStatusButton
            viewedGame.controlsStatus = Int16(status)
        case .audio: buttonToUpdate = audioStatusButton
            viewedGame.audioStatus = Int16(status)
        case .video: buttonToUpdate = videoStatusButton
            viewedGame.videoStatus = Int16(status)
        }
        
        DispatchQueue.main.async { //ToDo - update minimum iOS version to 13.0 so I can use UIImage(systemName:) orr add images to asset catalog
            switch status{
            case 0: buttonToUpdate.setImage(UIImage(named: "circle"), for: .normal)
                buttonToUpdate.tintColor = .systemBlue
            case 1: buttonToUpdate.setImage(UIImage(named: "circle.fill"), for: .normal)
                buttonToUpdate.tintColor = .red
            case 2: buttonToUpdate.setImage(UIImage(named: "circle.fill"), for: .normal)
                buttonToUpdate.tintColor = .yellow
            case 3: buttonToUpdate.setImage(UIImage(named: "circle.fill"), for: .normal)
                buttonToUpdate.tintColor = .green
            default:
                return
            }
        }
        try? dataController.viewContext.save()
    }
        
    //MARK: PickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //MARK: StatusSelectionDelegate
    func didSelect(statusType: StatusType, status: Int) {
        updateStatusButtonAppearance(statusType: statusType, status: status)
        try? dataController.viewContext.save()
       // save
    }
}




