//
//  PCBViewController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/4/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

//ToDO: calculate size in Megabits of game

import UIKit
import PDFKit

class HardwareViewController: UIViewController, XMLParserDelegate {
    
    var isPDF : Bool = false
    var formattedSoundStringArray = [String]()
    var formattedCPUStringArray = [String]()
    var cpuStringArray = [String]()
    var soundDeviceStringArray = [String]()
    var viewedGame: Game!
    var soundChannels = ""
    let dataController = DataController.shared
    var currentValue: String?
    var machineDictionary: [String: String]?
    var displayDictionary: [String: String]?
    var chipDictionary: [String: String]?
    var chipResults: [[String: String]]?
    let machineElementKeys = Set<String>(["year" , "description", "manufacturer", "chip", "display", "sound"])
    var pdfDoc: PDFDocument?
    
    @IBOutlet weak var controlsStack : UIStackView!
    @IBOutlet weak var displayStack : UIStackView!
    @IBOutlet weak var audioStack : UIStackView!
    @IBOutlet weak var processorsStack : UIStackView!
    
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var displayLine: UILabel!
    @IBOutlet weak var controlsLine: UILabel!
    @IBOutlet weak var soundHardwareLine: UILabel!
    @IBOutlet weak var processorsLine: UILabel!
    @IBOutlet weak var imageChooser: UISegmentedControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var audioChannelsLine: UILabel!
    @IBOutlet weak var manualButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var mameButton: UIButton!
    
    
    //MARK App Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepMainImageView()
        getHardwareDetailsIfNeeded(game: viewedGame)
        
      //  buildMainStackView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if viewedGame.manualURLString == "" {
            manualButton.isEnabled = false
        }
        
       // stackView.heightAnchor.constraint(equalTo: proces).isActive = true
    }
    
    @IBAction func mameNotesButtonTapped(_ sender: UIButton) {
        getNotesFromMameIfNeeded()
    }
    
//    func determineStackHeight() {
//        mainImageView.
//
//
//    }
    
    func setImage(image: UIImage) {
        var imageViewAspectConstraint: NSLayoutConstraint?
        
        mainImageView.image = image
        
        imageViewAspectConstraint?.isActive = false
        imageViewAspectConstraint = mainImageView.widthAnchor.constraint(equalTo: mainImageView.heightAnchor, multiplier: image.size.width / image.size.height)
        imageViewAspectConstraint!.isActive = true
    }
    
    func buildMainStackView() {
        
        buildIndividualStackViews()
        
        stackView.addArrangedSubview(mainImageView)
        stackView.addArrangedSubview(imageChooser)
        stackView.addArrangedSubview(mameButton)
        stackView.addArrangedSubview(manualButton)
        stackView.addArrangedSubview(controlsStack)
        stackView.addArrangedSubview(displayStack)
        stackView.addArrangedSubview(audioStack)
        stackView.addArrangedSubview(processorsStack)
    }
    
    func buildIndividualStackViews() {
        let controlsTitle = UILabel()
        controlsTitle.text = "Controls"
        
        controlsStack.addArrangedSubview(controlsTitle)
        controlsStack.addArrangedSubview(controlsLine)
    }
    
    
    func prepMainImageView() {
        handleActivityIndicator(indicator: activityIndicator, vc: self, show: false)
        mainImageView.image = nil
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.mainImageTapped))
        mainImageView.addGestureRecognizer(tapRecognizer)
        mainImageView.isUserInteractionEnabled = true
        
        if hasEmptyImageStrings() {
            imageChooser.isHidden = true
        }
        
        if hasNoAvailableImages(){
            mainImageView.image = UIImage(named: "noHardwareDefaultImage")
        }
        
        if viewedGame.manualURLString == "" {
            manualButton.isEnabled = false
        }
    }
    
    func segueToMameNotes() {
        let popOverVC = storyboard!.instantiateViewController(withIdentifier: "PopOverViewController") as! PopOverViewController
        popOverVC.text = viewedGame.mameNotes ?? "Sorry, MAME driver notes could not be fetched."
        popOverVC.type = "textView"
        popOverVC.modalTransitionStyle = .crossDissolve
        present(popOverVC, animated: true, completion: nil)
    }
    
    @objc func mainImageTapped(_ sender: UIGestureRecognizer) {
        if sender.state == .ended {
            let popOverVC = storyboard!.instantiateViewController(withIdentifier: "PopOverViewController") as! PopOverViewController
            popOverVC.image = mainImageView.image
            popOverVC.type = "hardwareView"
            popOverVC.modalTransitionStyle = .crossDissolve
            present(popOverVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func manualButtonTapped(_ sender: UIButton) {
        
        if let manual = viewedGame.manual {
            segueToManualViewController(manualData: manual)
        } else {
            getManualIfNeeded()
        }
    }
    
    func segueToManualViewController(manualData: Data) {
        let manualPDF = PDFDocument(data: manualData)!
        let popOverVC = storyboard!.instantiateViewController(withIdentifier: "PopOverViewController") as! PopOverViewController
        popOverVC.manual = manualPDF
        popOverVC.type = "pdfView"
        popOverVC.modalTransitionStyle = .crossDissolve
        present(popOverVC, animated: true, completion: nil)
    }
    
    @IBAction func segmentedControlPressed(_sender: UISegmentedControl){
        stackView.arrangedSubviews[0].isHidden = true
        switch imageChooser.selectedSegmentIndex {
        case 0: setImage(image: UIImage(data: self.viewedGame.cabinetImageData!)!)
        case 1: getBoardPhotoIfNeeded()
        default: break;
        }
          stackView.arrangedSubviews[0].isHidden = false
    }
    // to allow the stack view to update properly, I need to providethe  view's aspect ratio?. Probably...or do I need to completely rebuild the stackview?... or force the imagechooser to not stretch with hugging priority or something?
    
    func getNotesFromMameIfNeeded() {
        
        if viewedGame.mameNotes != nil {
            segueToMameNotes()
        } else {
            let url = URL(string: "https://raw.githubusercontent.com/mamedev/mame/master/src/mame/drivers/" + viewedGame.driver!)!
            
            DispatchQueue.global().async {
                do {
                    let contents = try String(contentsOf: url)
                    if let range = contents.range(of: "*/") {
                        let notes = contents [..<range.upperBound]
                        let mameNotes = String(notes)
                        self.viewedGame.mameNotes = mameNotes
                        try? self.dataController.viewContext.save()
                    } else {
                        print("Substringing didn't go so well")
                    }
                    DispatchQueue.main.async {
                        self.segueToMameNotes()
                    }
                }
                catch {
                    print("Contents Could Not Be Loaded")
                }
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
        soundHardwareLine.text = soundDevicesLineText
        soundHardwareLine.sizeToFit()
        audioChannelsLine.text = viewedGame.audioChannels ?? "viewedGame.audioChannels is nil"
        processorsLine.text = cpuLineText
        processorsLine.sizeToFit()
        displayLine.text = "\(viewedGame.orientation ?? ""), \(viewedGame.displayType ?? ""), \(viewedGame.resolution ?? ""), \(horizontalRefresh)"
        controlsLine.text = " \(viewedGame.inputControls ?? ""), \(viewedGame.inputButtons ?? "") buttons"
    }
    
    func getHardwareDetailsIfNeeded(game: Game) {
        if viewedGame.resolution != nil {
            setInfo()
            getAtLeastOnePhotoIfPossible()
            return
        } else {
            getInfoFromXML()
            setInfo()
            getAtLeastOnePhotoIfPossible()
        }
    }
    
    func getAtLeastOnePhotoIfPossible() {
        
        if let cabinetImageData = viewedGame.cabinetImageData {
            let image = UIImage(data: cabinetImageData)
            setImage(image: image!)
          //  mainImageView.image = image
        } else {
            if viewedGame.cabinetImageURLString != "" {
                handleActivityIndicator(indicator: activityIndicator, vc: self, show: true)
                let url = URL(string: viewedGame.cabinetImageURLString!)!
                DispatchQueue.global().async {
                    guard let imageData = try? Data(contentsOf: url) else {
                        print("Cabinet Photo download failure.")
                        self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                        DispatchQueue.main.async {
                            self.imageChooser.isHidden = true
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        self.viewedGame.cabinetImageData = imageData
                        try? self.dataController.viewContext.save()
                        self.setImage(image: UIImage(data: imageData)!)
                       // self.mainImageView.image = UIImage(data: imageData)!
                        self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                    }
                }
            } else {
                print("No Cabinet Photo Available")
                DispatchQueue.main.async {
                    self.imageChooser.isHidden = true
                }
                self.getBoardPhotoIfNeeded()
            }
        }
    }
    
    func hasEmptyImageStrings() -> Bool {
        if viewedGame.pcbPhotoURLString == "" || viewedGame.cabinetImageURLString == "" {
            return true
        } else {
            return false
        }
    }
    
    func hasNoAvailableImages() -> Bool { // should this just be a variable?
        if viewedGame.pcbPhotoURLString == "" && viewedGame.cabinetImageURLString == "" {
            return true
        } else {
            return false
        }
    }
    
    func getBoardPhotoIfNeeded () {
        
        if let boardPhotoData = viewedGame.pcbImageData {
            setImage(image: UIImage(data: boardPhotoData)!)
           // mainImageView.image = UIImage(data: boardPhotoData)
        } else {
            if viewedGame.pcbPhotoURLString != "" {
                handleActivityIndicator(indicator: activityIndicator, vc: self, show: true)
                DispatchQueue.global().async { // necessary?
                    let inputString = self.viewedGame.romSetName!
                    let urlString = ("http://adb.arcadeitalia.net/media/mame.current/pcbs/" + inputString + ".png")
                    let url = URL(string: urlString)!
                    
                    guard let data = try? Data(contentsOf: url) else {
                        print("PCB Photo download failure.")
                        self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                        DispatchQueue.main.async {
                            self.viewedGame.pcbPhotoURLString = ""
                            self.imageChooser.isHidden = true
                            
                            if self.hasNoAvailableImages() {
                              //  self.mainImageView.image = UIImage(named: "noHardwareDefaultImage")
                                self.setImage(image: UIImage(named: "noHardwareDefaultImage")!)
                             //   self.mainImageView.heightAnchor.constraint(equalToConstant: 0).isActive = true
                            }
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        self.viewedGame.pcbPhotoURLString = urlString
                        self.viewedGame.pcbImageData = data
                        try? self.dataController.viewContext.save()
                        self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                        
                        self.setImage(image: UIImage(data: data)!)
                        //self.mainImageView.image = UIImage(data: data)
                    }
                }
            } else {
                self.imageChooser.isHidden = true
                print("no PCB image available")
                if hasNoAvailableImages() {
                    setImage(image: UIImage(named: "noHardwareDefaultImage")!)
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
    
    /// Unused because orientation now included in JSON
    func determineOrientation() {

        if displayDictionary!["rotate"] == "90"  {
            viewedGame.orientation = "Vertical"
        }
        else if displayDictionary!["rotate"] == "270"{
            viewedGame.orientation = "Vertical"
        }
        else {
            viewedGame.orientation = "Horizontal"
        }
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
        
        if assetData.length >= 1024 //only check if bigger
        {
            var pdfBytes = [UInt8]()
            pdfBytes = [0x25, 0x50, 0x44, 0x46]
            let pdfHeader = NSData(bytes: pdfBytes, length: 4)
            let a = NSData(data: assetData as Data).range(of: pdfHeader as Data, options: .anchored, in: NSMakeRange(0, 1024))
            if (a.length) > 0
            {
                isPDF = true
            }
            else
            {
                isPDF = false
            }
        }
    }
    
    func getManualIfNeeded() {
        if let manual = viewedGame.manual {
            segueToManualViewController(manualData: manual)
        } else {
            
            if viewedGame.manualURLString == nil {
                
                handleActivityIndicator(indicator: activityIndicator, vc: self, show: true)
                
                //  DispatchQueue.global().async {
                let urlString = String("http://adb.arcadeitalia.net/download_file.php?tipo=mame_current&codice=" + self.viewedGame.romSetName! + "&entity=manual")
                let url = URL(string: urlString)!
                
                guard let data = try? Data(contentsOf: url) else {
                    print("manual download failure.")
                    DispatchQueue.main.async {
                        self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                        self.manualButton.isEnabled = false
                        self.manualButton.isHidden = true
                        self.viewedGame.manualURLString = ""
                        try? self.dataController.viewContext.save()
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.checkForRealPDF(assetData: NSData(data: data))
                    if !self.isPDF {
                        self.viewedGame.manualURLString = ""
                        self.viewedGame.manual = nil
                        self.manualButton.isEnabled = false
                        self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                        try? self.dataController.viewContext.save()
                        return
                    }
                        
                    else {
                        DispatchQueue.main.async {
                            self.viewedGame.manual = data
                            try? self.dataController.viewContext.save()
                            self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
                            self.segueToManualViewController(manualData: data)
                        }
                    }
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
                return "VGA+"
            }
        }
        else { return "Horizontal Refresh Unknown" }
    }
}

