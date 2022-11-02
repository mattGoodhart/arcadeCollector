//
//  DetailViewController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/3/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit
import SafariServices

enum Orientations: String {
    case horizontal = "Horizontal"
    case vertical = "Vertical"
}

protocol EditGameDelegate: AnyObject {
    func didFinishEditingGame()
}

class DetailViewController: UIViewController, EditGameDelegate {

    @IBOutlet weak var marqueeView: UIImageView!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var mainImageSwitch: UISegmentedControl!
    @IBOutlet weak var marqueeActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var mainImageActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var historyButton: UIButton!
    @IBOutlet weak var youTubeButton: UIButton!
    @IBOutlet weak var wantedButton: UIButton!
    @IBOutlet weak var addEditButton: UIButton!
    @IBOutlet weak var baseStackView: UIStackView!

    var isInMyCollection = false
    var isWanted = false
    let masterCollection = CollectionManager.shared
    var viewedGame: Game!
    var dataController = DataController.shared
    var viewedCollection: CollectionEntity!
    var titleImageData: Data?
    var inGameImageData: Data?
    var flyerImageData: Data?
    var marqueeImageData: Data?

    var viewMargins: UILayoutGuide {
        return view.layoutMarginsGuide
    }

    // MARK: - View Controller Life Cycle and Other Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        setMarqueeView()
        setImageViewAspectRatio() // why does this work? shouldnt this be in viewWillAppear?

     //   setOtherConstraints()
        determineCollectionsGameBelongsTo()

        self.title = viewedGame.title

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.mainImageTapped))
        let marqueeTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.marqueeImageTapped))

        configureGestureForImageView(imageView: mainImageView, gestureRecognizer: tapRecognizer)
        configureGestureForImageView(imageView: marqueeView, gestureRecognizer: marqueeTapRecognizer)

        mainImageView.image = nil // there will always be some image, so a placeholder unecessary
        getDetailsIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (UIApplication.shared.delegate as? AppDelegate)?.allowedOrientations = .portrait
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HardwareSegue" {
            let hardwareVC = segue.destination as! HardwareViewController
            hardwareVC.viewedGame = self.viewedGame
        }
    }

    // MARK: Actions

    @IBAction func hardwareButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "HardwareSegue", sender: self)
    }

    @IBAction func addEditButtonTapped(_ sender: UIButton) {
        let popOverVC = storyboard!.instantiateViewController(withIdentifier: "EditGameViewController") as! EditGameViewController
        popOverVC.viewedGame = viewedGame
        popOverVC.delegate = self
        popOverVC.modalTransitionStyle = .flipHorizontal
        present(popOverVC, animated: true, completion: nil)
    }

    @IBAction func addToWantedTapped(_ sender: UIButton) {
        if  !isWanted {
            masterCollection.wantedGames.append(viewedGame)
            masterCollection.wantedGamesCollection.addToGames(viewedGame)
            isWanted = true
            DispatchQueue.main.async {
                self.wantedButton.setImage(UIImage(named: "icons8-favorite-filled"), for: .normal)
            }
        } else {
            let removalIndex = masterCollection.wantedGames.firstIndex(of: viewedGame)
            masterCollection.wantedGames.remove(at: removalIndex!)
            masterCollection.wantedGamesCollection.removeFromGames(viewedGame)
            isWanted = false
            DispatchQueue.main.async {
                self.wantedButton.setImage(UIImage(named: "icons8-favorite"), for: .normal)
            }
        }
        try? dataController.viewContext.save()
    }

    @IBAction func historyButtonTapped(_ sender: UIButton) {
        let popoverViewController = storyboard!.instantiateViewController(withIdentifier: "PopOverViewController") as! PopOverViewController
        popoverViewController.type = .textView
        popoverViewController.text = viewedGame.history!
        popoverViewController.modalTransitionStyle = .coverVertical
        present(popoverViewController, animated: true, completion: nil)
    }

    @IBAction func segmentedControlPressed() {
        if viewedGame.flyerImageURLString != "" {
            switch mainImageSwitch.selectedSegmentIndex {
            case 0:
                getFlyerImageIfNeeded()
            case 1:
                getInGameImageIfNeeded()
            case 2:
                getTitleImageIfNeeded()
            default:
                break
            }

        } else {
            switch mainImageSwitch.selectedSegmentIndex {
            case 0:
                getInGameImageIfNeeded()
            case 1:
                getTitleImageIfNeeded()
            default:
                break
            }
        }
    }

    @IBAction func youTubeButtonPressed(_ sender: UIButton) {
        loadYoutube(videoID: viewedGame.youtubeVideoID ?? "")
    }

    // MARK: Other Methods

    func adjustImageView(height: CGFloat, multiplier: CGFloat) {
        mainImageView.translatesAutoresizingMaskIntoConstraints = false
     //   mainImageView.centerXAnchor.constraint(equalTo: viewMargins.centerXAnchor).isActive = true
     //   mainImageView.topAnchor.constraint(equalTo: marqueeView.bottomAnchor, constant: 20).isActive = true
        mainImageView.heightAnchor.constraint(equalToConstant: height).isActive = true
        mainImageView.widthAnchor.constraint(equalTo: mainImageView.heightAnchor, multiplier: multiplier).isActive = true
    }

    func setMarqueeView() {
        marqueeView.translatesAutoresizingMaskIntoConstraints = false
       // marqueeView.contentMode = .scaleAspectFit
       // marqueeView.topAnchor.constraint(equalTo: viewMargins.topAnchor, constant: 10).isActive = true
        // marqueeView.centerXAnchor.constraint(equalTo: viewMargins.centerXAnchor).isActive = true
        marqueeView.widthAnchor.constraint(equalTo: viewMargins.widthAnchor).isActive = true
        marqueeView.heightAnchor.constraint(equalTo: marqueeView.widthAnchor, multiplier: 0.25).isActive = true

        // marqueeView.heightAnchor.constraint(equalToConstant: 85).isActive = true
    }

    func setOtherConstraints() {
        mainImageSwitch.translatesAutoresizingMaskIntoConstraints = false
        mainImageSwitch.topAnchor.constraint(equalTo: mainImageView.bottomAnchor, constant: 20).isActive = true
        mainImageSwitch.centerXAnchor.constraint(equalTo: viewMargins.centerXAnchor).isActive = true

        baseStackView.widthAnchor.constraint(equalTo: viewMargins.widthAnchor).isActive = true
        baseStackView.centerXAnchor.constraint(equalTo: viewMargins.centerXAnchor).isActive = true
    }

    func setImageViewAspectRatio() {
        let orientation = viewedGame.orientation
        let horizontalHeight = UIScreen.main.bounds.height / 2.5
        let verticalHeight = UIScreen.main.bounds.height / 2

        switch orientation {
        case Orientations.horizontal.rawValue:
            mainImageView.contentMode = .scaleToFill
            adjustImageView(height: horizontalHeight, multiplier: 4.0/3.0)
        case Orientations.vertical.rawValue:
            mainImageView.contentMode = .scaleToFill
            adjustImageView(height: verticalHeight, multiplier: 3.0/4.0)
        default:
            mainImageView.contentMode = .scaleAspectFit
            adjustImageView(height: horizontalHeight, multiplier: 4.0/3.0)
        }
    }

    /// fetch collections the viewedGame belongs to
    func determineCollectionsGameBelongsTo() {
        var collectionNameArray = [String]()
        if let collectionOwnership = masterCollection.fetchCollectionsForGame(game: viewedGame) {

            for collection in collectionOwnership {
                collectionNameArray += [collection.name!]
            }

            isInMyCollection = collectionNameArray.contains("My Games")
            isWanted = collectionNameArray.contains("Wanted Games")
        }

        if isWanted { // maybe refactor setimage to include the dispatch to main
            DispatchQueue.main.async {
                self.wantedButton.setImage(UIImage(named: "icons8-favorite-filled"), for: .normal)
            }
        } else {
            DispatchQueue.main.async {
                self.wantedButton.setImage(UIImage(named: "icons8-favorite"), for: .normal)
            }
        }

        if isInMyCollection {
            DispatchQueue.main.async {
                self.addEditButton.setImage(UIImage(named: "icons8-edit"), for: .normal)
            }
        } else {
            DispatchQueue.main.async {
                self.addEditButton.setImage(UIImage(named: "icons8-add"), for: .normal)
            }
        }

        let index = self.tabBarController!.selectedIndex

        switch index {
        case 1:
            viewedCollection = masterCollection.myGamesCollection
        case 2:
            viewedCollection = masterCollection.allGamesCollection
        case 3:
            viewedCollection = masterCollection.wantedGamesCollection
        default:
            break
        }
    }

    func loadYoutube(videoID: String) {
        guard let youtubeURL = URL(string: "https://www.youtube.com/embed/\(videoID)?playsinline=1") else {
            return
        }
        UIApplication.shared.open(youtubeURL, options: [:], completionHandler: nil)
    }

    func toggleButtons(enabled: Bool) {
        handleButtons(enabled: enabled, button: historyButton)
        handleButtons(enabled: enabled, button: youTubeButton)
        handleButtons(enabled: enabled, button: addEditButton)

        mainImageSwitch.isEnabled = enabled
    }

    func loadMarquee(at url: URL) {

        Networking.shared.fetchData(at: url) { data in
            guard let data = data, let marqueeImage = UIImage(data: data) else {
                self.marqueeActivityIndicator.stopAnimating()
                return
            }
            self.viewedGame.marqueeImageData = data
            try? self.dataController.viewContext.save()
            self.marqueeView.image = marqueeImage
            self.marqueeActivityIndicator.stopAnimating()
        }
    }

    func getInGameImageIfNeeded() { // Note - combine this and below 2 methods?
        if let inGameImageData = viewedGame.inGameImageData, let image = UIImage(data: inGameImageData) {
            mainImageView.contentMode = .scaleToFill
            mainImageView.image = image
        } else {
            guard let urlString = viewedGame.inGameImageURLString, let url = URL(string: urlString) else {
                return
            }

            mainImageActivityIndicator.startAnimating()
            print("main activity indicator started for in-game image")

            Networking.shared.fetchData(at: url) { data in
                guard let data = data, let inGameImage = UIImage(data: data) else {

                    self.mainImageActivityIndicator.stopAnimating()

                    print("main activity indicator stopped because of in-game image failure")
                    return
                }

                self.viewedGame.inGameImageData = data
                try? self.dataController.viewContext.save()
                self.mainImageView.contentMode = .scaleToFill
                self.mainImageView.image = inGameImage
                self.mainImageActivityIndicator.stopAnimating()
                print("main activity indicator stopped for in-game image")
            }
        }
        if mainImageActivityIndicator.isAnimating {
            mainImageActivityIndicator.stopAnimating()
        }
    }

    func getTitleImageIfNeeded() {
        if let titleImageData = viewedGame.titleImageData {
            let image = UIImage(data: titleImageData)
            mainImageView.contentMode = .scaleToFill
            mainImageView.image = image
        } else {
            guard let urlString = viewedGame.titleImageURLString, let url = URL(string: urlString) else {
                return
            }
            mainImageActivityIndicator.startAnimating()

            print("main activity indicator started for title image")
            Networking.shared.fetchData(at: url) { data in
                guard let data = data, let titleImage = UIImage(data: data) else {
                    self.mainImageActivityIndicator.stopAnimating()

                    print("main activity indicator stopped because of failed title image")
                    return
                }

                self.viewedGame.titleImageData = data
                try? self.dataController.viewContext.save()
                self.mainImageView.contentMode = .scaleToFill
                self.mainImageView.image = titleImage
                self.mainImageActivityIndicator.stopAnimating()
                print("main activity indicator stopped for title image")
            }
        }
        if mainImageActivityIndicator.isAnimating {
            mainImageActivityIndicator.stopAnimating()
        }
    }

    func getFlyerImageIfNeeded() {
        if let flyerImageData = viewedGame.flyerImageData {
            let image = UIImage(data: flyerImageData)
            mainImageView.contentMode = .scaleAspectFit
            mainImageView.image = image
        } else {
            guard let urlString = viewedGame.flyerImageURLString, let url = URL(string: urlString) else {
                self.mainImageActivityIndicator.stopAnimating()

                print("main activity indicator stopped for failed flyer image")
                return
            }
            handleActivityIndicator(indicator: mainImageActivityIndicator, viewController: self, show: true)

            Networking.shared.fetchData(at: url) { data in
                guard let data = data, let flyerImage = UIImage(data: data) else {

                    self.mainImageActivityIndicator.stopAnimating()
                    print("main activity indicator stopped for failed flyer image")
                    return
                }

                self.viewedGame.flyerImageData = data
                try? self.dataController.viewContext.save()
                self.mainImageView.contentMode = .scaleAspectFit
                self.mainImageView.image = flyerImage
                self.mainImageActivityIndicator.stopAnimating()
                print("main activity indicator stopped for flyer image")
            }
        }

        if mainImageActivityIndicator.isAnimating {
            mainImageActivityIndicator.stopAnimating()
        }
    }

    func setImages() { // put dispatch here...
        if let inGameImageData =  viewedGame.inGameImageData {
            mainImageView.image = UIImage(data: inGameImageData)
        }

        if let marqueeImageData = viewedGame.marqueeImageData {
            marqueeView.image = UIImage(data: marqueeImageData)
        }

        if viewedGame.flyerImageURLString == "" {
            mainImageSwitch.removeSegment(at: 0, animated: false)
            mainImageSwitch.selectedSegmentIndex = 1
        }
    }

    func getDetailsIfNeeded() {
        if viewedGame.emulationStatus != nil {
            setImages()
            return
        } else {
            marqueeActivityIndicator.startAnimating()
            mainImageActivityIndicator.startAnimating()
            toggleButtons(enabled: false)

            let url = URL(string: "http://adb.arcadeitalia.net/service_scraper.php?ajax=query_mame&game_name=" + viewedGame.romSetName! + "&use_parent=1")!

            Networking.shared.taskForJSON(url: url, responseType: ArcadeDatabaseAPIResponse.self) { response, error in

                guard let response = response else {
                    print("error: \(String(describing: error))")

                    self.marqueeActivityIndicator.stopAnimating()
                    self.mainImageActivityIndicator.stopAnimating()
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

                self.mainImageActivityIndicator.stopAnimating()
                self.marqueeActivityIndicator.stopAnimating()
            }
        }
    }

    func getMarqueeIfNeeded() {

        guard let urlString = viewedGame.marqueeURLString, let url = URL(string: urlString) else {
            marqueeActivityIndicator.stopAnimating()
            return
        }
        marqueeActivityIndicator.startAnimating()
        loadMarquee(at: url)
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

        let zoomableImageViewController = storyboard!.instantiateViewController(withIdentifier: "ZoomableImageViewController") as! ZoomableImageViewController
        zoomableImageViewController.modalTransitionStyle = .crossDissolve

        if imageView == mainImageView && mainImageSwitch.selectedSegmentIndex != 0 {
            setImageForPopOver(viewController: zoomableImageViewController, imageView: imageView, isInGameImage: true)
        } else {
            setImageForPopOver(viewController: zoomableImageViewController, imageView: imageView, isInGameImage: false)
        }
        present(zoomableImageViewController, animated: true, completion: nil)
    }

    func configureGestureForImageView(imageView: UIImageView, gestureRecognizer: UIGestureRecognizer) {
        imageView.addGestureRecognizer(gestureRecognizer)
        imageView.isUserInteractionEnabled = true
    }

    func setImageForPopOver(viewController: ZoomableImageViewController, imageView: UIImageView, isInGameImage: Bool) {
        viewController.image = imageView.image
        viewController.isInGameImage = isInGameImage
        viewController.orientation = viewedGame.orientation
    }

    // MARK: EditGameDelegate
    func didFinishEditingGame() {
        determineCollectionsGameBelongsTo()
    }
}
