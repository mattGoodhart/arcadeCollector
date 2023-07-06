//
//  HardwareViewControllerExtension.swift
//  arcadeCollector
//
//  Created by TrixxMac on 7/5/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

extension HardwareViewController {

    // MARK: - XML Parser

    func parserDidStartDocument(_ parser: XMLParser) {
        chipResults = [[:]]
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {

        if elementName == "machine" {
            machineDictionary = [:]
            if let sourcefile = attributeDict["sourcefile"] {
                machineDictionary!["driver"] = sourcefile
            }
        } else if elementName == "chip" {
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
        } else if elementName == "display" {
            displayDictionary = [:]

            if let type = attributeDict["type"] {
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
            if let vtotal = attributeDict["vtotal"] {
                displayDictionary!["vtotal"] = vtotal
            }
        } else if elementName == "sound", let channels = attributeDict["channels"] {
            soundChannels = "Audio Channels: \(channels)"
        } else if machineElementKeys.contains(elementName) {
            currentValue = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue? += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "chip" {
            chipResults!.append(chipDictionary!)
            chipDictionary = nil
        }

        if machineElementKeys.contains(elementName) {
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
        guard let results = chipResults else {
            return
        }

        for chip in results {
            if chip["type"] == "cpu" {
                if chip["tag"] == "maincpu" {
                    cpuStringArray += ["Main CPU: " + "\(chip["name"] ?? ""), " + "\(chip["clock"] ?? "")"]
                } else if chip["tag"] == "audiocpu" {
                    cpuStringArray += ["Audio CPU: " + "\(chip["name"] ?? ""), " + "\(chip["clock"] ?? "")"]
                } else {
                    cpuStringArray += ["\(chip["name"] ?? ""), " + "\(chip["clock"] ?? "")"]
                }
            } else if (chip["type"] == "audio") && chip["name"] != "Speaker" && (chip["clock"] != nil) {
                soundDeviceStringArray += ["\(chip["name"] ?? ""), " + "\(chip["clock"] ?? "")"] // remove comma for case where device has no clock

            } else if (chip["type"] == "audio") && chip["name"] != "Speaker"{
                soundDeviceStringArray += ["\(chip["name"] ?? "")"]
            }
        }

        for cpuString in cpuStringArray {
            improveClockFormatting(stringToProcess: cpuString, isForCPU: true)
        }
            for soundString in soundDeviceStringArray {
                improveClockFormatting(stringToProcess: soundString, isForCPU: false)
        }
            viewedGame.cpuStringArray = formattedCPUStringArray
            viewedGame.soundDeviceStringArray = formattedSoundStringArray
            try? dataController.viewContext.save()
        }

    func improveClockFormatting(stringToProcess: String, isForCPU: Bool) {

        var formattedStringArray = [String]()

        let split = stringToProcess.split(separator: " ")
        let poorlyFormattedClock = String(split.suffix(1).joined(separator: [" "]))

        if let poorlyFormattedClockDouble = (Double(poorlyFormattedClock)) {
            let adjust = Double(poorlyFormattedClockDouble / 1000000)
            let rounded = Double(round(100 * adjust)/100)
            let replacementClockString = String(rounded)  + " MHz"

            let goodString = stringToProcess.replacingOccurrences(of: poorlyFormattedClock, with: replacementClockString)
            formattedStringArray += [goodString]
        } else {
            formattedStringArray += [stringToProcess]
        }
        if isForCPU {
            formattedCPUStringArray += formattedStringArray
        } else {
            formattedSoundStringArray += formattedStringArray
        }
    }
}
