//
//  Extensions.swift
//  arcadeCollector
//
//  Created by TrixxMac on 5/4/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

extension TableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
    
    func filterContentForSearchText(_ searchText: String) {
        filteredGames = gamesList.filter { (game: Game) -> Bool in
            return game.title!.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
}

extension UIViewController {
    func handleActivityIndicator(indicator: UIActivityIndicatorView, vc: UIViewController, show: Bool) {
        if show {
            _ = indicator
            DispatchQueue.main.async {
                indicator.bringSubviewToFront(vc.view)
                indicator.center = vc.view.center
                indicator.isHidden = false // could also set hidesWhenStopped to true
                indicator.startAnimating()
            }
        } else {
            _ = indicator
            DispatchQueue.main.async {
                indicator.sendSubviewToBack(vc.view)
                indicator.isHidden = true
                indicator.stopAnimating()
            }
        }
    }
    
    func handleButtons(enabled: Bool, button: UIButton) {
        if enabled {
            DispatchQueue.main.async {
                button.isEnabled = true
                button.alpha = 1.0
            }
        } else {
            DispatchQueue.main.async {
                button.isEnabled = false
                button.alpha = 0.5
            }
        }
    }
//
//    func showAnimate(viewController: UIViewController) {
//        viewController.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
//        viewController.view.alpha = 0.0;
//        UIView.animate(withDuration: 0.25, animations: {
//            viewController.view.alpha = 1.0
//            viewController.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
//        })
//    }
//
//    func removeAnimate(viewController: UIViewController) {
//        UIView.animate(withDuration: 0.25, animations: {
//            viewController.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
//            viewController.view.alpha = 0.0
//        }, completion:{(finished : Bool)  in
//            if (finished)
//            {
//                viewController.view.removeFromSuperview()
//            }
//        })
//    }
}

extension HardwareViewController {
    
    func parserDidStartDocument(_ parser: XMLParser) {
        chipResults = [[:]]
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == "machine" {
            machineDictionary = [:]
            if let sourcefile = attributeDict["sourcefile"] {
                machineDictionary!["driver"] = sourcefile
            }
        }
            
        else if elementName == "chip" {
            
            chipDictionary = [:]
            
            if let type = attributeDict["type"] {
                chipDictionary!["type"] = type
            }
            if let tag = attributeDict["tag"] {
                chipDictionary!["tag"] = tag
            }
            if let name = attributeDict["name"] {
                chipDictionary!["name"] = name
            }
            if let clock = attributeDict["clock"] {
                chipDictionary!["clock"] = clock
            }
        }
            
        else if elementName == "display" {
            
            displayDictionary = [:]
            
            if let type = attributeDict["type"]{
                displayDictionary!["type"] = type
            }
            if let rotate = attributeDict["rotate"] {
                displayDictionary!["rotate"] = rotate
            }
            if let width = attributeDict["width"] {
                displayDictionary!["width"] = width
            }
            if let height = attributeDict["height"] {
                displayDictionary!["height"] = height
            }
            if let refresh = attributeDict["refresh"] {
                displayDictionary!["refresh"] = refresh
            }
            if let vtotal = attributeDict["vtotal"]{
                displayDictionary!["vtotal"] = vtotal
            }
        }
                
        else if elementName == "sound" {
            
            if let channels = attributeDict["channels"]{
              soundChannels = "Audio Channels: \(channels)"
            }
        }
            
        else if machineElementKeys.contains(elementName) {
            currentValue = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue? += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "machine" {
            
            //            print(chipResults as Any)
        }
        else if elementName == "chip" {
            chipResults!.append(chipDictionary!)
            chipDictionary = nil
        }
            
        else if machineElementKeys.contains(elementName) {
            machineDictionary![elementName] = currentValue
            currentValue = nil
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError)
        currentValue = nil
        machineDictionary = nil
        chipResults = nil
    }
    
    func parseHardwareData() {
        
        for chip in chipResults! {
            if chip["type"] == "cpu" {
                if chip["tag"] == "maincpu" {
                    cpuStringArray += ["Main CPU: " + "\(chip["name"] ?? ""), " + "\(chip["clock"] ?? "")"]
                } else if chip["tag"] == "audiocpu" {
                    cpuStringArray += ["Audio CPU: " + "\(chip["name"] ?? ""), " + "\(chip["clock"] ?? "")"]
                } else {
                    cpuStringArray += ["\(chip["tag"] ?? ""): " + "\(chip["name"] ?? ""), " + "\(chip["clock"] ?? "")"]
                }
            }
            else if (chip["type"] == "audio") && chip["name"] != "Speaker" {
                soundDeviceStringArray += ["\(chip["tag"] ?? "")" + ":" + "\(chip["name"] ?? ""), " + "\(chip["clock"] ?? "")"]
            }
        }
        
        for cpuString in cpuStringArray { // these two loops can be refactored into a single method
            let split = cpuString.split(separator: " ")
            let poorlyFormattedClock = String(split.suffix(1).joined(separator: [" "]))
            
            if let poorlyFormattedClockDouble = (Double(poorlyFormattedClock)) {
                let adjust = Double(poorlyFormattedClockDouble / 1000000)
                let rounded = Double(round(100 * adjust)/100)
                let replacementClockString = String(rounded)  + " MHz"
    
                let goodCPUString = cpuString.replacingOccurrences(of: poorlyFormattedClock, with: replacementClockString)
                formattedCPUStringArray += [goodCPUString]
            } else {
                formattedCPUStringArray += [cpuString]
            }
        }
        
        for soundString in soundDeviceStringArray {
            let split = soundString.split(separator: " ")
            let poorlyFormattedClock = String(split.suffix(1).joined(separator: [" "]))
            
            if let poorlyFormattedClockDouble = (Double(poorlyFormattedClock)) {
                let adjust = Double(poorlyFormattedClockDouble / 1000000)
                let rounded = Double(round(100 * adjust)/100)
                let replacementClockString = String(rounded)  + " MHz"
                let goodSoundString = soundString.replacingOccurrences(of: poorlyFormattedClock, with: replacementClockString)
                formattedSoundStringArray += [goodSoundString]
            } else {
                formattedSoundStringArray += [soundString]
            }
        }
        viewedGame.cpuStringArray = formattedCPUStringArray
        viewedGame.soundDeviceStringArray = formattedSoundStringArray
        try? dataController.viewContext.save()
    }
}

extension UIView {
    public func removeAllConstraints() {
        var _superview = self.superview
        while let superview = _superview {
            for constraint in superview.constraints {
                if let first = constraint.firstItem as? UIView, first == self {
                    superview.removeConstraint(constraint)
                }
                if let second = constraint.secondItem as? UIView, second == self {
                    superview.removeConstraint(constraint)
                }
            }
            _superview = superview.superview
        }
        self.removeConstraints(self.constraints)
        self.translatesAutoresizingMaskIntoConstraints = true
    }
}









