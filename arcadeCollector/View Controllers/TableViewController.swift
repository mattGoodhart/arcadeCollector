//
//  TableViewController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 5/11/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

protocol FilterSelectionDelegate: AnyObject {
    func didSelect(filter: String, filterOptionString: String)
    func didFinish()
}

enum Tab: Int {
    case myGames = 1
    case allGames = 2
    case wanted = 3
    
    var shouldRefresh: Bool {
        switch self {
        case .myGames, .wanted:
            return true
        default:
            return false
        }
    }
    
    var baseGamesList: [Game] {
        switch self {
        case .myGames:
            return CollectionManager.shared.myGames
        case .allGames:
            return CollectionManager.shared.allGames
        case .wanted:
            return CollectionManager.shared.wantedGames
        }
    }
}

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating, FilterSelectionDelegate {

    @IBOutlet weak var reverseButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let searchController = UISearchController(searchResultsController: nil)
    let dataController = DataController.shared
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let tableColor1 = UIColor(displayP3Red: 0.45, green: 0.62, blue: 0.5, alpha: 1.0)
    let tableColor2 = UIColor(displayP3Red: 25.0/255.0, green: 100.0/255.0, blue: 100.0/255.0, alpha: 1.0)
    
    
    var reverseActive = false
    var popUpViewController: FilterOptionsPopup!
    var filterOptionSelected = "orientation"
    var filterOptionString = ""
    var filteredUniqueYears: [String] = []
    var groups = [String: [Game]]()
    var doubleFilteredYears: [String] = []
    var filterOptionedUniqueYears = [String]()
    var doubleFilteredGames = [Game]()
    var filterOptionedGames = [Game]()
    var arrayOfUniqueYears = [String]()
    var gamesList = [Game]()
    var viewedGame: Game!
    var filteredGames: [Game] = []
    var tab: Tab!
    
    var visibleGamesList: [Game] {
        switch (isFiltering, isFilterOptionChosen) {
        case (false, false):
            return gamesList
        case (true, false):
            return filteredGames
        case (false, true):
            return filterOptionedGames
        case (true, true):
            return doubleFilteredGames
        }
    }
    
    var visibleUniqueYears : [String] {
       
        var uniqueYears: [String] {
            switch (isFiltering, isFilterOptionChosen) {
            case (false, false):
                return arrayOfUniqueYears
            case (true, false):
                return filteredUniqueYears
            case (false, true):
                return filterOptionedUniqueYears
            case (true, true):
                return doubleFilteredYears
            }
        }
        guard reverseActive else {
            return uniqueYears
        }
        return uniqueYears.sorted(by: >)
    }

    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
        return (searchController.isActive && !isSearchBarEmpty)
    }
    
    var isFilterOptionChosen: Bool {
        if filterOptionString == "" {
            return false
        } else {
            return true
        }
    }

    //MARK Life Cycle and Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.frame = view.frame
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sectionIndexColor = UIColor.white
        tableView.sectionIndexBackgroundColor = UIColor.init(red: 0.45, green: 0.62, blue: 0.5, alpha: 1)
        searchController.searchResultsUpdater = self as UISearchResultsUpdating
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for Game by Title"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        refreshDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        appDelegate.allowedOrientations = .portrait
        refreshCollectionIfNeeded()
        handleActivityIndicator(indicator: activityIndicator, vc: self, show: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GamesDetailSegue" {
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.viewedGame = viewedGame
        }
    }
 
    //MARK: Actions
    
    @IBAction func reverseButtonTapped(_ sender: UIButton) {
        guard visibleGamesList.count != 0 else {return}
        reverseActive.toggle()
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableView.ScrollPosition.top, animated: false)
    }

    @IBAction func filterButtonTapped(_ sender: UIButton) {
        guard visibleGamesList.count != 0 else {return}
        if let popOver = popUpViewController {
            handleButtons(enabled: false, button: filterButton)
            present(popOver, animated: true, completion: nil)
        } else {
            popUpViewController = storyboard!.instantiateViewController(withIdentifier: "FilterOptionsPopup") as? FilterOptionsPopup
            popUpViewController.delegate = self
            popUpViewController.gamesList = gamesList
            popUpViewController.modalPresentationStyle = .overCurrentContext
            popUpViewController.modalTransitionStyle = .crossDissolve
            
            handleButtons(enabled: false, button: filterButton)
            
            present(popUpViewController, animated: true, completion: nil)
        }
    }
    
    func refreshData() {
        handleActivityIndicator(indicator: activityIndicator, vc: self, show: true)
        
        self.refreshDataSource()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
            
        }
    }
    
    func refreshDataSourceIfFilterOptionSet() {
//        guard isFilterOptionChosen else {
//            return
//        }
        
        switch filterOptionSelected {
        case "orientation":
            filterOptionedGames = gamesList.filter { (game: Game) -> Bool in
                return game.orientation!.lowercased() == filterOptionString.lowercased()
            }
        case "players":
            filterOptionedGames = gamesList.filter { (game: Game) -> Bool in
                return game.players!.lowercased().contains(filterOptionString.lowercased())
            }
        case "manufacturer":
            filterOptionedGames = gamesList.filter { (game: Game) -> Bool in
                return game.manufacturer!.lowercased().contains(filterOptionString.lowercased())
            }
        default: // This handles the case if the filter option is removed
            break
        }
        refreshData()
    }
    
    func createArrayOfUniqueYears(listOfGames: [Game]) -> [String] {
        var uniqueYears = [String]()
        for game in listOfGames {
            uniqueYears += [game.year!]
        }
        var uniqueYearsArray = Array(Set(uniqueYears))
        uniqueYearsArray.sort()
        return uniqueYearsArray
    }
    
    func createUniqueYearArrayForFilterConditions() {
        
            switch (isFiltering, isFilterOptionChosen) {
            case (false, false):
                arrayOfUniqueYears = createArrayOfUniqueYears(listOfGames: visibleGamesList)
            case (true, false):
                filteredUniqueYears = createArrayOfUniqueYears(listOfGames: visibleGamesList)
            case (false, true):
                 filterOptionedUniqueYears = createArrayOfUniqueYears(listOfGames: visibleGamesList)
            case (true, true):
                doubleFilteredYears = createArrayOfUniqueYears(listOfGames: visibleGamesList)
            }
    }
    
    func refreshDataSource() {
        gamesList = tab.baseGamesList
        createUniqueYearArrayForFilterConditions()
        groups = Dictionary(grouping: visibleGamesList.sorted { $0.title! < $1.title! }, by :{ $0.year! })
    }
    
    private func refreshCollectionIfNeeded() {
        guard tab.shouldRefresh else {
            return
        }
        
        let gamesSet = Set(gamesList)
        let baseGamesSet = Set(tab.baseGamesList)
        guard gamesSet != baseGamesSet else {
            print("No refresh needed")
            return
        }
        print("Refreshing list")
        refreshData()
    }
    
    // MARK UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
    
    func filterContentForSearchText(_ searchText: String) {
        if !isFilterOptionChosen {
            filteredGames = gamesList.filter { (game: Game) -> Bool in
                return game.title!.lowercased().contains(searchText.lowercased())
            }
        } else {
            doubleFilteredGames = filterOptionedGames.filter { (game: Game) -> Bool in
                return game.title!.lowercased().contains(searchText.lowercased())
            }
        }
        
        handleActivityIndicator(indicator: activityIndicator, vc: self, show: true)
        refreshDataSource()
        tableView.reloadData()
        handleActivityIndicator(indicator: activityIndicator, vc: self, show: false)
    }
    
    // MARK TableViewDelegate
    
    /// Prevents the deleting of rows when viewing allGames on TableVC
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard tabBarController?.selectedIndex != Tab.allGames.rawValue else {
            return false
        }
        return true
    }
    
    /// Removes game from myGames or wantedGames with delete gesture
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let section = visibleUniqueYears[indexPath.section]
        var group = groups[section]!
        let game = group[indexPath.row]
        
        guard editingStyle == .delete else {
            return
        }
        
        if tabBarController?.selectedIndex == Tab.myGames.rawValue {
            let removalIndex = CollectionManager.shared.myGames.firstIndex(of: game)
            CollectionManager.shared.myGames.remove(at: removalIndex!)
            CollectionManager.shared.myGamesCollection.removeFromGames(game)
        } else if tabBarController?.selectedIndex == Tab.wanted.rawValue {
            let removalIndex = CollectionManager.shared.wantedGames.firstIndex(of: game)
            CollectionManager.shared.wantedGames.remove(at: removalIndex!)
            CollectionManager.shared.wantedGamesCollection.removeFromGames(game)
        }

        try? dataController.viewContext.save()
        refreshDataSource()
        
        if group.count == 1 {
            tableView.deleteSections([indexPath.section], with: .fade)
        } else {
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if visibleGamesList.isEmpty && tabBarController?.selectedIndex == 1 {
            let label = UILabel()
            label.text = "No Games in Collection Yet!"
            label.textAlignment = .center
            tableView.backgroundView = label
            tableView.separatorStyle = .none
            return 0
        }
        else if visibleGamesList.isEmpty && tabBarController?.selectedIndex == 3 {
            let label = UILabel()
            label.text = "No Wanted Games!"
            label.textAlignment = .center
            tableView.backgroundView = label
            tableView.separatorStyle = .none
            return 0
        }
        else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            return visibleUniqueYears.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //(view as! UITableViewHeaderFooterView).textLabel?.textColor = tableColor1
        return visibleUniqueYears[section]
        }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        //(view as! UITableViewHeaderFooterView).contentView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = tableColor2
    }
    /// Right-side scroll index for allGames
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard tabBarController?.selectedIndex == Tab.allGames.rawValue else {
            return nil
        }
        return visibleUniqueYears
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let year = visibleUniqueYears[section]
        let groupSection = groups[year]
        return groupSection!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameTableCell", for: indexPath) as! GameTableCell
        cell.backgroundColor = indexPath.row % 2 == 0 ? tableColor1 : tableColor2
        
        let section = visibleUniqueYears[indexPath.section]
        var group = groups[section]!
        let game = group[indexPath.row]
        if let name = game.romSetName, let dataAsset = NSDataAsset(name: "icons/\(name)") {
            let iconImage = UIImage(data: dataAsset.data)
            cell.iconImageView.image = iconImage
        }
        cell.titleText.text = game.title
        cell.detailtext.text = (game.manufacturer ?? "Unknown") + ", " + (game.year ?? "????")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = visibleUniqueYears[indexPath.section]
        viewedGame = groups[section]![indexPath.row]
        performSegue(withIdentifier: "GamesDetailSegue", sender: self)
    }
    
    // MARK: - FilterSelectionDelegate
    
    func didSelect(filter: String, filterOptionString: String) {
        filterOptionSelected = filter
        self.filterOptionString = filterOptionString
        refreshDataSourceIfFilterOptionSet()
    }
    
    func didFinish() {
        handleButtons(enabled: true, button: filterButton)
    }
}
