//
//  FilterOptionsPopup.swift
//  arcadeCollector
//
//  Created by TrixxMac on 6/28/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit


enum filterType {
    case players
    case manufacturers
    case orientation
}

class FilterOptionsPopup: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
 
    @IBOutlet weak var optionsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var removeFilterButton: UIButton!
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var pickerView: UIPickerView!

    weak var delegate: FilterSelectionDelegate?
    
    var hasActiveFilter: Bool! = false
    var gamesList: [Game]!
    var stringArrayForPicker: [String] = []
    var arrayOfUniqueOrientations: [String] = []
    var arrayOfUniquePlayerCounts: [String] = []
    var arrayOfUniqueManufacturers: [String] = []
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arrayOfUniqueOrientations = createArrayOfUniqueFilterItems(filterType: .orientation)
        arrayOfUniquePlayerCounts = createArrayOfUniqueFilterItems(filterType: .players)
        arrayOfUniqueManufacturers = createArrayOfUniqueFilterItems(filterType: .manufacturers)
        
        pickerView.delegate = self
        pickerView.dataSource = self
        optionsSegmentedControl.selectedSegmentIndex = 0
        stringArrayForPicker = arrayOfUniqueOrientations
        buildMainView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(true)
        appDelegate.allowedOrientations = .portrait
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
        case 0:
            filterOptionChosen = "orientation"
        case 1:
            filterOptionChosen = "players"
        case 2:
            filterOptionChosen = "manufacturer"
        default:
            break
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
        case 0:
            stringArrayForPicker = arrayOfUniqueOrientations
        case 1:
            stringArrayForPicker = arrayOfUniquePlayerCounts
        case 2:
            stringArrayForPicker = arrayOfUniqueManufacturers
        default:
            break
        }
        DispatchQueue.main.async {
            self.pickerView.reloadAllComponents()
        }
    }
    
    func checkForActiveFilterOption() {
        if !hasActiveFilter {
            stackView.arrangedSubviews[3].isHidden = true
            applyButton.setTitle("Apply", for: .normal)
        } else {
            stackView.arrangedSubviews[3].isHidden = false
            applyButton.setTitle("Apply New Filter", for: .normal)
        }
    }
    
    func buildMainView() {
        view.backgroundColor = .gray
        view.alpha = 0.5
        
        setContentView()
        view.addSubview(contentView)
        
        buildStackView()
        contentView.addSubview(stackView)
    }
    
    func setContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        
        contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75).isActive = true
        contentView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.66).isActive = true
        }
    
    func buildStackView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        setStackViewConstraints()

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.addArrangedSubview(optionsSegmentedControl)
        stackView.addArrangedSubview(pickerView)
        stackView.addArrangedSubview(applyButton)
        stackView.addArrangedSubview(removeFilterButton)
        stackView.addArrangedSubview(cancelButton)
    }
    
    func setStackViewConstraints() {
        stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        stackView.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
    }
    
    func createArrayOfUniqueFilterItems(filterType: filterType) -> [String] {
        
        var items = [String]()
        
        switch filterType {
        case .manufacturers: for game in gamesList {
            items += [game.manufacturer!]
            }
        case .players: for game in gamesList {
            items += [game.players!]
            }
        case .orientation: for game in gamesList {
            items += [game.orientation!]
            }
        }
        
        var uniqueItemsArray = Array(Set(items))
        
        uniqueItemsArray.sort()
        return uniqueItemsArray
    }
    
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
