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
    
    var dataController = DataController.shared
    var viewedGame: Game!
    var repairLogs: [RepairLog]!

    
    override func viewDidLoad() {
     
        
        // buildViewController()
        // init with defaults
        // setStatus, Board photo
        // setLogs / scroll view height
    }
    
    @IBAction func bootStatusButtonTapped(_ sender: UIButton) {
        let statusPickerPopup = storyboard!.instantiateViewController(withIdentifier: "StatusPickerPopup") as! StatusPickerPopup
        statusPickerPopup.statusType = .bootStatus
        statusPickerPopup.delegate = self
        statusPickerPopup.setPickerValues()
        statusPickerPopup.modalTransitionStyle = .crossDissolve
        present(statusPickerPopup, animated: true, completion: nil)
        
//        let popOverVC = storyboard!.instantiateViewController(withIdentifier: "EditGameViewController") as! EditGameViewController
//        popOverVC.viewedGame = viewedGame
//        popOverVC.delegate = self
//        popOverVC.modalTransitionStyle = .flipHorizontal
//        present(popOverVC, animated: true, completion: nil)
        
        
        
        
//        if let popOver = popUpViewController {
//            handleButtons(enabled: false, button: filterButton)
//            present(popOver, animated: true, completion: nil)
//        } else {
//            popUpViewController = storyboard!.instantiateViewController(withIdentifier: "FilterOptionsPopup") as? FilterOptionsPopup
//            popUpViewController.delegate = self
//            popUpViewController.gamesList = gamesList
//            popUpViewController.modalPresentationStyle = .overCurrentContext
//            popUpViewController.modalTransitionStyle = .crossDissolve
//
//            handleButtons(enabled: false, button: filterButton)
//
//            present(popUpViewController, animated: true, completion: nil)
    }
    
    @IBAction func audioStatusButtonTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func videoStatusButtonTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func controlsStatusButtonTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func extendedPlayStatusButtonTapped(_ sender: UIButton) {
        
    }
    
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
    
    func updateStatusButtonAppearance(statusType: StatusType, status: Int) {
        let buttonToUpdate : UIButton
        
        switch statusType {
        case .bootStatus: buttonToUpdate = bootStatusButton
        case .extendedPlay: buttonToUpdate = extendedPlayStatusButton
        case .controls: buttonToUpdate = controlsStatusButton
        case .audio: buttonToUpdate = audioStatusButton
        case .video: buttonToUpdate = videoStatusButton
        }
        
        DispatchQueue.main.async {
            switch status{
            case 0: buttonToUpdate.setImage(UIImage(named: "circle"), for: .normal)
                buttonToUpdate.tintColor = .systemBlue
//            case 1: buttonToUpdate.setImage(UIImage(systemName: "circle.fill"), for: .normal)
//                buttonToUpdate.tintColor = .red
//            case 2: buttonToUpdate.setImage(UIImage(systemName: "circle.fill"), for: .normal)
//                buttonToUpdate.tintColor = .yellow
//            case 3: buttonToUpdate.setImage(UIImage(systemName: "circle.fill"), for: .normal)
//                buttonToUpdate.tintColor = .green
            default:
                return
            }
        }
    }
    
    func dismissAndSave() {
        // check for changes and save, no matter how dismissed
    }
        
    //MARK: PickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //MARK: StatusSelectionDelegate
    func didSelect(statusType: StatusType, status: Int) {
        updateStatusButtonAppearance(statusType: statusType, status: status)
        //button status changes to reflect selection.
        
        
       // save
    }
}




