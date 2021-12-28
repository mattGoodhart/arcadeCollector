//
//  PCBViewController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/4/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit
import PDFKit
import SafariServices

class HardwareViewController: UIViewController, XMLParserDelegate {
    
//    @IBOutlet weak var controlsStack : UIStackView!
//    @IBOutlet weak var displayStack : UIStackView!
//    @IBOutlet weak var audioStack : UIStackView!
//    @IBOutlet weak var processorsStack : UIStackView!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var displayLine: UILabel!
    @IBOutlet weak var controlsLine: UILabel!
   // @IBOutlet weak var soundHardwareLine: UILabel!
    @IBOutlet weak var processorsLine: UILabel!
    @IBOutlet weak var imageChooser: UISegmentedControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  //  @IBOutlet weak var audioChannelsLine: UILabel!
    @IBOutlet weak var manualButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var mameButton: UIButton!
    @IBOutlet weak var joystickIcon: UIImageView!
    @IBOutlet weak var displayIcon: UIImageView!
    @IBOutlet weak var audioIcon: UIImageView!
    @IBOutlet weak var processorIcon: UIImageView!
    @IBOutlet weak var audioLine: UILabel!
    
    var imageViewAspectConstraint: NSLayoutConstraint?
    var isPDF: Bool = false
    var formattedSoundStringArray: [String] = []
    var formattedCPUStringArray: [String] = []
    var cpuStringArray: [String] = []
    var soundDeviceStringArray: [String] = []
    var viewedGame: Game!
    var soundChannels = ""
    let dataController = DataController.shared
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var currentValue: String?
    var machineDictionary: [String: String]?
    var displayDictionary: [String: String]?
    var chipDictionary: [String: String]?
    var chipResults: [[String: String]]?
    let machineElementKeys = Set<String>(["year" , "description", "manufacturer", "chip", "display", "sound"])
    
    var hasEmptyImageStrings: Bool {
        return viewedGame.pcbPhotoURLString == "" || viewedGame.cabinetImageURLString == ""
    }
    
    var hasNoAvailableImages: Bool {
        return viewedGame.pcbPhotoURLString == "" && viewedGame.cabinetImageURLString == ""
    }

    //MARK View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepMainImageView()
        getHardwareDetailsIfNeeded(game: viewedGame)
        buildMainStackView()
        manualButton.setTitle("Manual Unavailable", for: .disabled)
    }
    
    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(true)
        
        appDelegate.allowedOrientations = .portrait
        
        if viewedGame.manualURLString == "" {
            manualButton.isEnabled = false
        }
    }
    
    @IBAction func mameNotesButtonTapped(_ sender: UIButton) {
      //  getNotesFromMameIfNeeded()
        goToMameDriverOnGithub()
    }

    func setImage(image: UIImage) {
    
        for view in stackView.subviews {
            stackView.removeArrangedSubview(view)
        }
        
        mainImageView.image = image
        
        imageViewAspectConstraint?.isActive = false
        imageViewAspectConstraint = mainImageView.widthAnchor.constraint(equalTo: mainImageView.heightAnchor, multiplier: image.size.width / image.size.height)
        imageViewAspectConstraint!.isActive = true
        
        buildMainStackView()
        scrollView.setContentOffset(.zero, animated: true)
    }
    
    func buildMainStackView() {
        stackView.addArrangedSubview(mainImageView)
        stackView.addArrangedSubview(imageChooser)
        stackView.addArrangedSubview(mameButton)
        stackView.addArrangedSubview(manualButton)
        stackView.addArrangedSubview(joystickIcon)
        stackView.addArrangedSubview(controlsLine)
        stackView.addArrangedSubview(displayIcon)
        stackView.addArrangedSubview(displayLine)
        stackView.addArrangedSubview(audioIcon)
        stackView.addArrangedSubview(audioLine)
        //stackView.addArrangedSubview(soundHardwareLine)
        stackView.addArrangedSubview(processorIcon)
        stackView.addArrangedSubview(processorsLine)
//        stackView.addArrangedSubview(controlsStack)
//        stackView.addArrangedSubview(displayStack)
//        stackView.addArrangedSubview(audioStack)
//        stackView.addArrangedSubview(processorsStack)
    }
    
    func prepMainImageView() {
        handleActivityIndicator(indicator: activityIndicator, vc: self, show: false)
        mainImageView.image = nil
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.mainImageTapped))
        mainImageView.addGestureRecognizer(tapRecognizer)
        mainImageView.isUserInteractionEnabled = true
        
        if hasEmptyImageStrings {
            imageChooser.isHidden = true
        }
        
        if hasNoAvailableImages {
            imageChooser.isHidden = true
            mainImageView.image = UIImage(named: "noHardwareDefaultImage")
        }
        
        if viewedGame.manualURLString == "" {
            manualButton.isEnabled = false
        }
    }
    
    func goToMameDriverOnGithub () {
        guard let driver = viewedGame.driver, let url = URL(string: "https://github.com/mamedev/mame/blob/master/src/mame/drivers/" + driver) else {
            return
        }
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
    
    func segueToMameNotes() {
        let popOverViewController = storyboard!.instantiateViewController(withIdentifier: "PopOverViewController") as! PopOverViewController
        popOverViewController.text = viewedGame.mameNotes ?? "Sorry, MAME driver notes could not be fetched."
        popOverViewController.type = "Horizontally Scrolling textView"
        popOverViewController.modalTransitionStyle = .crossDissolve
        present(popOverViewController, animated: true, completion: nil)
    }
    
    @objc func mainImageTapped(_ sender: UIGestureRecognizer) {
        if sender.state == .ended {
            let popOverViewController = storyboard!.instantiateViewController(withIdentifier: "PopOverViewController") as! PopOverViewController
            popOverViewController.image = mainImageView.image
            popOverViewController.type = "hardwareView"
            popOverViewController.modalTransitionStyle = .crossDissolve
            present(popOverViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func manualButtonTapped(_ sender: UIButton) {
        getManualIfNeeded()
//        if let manual = viewedGame.manual {
//            segueToManualViewController(manualData: manual)
//        } else {
//            getManualIfNeeded()
//        }
    }
    
    func segueToManualViewController(manualData: Data) {
        let manualPDF = PDFDocument(data: manualData)!
        let popOverVC = storyboard!.instantiateViewController(withIdentifier: "PopOverViewController") as! PopOverViewController
        popOverVC.manual = manualPDF
        popOverVC.type = "pdfView"
        popOverVC.modalTransitionStyle = .crossDissolve
        present(popOverVC, animated: true, completion: nil)
    }
    
    @IBAction func segmentedControlPressed(_sender: UISegmentedControl) {
        stackView.arrangedSubviews[0].isHidden = true
        
        guard let cabinetImageData = viewedGame.cabinetImageData, let cabinetImage = UIImage(data: cabinetImageData) else {
            return
        }
    
        switch imageChooser.selectedSegmentIndex {
        case 0:
            setImage(image: cabinetImage)
        case 1:
            getBoardPhotoIfNeeded()
        default: break;
        }
        
        stackView.arrangedSubviews[0].isHidden = false
    }
    
    func getNotesFromMameIfNeeded() {
        if viewedGame.mameNotes != nil {
            segueToMameNotes()
        } else {
            
            guard let driver = viewedGame.driver, let url = URL(string: "https://raw.githubusercontent.com/mamedev/mame/master/src/mame/drivers/" + driver) else {
                return
            }
            
            Networking.shared.fetchText(at: url) { textData in 
                if let range = textData.range(of: "*/") {
                    let notes = textData [..<range.upperBound]
                    let mameNotes = String(notes)
                    self.viewedGame.mameNotes = mameNotes
                    try? self.dataController.viewContext.save()
                } else {
                    print("Substringing didn't go so well")
                }
                self.segueToMameNotes()
            }
        }
    }
    
    func setInfo() {
        
        var cpuLineText = ""
        var soundDevicesLineText = ""
        
        for cpu in viewedGame!.cpuStringArray! {
            cpuLineText += cpu + "\n"
        }
        for device in viewedGame!.soundDeviceStringArray! {
            soundDevicesLineText += device + "\n"
        }
        
        let horizontalRefresh = getMonitorResolutionType()
//        soundHardwareLine.text = soundDevicesLineText
//        soundHardwareLine.sizeToFit()
//        audioChannelsLine.text = viewedGame.audioChannels ?? "?"
        audioLine.text = "\(viewedGame.audioChannels ?? "?")\n\(soundDevicesLineText)"
        audioLine.sizeToFit()
        processorsLine.text = cpuLineText
        processorsLine.sizeToFit()
        displayLine.text = "\(viewedGame.orientation?.capitalized ?? "")\n \(viewedGame.displayType?.capitalized ?? "")\n \(viewedGame.resolution ?? "")\n \(horizontalRefresh)"
        if let inputButtons = viewedGame.inputButtons?.capitalized {
            controlsLine.text = "\(viewedGame.inputControls?.capitalized ?? "")\n \(inputButtons) Button(s)"
        } else {
            controlsLine.text = "\(viewedGame.inputControls ?? "")"
        }
    }
    
    func getHardwareDetailsIfNeeded(game: Game) {
        if viewedGame.resolution != nil {
            setInfo()
            getAtLeastOnePhotoIfPossible()
        } else {
            getInfoFromXML()
            setInfo()
            getAtLeastOnePhotoIfPossible()
        }
    }
    
    func getAtLeastOnePhotoIfPossible() {
        if let cabinetImageData = viewedGame.cabinetImageData, let image = UIImage(data: cabinetImageData) {
            setImage(image: image)
        } else {
            
            guard viewedGame.cabinetImageURLString != "", let cabinetURLString = viewedGame.cabinetImageURLString, let url = URL(string: cabinetURLString) else {
                print("No Cabinet Photo Available")
                DispatchQueue.main.async {
                    self.imageChooser.isHidden = true
                }
                getBoardPhotoIfNeeded()
                return
            }
            
            handleActivityIndicator(indicator: activityIndicator, vc: self, show: true)
            
            Networking.shared.fetchData(at: url) { data in
                
                guard let data = data, let cabinetImage = UIImage(data: data) else {
                    self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                    self.getBoardPhotoIfNeeded()
                    return
                }
                
                self.viewedGame.cabinetImageData = data
                try? self.dataController.viewContext.save()
                self.setImage(image: cabinetImage)
                self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                self.getBoardPhotoIfNeeded()
               // self.getPCBPhotoButDontSetImage()
            }
        }
    }
    
//    func getPCBPhotoButDontSetImage () {
//        guard viewedGame.pcbPhotoURLString != "", let inputString = self.viewedGame.romSetName,
//            let url = URL(string: "http://adb.arcadeitalia.net/media/mame.current/pcbs/" + inputString + ".png") else {
//
//                self.imageChooser.isHidden = true
//                print("no PCB image available")
//                if hasNoAvailableImages {
//                    setImage(image: UIImage(named: "noHardwareDefaultImage")!)
//                }
//                return
//        }
//        Networking.shared.fetchData(at: url) { data in
//
//            guard let data = data else {
//                print("PCB Photo download failure.")
//                self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
//                self.viewedGame.pcbPhotoURLString = ""
//                self.imageChooser.isHidden = true
//
//                if self.hasNoAvailableImages {
//                    self.setImage(image: UIImage(named: "noHardwareDefaultImage")!)
//                }
//
//                return
//            }
//            self.viewedGame.pcbImageData = data
//            try? self.dataController.viewContext.save()
//
//        }
//    }
    
    
    func getBoardPhotoIfNeeded () {
        
        if let boardPhotoData = viewedGame.pcbImageData, let image = UIImage(data: boardPhotoData) {
            setImage(image: image)
        } else {
            //note: pcbPhotoURLString only will ever be nil or "" . maybe should update the name of this attribute and make it a bool
            guard viewedGame.pcbPhotoURLString != "", let inputString = self.viewedGame.romSetName,
                let url = URL(string: "http://adb.arcadeitalia.net/media/mame.current/pcbs/" + inputString + ".png") else {
                    
                    self.imageChooser.isHidden = true
                    print("no PCB image available")
                    if hasNoAvailableImages {
                        setImage(image: UIImage(named: "noHardwareDefaultImage")!)
                    }
                    return
            }
            
            handleActivityIndicator(indicator: activityIndicator, vc: self, show: true)
            Networking.shared.fetchData(at: url) { data in
                
                guard let data = data, let pcbImage = UIImage(data: data) else {
                    print("PCB Photo download failure.")
                    self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                    self.viewedGame.pcbPhotoURLString = ""
                    self.imageChooser.isHidden = true
                    
                    if self.hasNoAvailableImages {
                        self.setImage(image: UIImage(named: "noHardwareDefaultImage")!)
                    }
                    
                    return
                }
                self.viewedGame.pcbImageData = data
                try? self.dataController.viewContext.save()
                self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                if self.viewedGame.cabinetImageURLString == "" {
                    self.setImage(image: pcbImage)
                }
            }
        }
    }
    
    func saveGameAttributesFromXML() {
        viewedGame.displayType = displayDictionary?["type"] ?? "Unknown Type"
        viewedGame.vRefresh = displayDictionary?["refresh"] ?? "Unknown vRefresh"
        viewedGame.vTotalLines = displayDictionary?["vtotal"] ?? "Unknown vTotalLines"
        
        if (displayDictionary?["width"]) != nil {
        viewedGame.resolution = displayDictionary!["width"]! + " x " + displayDictionary!["height"]!
        } else {
            viewedGame.resolution = "Unknown"
        }
        
        viewedGame.hRefresh = getHorizontalRefresh(viewedGame: viewedGame)
        viewedGame.driver = machineDictionary!["driver"]
        viewedGame.audioChannels = soundChannels
        viewedGame.monitorResolutionType = getMonitorResolutionType()
        parseHardwareData()
        try? dataController.viewContext.save()
    }
    
    func getInfoFromXML(){
        
        let urlString = String("http://adb.arcadeitalia.net/download_file.php?tipo=xml&codice=" + viewedGame.romSetName!)
        let url = URL(string: urlString)!
        
        guard let data = try? Data(contentsOf: url) else {
            print("XML download failure.")
            return
        }
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        if parser.parse() {
            self.saveGameAttributesFromXML()
        }
    }
    
    func checkForRealPDF(assetData: NSData) {
        guard assetData.length >= 1024 else {
            return
        }
        var pdfBytes = [UInt8]()
        pdfBytes = [0x25, 0x50, 0x44, 0x46]
        let pdfHeader = NSData(bytes: pdfBytes, length: 4)
        let a = NSData(data: assetData as Data).range(of: pdfHeader as Data, options: .anchored, in: NSMakeRange(0, 1024))
        if (a.length) > 0 {
            isPDF = true
        } else {
            isPDF = false
        }
    }
    func fileExistsAt(url: URL, completion: @escaping (Bool) -> Void) {
        let checkSession = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 1.0 // Adjust to your needs
        let task = checkSession.dataTask(with: request) { (data, response, error) -> Void in
            if let httpResp = response as? HTTPURLResponse {
                completion(httpResp.statusCode == 200) }
        
        }
        task.resume()
    }
        
    func getManualIfNeeded() {
        if let manual = viewedGame.manual {
            segueToManualViewController(manualData: manual)
        } else {
            guard viewedGame.manualURLString != "", let romName = self.viewedGame.romSetName, let url = URL(string: "http://adb.arcadeitalia.net/download_file.php?tipo=mame_current&codice=" + romName + "&entity=manual") else {
                manualButton.isEnabled = false
                return
            }
//            fileExistsAt(url: url) { response in
//                guard let response = response else {
//                    print("no response")
//                }
//                print(response)
         //   }
                
           // let pdfExists = fileExistsAt(url: url, completion: <#T##(Bool) -> Void#>)
            //let pdfExists = try?url.checkResourceIsReachable()
            //print(pdfExists as Any)
            handleActivityIndicator(indicator: activityIndicator, vc: self, show: true)
            Networking.shared.fetchData(at: url) { data in
                guard let data = data else {
                    print("manual download failure.")
                    
                        self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                        self.manualButton.isEnabled = false
                       // self.manualButton.isHidden = true
                        self.viewedGame.manualURLString = ""
                        try? self.dataController.viewContext.save()
                    
                    return
                }
                self.checkForRealPDF(assetData: NSData(data: data))
                if !self.isPDF {
                    self.viewedGame.manualURLString = ""
                    self.viewedGame.manual = nil
                    self.manualButton.isEnabled = false
                    self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                    try? self.dataController.viewContext.save()
                    return
                } else {
                    self.viewedGame.manual = data
                    try? self.dataController.viewContext.save()
                    self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                    self.segueToManualViewController(manualData: data)
                }
                
            }
        }
    }
    
    func getHorizontalRefresh(viewedGame: Game) -> String {
        
        if let vRefresh = Double(viewedGame.vRefresh!), let vTotalLines = Double(viewedGame.vTotalLines!) {
           let hRefresh = vRefresh * vTotalLines
            return "\(hRefresh)"
        } else {
            if Int(displayDictionary!["width"]!)! > 262 {
                let hRefresh = Double(31550)
                return "\(hRefresh)"
            } else {
                let hRefresh = Double(15720)
                return "\(hRefresh)"
            }
        }
    }
    
    func getMonitorResolutionType() -> String {
        if let hRefresh = viewedGame.hRefresh {
            
            let hRefreshInt = Int(Double(hRefresh)!)
            
            if hRefreshInt <= 15720 {
                return "Standard - 15.72KHz"
            }
            else if hRefreshInt <= 16500 {
                return "Extended - 16.50KHz"
            }
            else if hRefreshInt <= 25000 {
                return "Medium - 25.00KHz"
            }
            else if hRefreshInt <= 31550 {
                return "VGA - 31.55KHz"
            }
            else {
                return "Uncertain Horizontal Refresh Rate"
            }
        }
        else { return "Horizontal Refresh Unknown" }
    }
}

