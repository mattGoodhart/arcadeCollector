//
//  DetailViewController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/3/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit
import SafariServices

class DetailViewController: UIViewController {
    
    //MARK: Properties
    
    var isInMyCollection = false
    var isWanted = false
    var viewMargins : UILayoutGuide!
    let masterCollection = CollectionManager.shared
    var viewedGame: Game!
    var dataController = DataController.shared
    var viewedCollection: CollectionEntity!
    var titleImageData: Data!
    var inGameImageData: Data!
    var flyerImageData: Data!
    var marqueeImageData: Data!
    
    @IBOutlet weak var marqueeView: UIImageView!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var mainImageSwitch: UISegmentedControl!
    @IBOutlet weak var marqueeActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var mainImageActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var historyButton: UIButton!
    @IBOutlet weak var youTubeButton: UIButton!
    @IBOutlet weak var wantedSwitch: UISwitch!
    @IBOutlet weak var addEditButton: UIButton!
    
    //MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewMargins = view.layoutMarginsGuide
        
        setMarqueeView()
        setImageViewAspectRatio()
        setOtherConstraints()
        determineCollectionsGameBelongsTo()
        
        handleActivityIndicator(indicator: marqueeActivityIndicator, vc: self, show: false)
        handleActivityIndicator(indicator: mainImageActivityIndicator, vc: self, show: false)
        self.title = viewedGame.title!
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.mainImageTapped))
        let marqueeTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.marqueeImageTapped))
        
        configureGestureForImageView(imageView: mainImageView, gestureRecognizer: tapRecognizer)
        configureGestureForImageView(imageView: marqueeView, gestureRecognizer: marqueeTapRecognizer)
        
        marqueeView.image = UIImage(named: "About Banners/logo-mame") // set better default
        mainImageView.image = nil
        getDetailsIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        
        if viewedGame.flyerImageURLString == "" {
             mainImageSwitch.selectedSegmentIndex = 1 // i want in-game to be highlighted, but this aint doing it
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HardwareSegue"  {
            let hardwareVC = segue.destination as! HardwareViewController
            hardwareVC.viewedGame = self.viewedGame
        }
    }

    //MARK: Actions
    
    @IBAction func hardwareButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "HardwareSegue", sender: self)
    }
    
    @IBAction func addEditButtonTapped(_ sender: UIButton) {
        let popOverVC = storyboard!.instantiateViewController(withIdentifier: "EditGameViewController") as! EditGameViewController
        popOverVC.viewedGame = viewedGame
        popOverVC.modalTransitionStyle = .crossDissolve
        present(popOverVC, animated: true, completion: nil)
    }
    
    @IBAction func addToWanted(_ sender: UISwitch) {
    
        if wantedSwitch.isOn {
            masterCollection.wantedGames.append(viewedGame)
            masterCollection.wantedGamesCollection.addToGames(viewedGame)
            wantedSwitch.setOn(true, animated: true)
        } else {
            let removalIndex = masterCollection.wantedGames.firstIndex(of: viewedGame)
            masterCollection.wantedGames.remove(at: removalIndex!)
            masterCollection.wantedGamesCollection.removeFromGames(viewedGame)
            wantedSwitch.setOn(false, animated: true)
        }
        try? dataController.viewContext.save()
    }
    
    @IBAction func historyButtonTapped(_ sender: UIButton) { 
        let popOverVC = storyboard!.instantiateViewController(withIdentifier: "PopOverViewController") as! PopOverViewController
        popOverVC.type = "textView"
        popOverVC.text = viewedGame.history!
        popOverVC.modalTransitionStyle = .crossDissolve
        present(popOverVC, animated: true, completion: nil)
    }
    
    @IBAction func segmentedControlPressed(){
        if viewedGame.flyerImageURLString != "" {
            switch mainImageSwitch.selectedSegmentIndex {
            case 0: getFlyerImageIfNeeded()
            case 1: getInGameImageIfNeeded()
            case 2: getTitleImageIfNeeded()
            default: break
            }
        } else {
            switch mainImageSwitch.selectedSegmentIndex {
            case 0: getInGameImageIfNeeded()
            case 1: getTitleImageIfNeeded()
            default: break
            }
        }
    }
    
    @IBAction func youTubeButtonPressed(_ sender: UIButton){
        loadYoutube(videoID: viewedGame.youtubeVideoID ?? "")
    }
    
    func adjustImageView(height: CGFloat, multiplier: CGFloat) {
        mainImageView.translatesAutoresizingMaskIntoConstraints = false
        mainImageView.centerXAnchor.constraint(equalTo: viewMargins.centerXAnchor).isActive = true
        mainImageView.topAnchor.constraint(equalTo: marqueeView.bottomAnchor, constant: 20).isActive = true
        mainImageView.heightAnchor.constraint(equalToConstant: height).isActive = true
        mainImageView.widthAnchor.constraint(equalTo: mainImageView.heightAnchor, multiplier: multiplier).isActive = true
    }
    
    func setMarqueeView() {
        marqueeView.translatesAutoresizingMaskIntoConstraints = false
        marqueeView.contentMode = .scaleAspectFit
        marqueeView.topAnchor.constraint(equalTo: viewMargins.topAnchor, constant: 10).isActive = true
        marqueeView.centerXAnchor.constraint(equalTo: viewMargins.centerXAnchor).isActive = true
        marqueeView.widthAnchor.constraint(equalTo: viewMargins.widthAnchor).isActive = true
        marqueeView.heightAnchor.constraint(equalToConstant: 85).isActive = true
      //  marqueeView.widthAnchor.constraint(equalTo: marqueeView.heightAnchor, multiplier: 4).isActive = true
    }
    
    func setOtherConstraints() {
        mainImageSwitch.translatesAutoresizingMaskIntoConstraints = false
        mainImageSwitch.topAnchor.constraint(equalTo: mainImageView.bottomAnchor, constant: 20).isActive = true
        mainImageSwitch.centerXAnchor.constraint(equalTo: viewMargins.centerXAnchor).isActive = true
        addEditButton.translatesAutoresizingMaskIntoConstraints = false
        addEditButton.topAnchor.constraint(equalTo: mainImageSwitch.bottomAnchor, constant: 20).isActive = true
        wantedSwitch.translatesAutoresizingMaskIntoConstraints = false
        wantedSwitch.centerYAnchor.constraint(equalTo: addEditButton.centerYAnchor).isActive = true
        wantedSwitch.trailingAnchor.constraint(equalTo: mainImageSwitch.trailingAnchor).isActive = true
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        historyButton.topAnchor.constraint(equalTo: addEditButton.bottomAnchor, constant: 20).isActive = true
        historyButton.leadingAnchor.constraint(equalTo: mainImageSwitch.leadingAnchor).isActive = true
        youTubeButton.translatesAutoresizingMaskIntoConstraints = false
        youTubeButton.centerYAnchor.constraint(equalTo: historyButton.centerYAnchor).isActive = true
        youTubeButton.centerXAnchor.constraint(equalTo: wantedSwitch.centerXAnchor).isActive = true
        addEditButton.centerXAnchor.constraint(equalTo: historyButton.centerXAnchor).isActive = true
    }
    
    func setImageViewAspectRatio() {
        let orientation = viewedGame.orientation
        switch orientation {
            
        case "Horizontal": mainImageView.contentMode = .scaleToFill
        adjustImageView(height: 210, multiplier: 4.0/3.0)
        case "Vertical": mainImageView.contentMode = .scaleToFill
        adjustImageView(height: 280, multiplier: 3.0/4.0)
        default: mainImageView.contentMode = .scaleAspectFit
        adjustImageView(height: 210, multiplier: 4.0/3.0)
            
        }
    }
    /// fetch collections the viewedGame belongs to
    func determineCollectionsGameBelongsTo() {
        
        var collectionNameArray = [String]()
        
        if let collectionOwnership = masterCollection.fetchCollectionsForGame(game: viewedGame) {

        for collection in collectionOwnership {
            collectionNameArray += [collection.name!]
        }
            if collectionNameArray.contains("My Games") {
                self.isInMyCollection = true
            }
            if collectionNameArray.contains("Wanted Games") {
                self.isWanted = true
            }
        }
        
        if isWanted {
            wantedSwitch.isOn = true
        } else {
            wantedSwitch.isOn = false
        }
    
        let index = self.tabBarController!.selectedIndex
        
        switch index {
        case 1: viewedCollection = masterCollection.myGamesCollection
        case 2: viewedCollection = masterCollection.allGamesCollection
        case 3: viewedCollection = masterCollection.wantedGamesCollection
        default: break
        }
    }
    
    func loadYoutube(videoID: String) {
        guard let youtubeURL = URL(string: "https://www.youtube.com/embed/\(videoID)?playsinline=1") else {
            return
        }
        
        UIApplication.shared.open(youtubeURL, options: [:], completionHandler: nil)
    }
    
    // MARK: Other Methods
    
    func toggleButtons(enabled: Bool) {
        if enabled {
            handleButtons(enabled: true, button: historyButton)
            handleButtons(enabled: true, button: youTubeButton)
            handleButtons(enabled: true, button: addEditButton)
            mainImageSwitch.isEnabled = true
        } else {
            handleButtons(enabled: false, button: historyButton)
            handleButtons(enabled: false, button: youTubeButton)
            handleButtons(enabled: false, button: addEditButton)
            mainImageSwitch.isEnabled = false
        }
    }
    
    func loadMarqueeFromURL(at url: URL) {
        DispatchQueue.global().async {
            guard let imageData = try? Data(contentsOf: url) else {
                print("Marquee download failure.")
                return
            }
            DispatchQueue.main.async {
                self.viewedGame.marqueeImageData = imageData
                try? self.dataController.viewContext.save()
                self.marqueeView.image = UIImage(data: imageData)!
            }
        }
    }
    
    func getInGameImageIfNeeded() {
        if let inGameImageData = viewedGame.inGameImageData {
            let image = UIImage(data: inGameImageData)
            mainImageView.contentMode = .scaleToFill
            mainImageView.image = image
        } else {
            if viewedGame.inGameImageURLString != "" {
                handleActivityIndicator(indicator: mainImageActivityIndicator, vc: self, show: true)
                let url = URL(string: viewedGame.inGameImageURLString!)!
                DispatchQueue.global().async {
                    guard let imageData = try? Data(contentsOf: url) else {
                        print("Photo download failure.")
                        self.handleActivityIndicator(indicator: self.mainImageActivityIndicator, vc: self, show: false)
                        return
                    }
                    DispatchQueue.main.async {
                        self.viewedGame.inGameImageData = imageData
                        try? self.dataController.viewContext.save()
                        self.mainImageView.contentMode = .scaleToFill
                        self.mainImageView.image = UIImage(data: imageData)!
                        self.handleActivityIndicator(indicator: self.mainImageActivityIndicator, vc: self, show: false)
                    }
                }
            } else {
                return
            }
        }
    }
    
    func getTitleImageIfNeeded() { // These methods can be refactored
        if let titleImageData = viewedGame.titleImageData {
            let image = UIImage(data: titleImageData)
            mainImageView.contentMode = .scaleToFill
            mainImageView.image = image
        } else {
            if viewedGame.titleImageURLString != "" {
                handleActivityIndicator(indicator: mainImageActivityIndicator, vc: self, show: true)
                let url = URL(string: viewedGame.titleImageURLString!)!
                DispatchQueue.global().async {
                    guard let imageData = try? Data(contentsOf: url) else {
                        print("Photo download failure.")
                        self.handleActivityIndicator(indicator: self.mainImageActivityIndicator, vc: self, show: false)
                        return
                    }
                    DispatchQueue.main.async {
                        self.viewedGame.titleImageData = imageData
                        try? self.dataController.viewContext.save()
                        self.mainImageView.contentMode = .scaleToFill
                        self.mainImageView.image = UIImage(data: imageData)!
                        self.handleActivityIndicator(indicator: self.mainImageActivityIndicator, vc: self, show: false)
                    }
                }
            } else {
                return
            }
        }
    }
    
    func getFlyerImageIfNeeded(){
        if let flyerImageData = viewedGame.flyerImageData {
            let image = UIImage(data: flyerImageData)
            mainImageView.contentMode = .scaleAspectFit
            mainImageView.image = image
        } else {
            if viewedGame.flyerImageURLString != "" {
                handleActivityIndicator(indicator: mainImageActivityIndicator, vc: self, show: true)
                let url = URL(string: viewedGame.flyerImageURLString!)!
                DispatchQueue.global().async {
                    guard let imageData = try? Data(contentsOf: url) else {
                        print("Flyer download failure.")
                        self.handleActivityIndicator(indicator: self.mainImageActivityIndicator, vc: self, show: false)
                       // self.mainImageSwitch.setEnabled(false, forSegmentAt: 0)
                        self.mainImageSwitch.removeSegment(at: 0, animated: true)
                        return
                    }
                    DispatchQueue.main.async {
                        self.viewedGame.flyerImageData = imageData
                        try? self.dataController.viewContext.save()
                        self.mainImageView.contentMode = .scaleAspectFit
                        self.mainImageView.image = UIImage(data: imageData)!
                        self.handleActivityIndicator(indicator: self.mainImageActivityIndicator, vc: self, show: false)
                    }
                }
            } else {
                self.handleActivityIndicator(indicator: self.mainImageActivityIndicator, vc: self, show: false)
                //self.mainImageSwitch.setEnabled(false, forSegmentAt: 0)
                 self.mainImageSwitch.removeSegment(at: 0, animated: true)
                return
            }
        }
    }
    
    func getDetailsIfNeeded() {
        
        if viewedGame.emulationStatus != nil {
            if let inGameImageData =  viewedGame.inGameImageData {
                mainImageView.image = UIImage(data: inGameImageData)
            }
            if let marqueeImageData = viewedGame.marqueeImageData {
                marqueeView.image = UIImage(data: marqueeImageData)
            }
            
            if viewedGame.flyerImageURLString == "" {
                mainImageSwitch.removeSegment(at: 0, animated: false)
            }
            return
        } else {
            
            handleActivityIndicator(indicator: self.marqueeActivityIndicator, vc: self, show: true)
            handleActivityIndicator(indicator: self.mainImageActivityIndicator, vc: self, show: true)
            toggleButtons(enabled: false)
            
            let url = URL(string: "http://adb.arcadeitalia.net/service_scraper.php?ajax=query_mame&game_name=" + viewedGame.romSetName! + "&use_parent=1")!
            
            Networking().taskForJSON(url: url, responseType: ArcadeDatabaseAPIResponse.self) { response, error in
                
                guard let response = response else {
                    print("error: \(String(describing: error))")
                    self.handleActivityIndicator(indicator: self.marqueeActivityIndicator, vc: self, show: false)
                    self.handleActivityIndicator(indicator: self.mainImageActivityIndicator, vc: self, show: false)
                    return
                }
                
                for item in response.result {
                    self.viewedGame.inGameImageURLString = item.inGameImageURLString
                    self.viewedGame.titleImageURLString = item.titleImageURLString
                    self.viewedGame.marqueeURLString = item.marqueeImageURLString
                    self.viewedGame.cabinetImageURLString = item.cabinetImageURLString
                    self.viewedGame.flyerImageURLString = item.flyerImageURLString
                    self.viewedGame.genre = item.genre
                    self.viewedGame.nPlayers = item.nPlayers
                    self.viewedGame.year = item.releaseYear
                    self.viewedGame.emulationStatus = item.emulationStatus
                    self.viewedGame.history = item.history
                    self.viewedGame.inputControls = item.inputControls
                    self.viewedGame.inputButtons = String(item.inputButtons)
                    self.viewedGame.youtubeVideoID = item.youtubeVideoID
                    self.viewedGame.shortPlayURLString = item.shortPlayURLString
                }
                try? self.dataController.viewContext.save()
                self.getInGameImageIfNeeded()
                self.getMarqueeIfNeeded()
                self.toggleButtons(enabled: true)
                
                if self.viewedGame.flyerImageURLString == "" {
                    self.mainImageSwitch.removeSegment(at: 0, animated: false)
                }
            }
        }
    }
    
    func getMarqueeIfNeeded() {
        
        if let marqueeURLString = self.viewedGame.marqueeURLString {
            if marqueeURLString != "" {
                self.loadMarqueeFromURL(at: URL(string: marqueeURLString)!)
                self.handleActivityIndicator(indicator: self.marqueeActivityIndicator, vc: self, show: false)
            } else {
                self.handleActivityIndicator(indicator: self.marqueeActivityIndicator, vc: self, show: false)
            }
        }
    }
    
    @objc func mainImageTapped(_ sender: UIGestureRecognizer) {
        if sender.state == .ended {
            photoTapped(imageView: mainImageView)
        }
    }
    
    @objc func marqueeImageTapped(_ sender: UIGestureRecognizer) {
        if sender.state == .ended {
            photoTapped(imageView: marqueeView)
        }
    }
    
    func photoTapped(imageView: UIImageView) {
        
        let popOverViewController = storyboard!.instantiateViewController(withIdentifier: "PopOverViewController") as! PopOverViewController
        popOverViewController.modalTransitionStyle = .crossDissolve
        
        if imageView == mainImageView && mainImageSwitch.selectedSegmentIndex != 0 {
            setImageForPopOver(viewController: popOverViewController, imageView: imageView, viewType: "gameImageView")
        }
        
        if imageView == mainImageView && mainImageSwitch.selectedSegmentIndex == 0 {
            setImageForPopOver(viewController: popOverViewController, imageView: imageView, viewType: "flyerView")
        }
        
        if imageView == self.marqueeView {
            setImageForPopOver(viewController: popOverViewController, imageView: imageView, viewType: "marqueeView")
        }
        present(popOverViewController, animated: true, completion: nil)
    }
    
    func configureGestureForImageView(imageView: UIImageView, gestureRecognizer: UIGestureRecognizer) {
        imageView.addGestureRecognizer(gestureRecognizer)
        imageView.isUserInteractionEnabled = true
    }
    
    func setImageForPopOver(viewController: PopOverViewController, imageView: UIImageView, viewType: String) {
        if viewType != "marqueeView" {
            viewController.image = imageView.image
        } else {
            viewController.marqueeImage = imageView.image
        }
        viewController.type = viewType
        guard viewType == "gameImageView" else {
            return
        }
        viewController.orientation = viewedGame.orientation
    }
}
