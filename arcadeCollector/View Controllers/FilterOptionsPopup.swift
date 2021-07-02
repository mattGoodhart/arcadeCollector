//
//  FilterOptionsPopup.swift
//  arcadeCollector
//
//  Created by TrixxMac on 6/28/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

class FilterOptionsPopup: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    weak var delegate: FilterSelectionDelegate?
    
    //weak var presentingViewController: UIViewController?
    
    var hasActiveFilter: Bool! = false
    var gamesList: [Game]!
    var stringArrayForPicker = [String]()
    var arrayOfUniqueOrientations: [String]!
    var arrayOfUniquePlayerCounts: [String]!
    var arrayOfUniqueManufacturers: [String]!
    
    @IBOutlet weak var optionsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var removeFilterButton: UIButton!
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var pickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arrayOfUniqueOrientations = createArrayOfUniqueOrientations()
        arrayOfUniquePlayerCounts = createArrayOfUniquePlayerCounts()
        arrayOfUniqueManufacturers = createArrayOfUniqueManufacturers()
        
        pickerView.delegate = self //this is horseshit.... finding nil..
        pickerView.dataSource = self
        optionsSegmentedControl.selectedSegmentIndex = 0
        stringArrayForPicker = arrayOfUniqueOrientations
        buildMainView()
        //checkForActiveFilterOption()
        navigationController?.navigationBar.popItem(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(true)
        checkForActiveFilterOption()
    }
    
    @IBAction func removeFilterButtonPressed(_ sender: UIButton) {
        delegate?.didFinish()
        delegate?.didSelect(filter: "", filterOptionString: "")
        hasActiveFilter = false
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
      
        delegate?.didFinish()
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func applyButtonPressed(_ sender: UIButton) {
        var filterOptionChosen = ""
        var filterOptionString = ""
        
        switch optionsSegmentedControl.selectedSegmentIndex {
        case 0: filterOptionChosen = "orientation"
        case 1: filterOptionChosen = "players"
        case 2: filterOptionChosen = "manufacturer"
        default: break;
        }
        
        let row = pickerView.selectedRow(inComponent: 0)
        filterOptionString = stringArrayForPicker[row]
        delegate?.didSelect(filter: filterOptionChosen, filterOptionString: filterOptionString)
       delegate?.didFinish()
        hasActiveFilter = true
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func segmentedControlPressed(_sender: UISegmentedControl){

        switch optionsSegmentedControl.selectedSegmentIndex {
        case 0: stringArrayForPicker = arrayOfUniqueOrientations
        case 1: stringArrayForPicker = arrayOfUniquePlayerCounts
        case 2: stringArrayForPicker = arrayOfUniqueManufacturers
        default: break;
        }
        
        DispatchQueue.main.async {
            self.pickerView.reloadAllComponents()
        }
    }
    
    func checkForActiveFilterOption() {
        if !hasActiveFilter {
           // handleButtons(enabled: false, button: removeFilterButton)
            //stackView.viewWithTag(4)?.removeAllConstraints()
            //stackView.removeArrangedSubview(removeFilterButton)
       // } else {
           // stackView.removeAllConstraints()
            //stackView.subviews.forEach({ $0.removeFromSuperview() })
            //buildStackView()
           // handleButtons(enabled: true, button: removeFilterButton)
           // stackView.removeArrangedSubview(removeFilterButton)
            stackView.arrangedSubviews[4].isHidden = true
            
        } else {
            stackView.arrangedSubviews[4].isHidden = false
           // stackView.removeAllConstraints()
           // setStackViewConstraints()
        }
            //removeFilterButton.bottomAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
    }
    
    func buildMainView() {
        view.backgroundColor = .gray
        view.alpha = 0.5 // why cant i see tableview underneath?
        
       
        view.addSubview(contentView)
        setContentView()
        contentView.addSubview(stackView)
        buildStackView()
    }
    
    func setContentView() {
      
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .white
        //contentView.layer.cornerRadius = 24
        
        contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75).isActive = true
        contentView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true
        
        }
    
    func buildStackView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        setStackViewConstraints()
        
        
//        if hasActiveFilter {
//            if let button = removeFilterButton {
//                stackView.addArrangedSubview(button)
//            } else {
//
//                stackView.addSubview(removeFilterButton)
//                stackView.addArrangedSubview(removeFilterButton)
//            }
//        } else {
//            removeFilterButton.removeFromSuperview()
//        }
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = 0
        
        stackView.addArrangedSubview(optionsSegmentedControl)
        stackView.addArrangedSubview(pickerView)
        stackView.addArrangedSubview(applyButton)
        stackView.addArrangedSubview(cancelButton)
        stackView.addArrangedSubview(removeFilterButton)
        
       
    }
    
    func setStackViewConstraints() {
        stackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        stackView.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
        
//        pickerView.centerXAnchor.constraint(equalTo: stackView.centerXAnchor).isActive = true
//        pickerView.centerYAnchor.constraint(equalTo: stackView.centerYAnchor).isActive = true
//
//        optionsSegmentedControl.topAnchor.constraint(equalTo: stackView.topAnchor).isActive = true
//
//        removeFilterButton.bottomAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
    }
    
    // these need to be refactored.
    func createArrayOfUniqueManufacturers() -> [String] {
        var uniqueManufacturers = [String]()
        for game in gamesList {
            uniqueManufacturers += [game.manufacturer!]
        }
        var uniqueManufacturersArray = Array(Set(uniqueManufacturers))
        uniqueManufacturersArray.sort()
        return uniqueManufacturersArray
    }
    
    func createArrayOfUniqueOrientations() -> [String] {
        var uniqueOrientations = [String]()
        for game in gamesList {
            uniqueOrientations += [game.orientation!]
        }
        var uniqueOrientationsArray = Array(Set(uniqueOrientations))
        uniqueOrientationsArray.sort()
        return uniqueOrientationsArray
    }
    
    func createArrayOfUniquePlayerCounts() -> [String] {
        var uniquePlayerCounts = [String]()
        for game in gamesList {
            uniquePlayerCounts += [game.players!]
        }
        var uniquePlayerCountsArray = Array(Set(uniquePlayerCounts))
        uniquePlayerCountsArray.sort()
        return uniquePlayerCountsArray
    }
    
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
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return stringArrayForPicker.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return stringArrayForPicker[row]
    }
}
