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

class RepairLogDetailViewController: UIViewController, StatusSelectionDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var myBoardPhotoView: UIImageView!
    @IBOutlet weak var bootStatusButton: UIButton!
    @IBOutlet weak var controlsStatusButton: UIButton!
    @IBOutlet weak var audioStatusButton: UIButton!
    @IBOutlet weak var videoStatusButton: UIButton!
    @IBOutlet weak var extendedPlayStatusButton: UIButton!
    
    let masterCollection = CollectionManager.shared
    var dataController = DataController.shared
    var viewedGame: Game!
    var repairLogEntries: [RepairLogEntry]!
    var hasAnyInfo: Bool = false
    
    override func viewDidLoad() {
        initializeStatusButtons()
        setRepairLogEntriesForViewedGame()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        
        checkForAnyInfo()
        if !hasAnyInfo {
            removeGameFromGamesInRepairCollection()
        } else {
            addGameToGamesInRepairCollection()
        }
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
    
    @IBAction func newRepairLogEntryTapped() {
        newLog()
    }
    
    @IBAction func cameraButtonTapped(_ sender: UIButton) {
        let viewController = UIImagePickerController()
        viewController.sourceType = .camera
        viewController.allowsEditing = true
        viewController.delegate = self
        present(viewController, animated: true)
    }
    
    func initializeStatusButtons() {
        let resizedImage = UIImage(named: "whiteLED")?.resizeImage(newSize: CGSize(width: 33, height: 33))
        bootStatusButton.imageView?.image = resizedImage
        audioStatusButton.imageView?.image = resizedImage
        videoStatusButton.imageView?.image = resizedImage
        controlsStatusButton.imageView?.image = resizedImage
        extendedPlayStatusButton.imageView?.image = resizedImage
    }
    
    func presentStatusPickerPopUp(statusType: StatusType) {
        let statusPickerPopup = storyboard!.instantiateViewController(withIdentifier: "StatusPickerViewController") as! StatusPickerViewController
        statusPickerPopup.statusType = statusType
        statusPickerPopup.delegate = self
        statusPickerPopup.setPickerValues()
        statusPickerPopup.modalTransitionStyle = .crossDissolve
        present(statusPickerPopup, animated: true, completion: nil)
    }
    
    func isViewedGameInRepairCollection() -> Bool {
        let gamesInRepair = masterCollection.gamesInRepair
        guard !gamesInRepair.isEmpty, gamesInRepair.contains(viewedGame) else {
            return false
        }
        return true
    }
    
    func addGameToGamesInRepairCollection(){
        guard !isViewedGameInRepairCollection() else {
            return
        }
        masterCollection.gamesInRepair.append(viewedGame)
        masterCollection.gamesInRepairCollection.addToGames(viewedGame)
        try? dataController.viewContext.save()
    }
    
    func removeGameFromGamesInRepairCollection() {
        guard isViewedGameInRepairCollection() else {
            return
        }
        let removalIndex = masterCollection.gamesInRepair.firstIndex(of: viewedGame)
        masterCollection.gamesInRepair.remove(at: removalIndex!) //OK to bang here?
        try? dataController.viewContext.save()
    }
    
    func checkForAnyInfo() {
        
        hasAnyInfo = viewedGame.bootStatus != 0 || viewedGame.audioStatus != 0 || viewedGame.videoStatus != 0 || viewedGame.controlsStatus != 0 || viewedGame.extendedPlayStatus != 0 || !repairLogEntries.isEmpty
    }
    
    func setRepairLogEntriesForViewedGame() {
        repairLogEntries = masterCollection.fetchRepairLogEntriesForGame(game: viewedGame)
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
    
    func newLog() {
        
        
        // set today's date at top in Bold, and set game.lastRepairDate 
        
        
        //need to programatically adjust scroll height and push new log to top of the main stackview
        
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
            case 0:
                let resizedImage = UIImage(named: "whiteLED")?.resizeImage(newSize: CGSize(width: 33, height: 33))
                buttonToUpdate.setImage(resizedImage, for: .normal)
            case 1:
                let resizedImage = UIImage(named: "redLED")?.resizeImage(newSize: CGSize(width: 33, height: 33))
                buttonToUpdate.setImage(resizedImage, for: .normal)
            case 2: let resizedImage = UIImage(named: "yellowLED")?.resizeImage(newSize: CGSize(width: 33, height: 33))
                buttonToUpdate.setImage(resizedImage, for: .normal)
            case 3: let resizedImage = UIImage(named: "greenLED")?.resizeImage(newSize: CGSize(width: 33, height: 33))
                buttonToUpdate.setImage(resizedImage, for: .normal)
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
    }
    
    //MARK: ImagePickerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        myBoardPhotoView.image = image
        let imageData = image.pngData()
        viewedGame.myPCBPhoto = imageData
        try? dataController.viewContext.save()
    }
    
    
}
