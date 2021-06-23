//
//  TableViewController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 5/11/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

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

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating {

    //MARK: Properties
    var segmentOfGames : [Game]!
    var groups : [String : [Game]]!
    let searchController = UISearchController(searchResultsController: nil)
    let dataController = DataController.shared

    var arrayOfUniqueYears : [String]!
    var gamesList = [Game]()
    var viewedGame : Game!
    var filteredGames : [Game] = []
    var tab: Tab!
    var reverseActive : Bool = false
    
    var visibleGamesList: [Game]! {
       return isFiltering ? filteredGames : gamesList
    }
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
  
    @IBOutlet weak var reverseButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!
    
    
    //MARK Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.frame = view.frame
        tableView.dataSource = self
        tableView.delegate = self
        gamesList = tab.baseGamesList
        searchController.searchResultsUpdater = self as UISearchResultsUpdating
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for Game by Title"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
      arrayOfUniqueYears = createArrayOfUniqueYears()
        groups = Dictionary(grouping: gamesList.sorted { $0.title! < $1.title! }, by :{ $0.year! })
        sortByYear()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        refreshCollectionIfNeeded()
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GamesDetailSegue" {
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.viewedGame = viewedGame
        }
    }
    
    @IBAction func reverseButtonTapped(_ sender: UIButton) {
        reverseActive = !reverseActive
        sortByYear()
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableView.ScrollPosition.top, animated: false)
    }
    
    func createArrayOfUniqueYears() -> [String] {
        var uniqueYears = [String]()
        for game in visibleGamesList {
            uniqueYears += [game.year!]
        }
        var uniqueYearsArray = Array(Set(uniqueYears))
        uniqueYearsArray.sort()
        return uniqueYearsArray
    }
    
    func getUniqueYearsIfNeeded() -> [String] {
        guard arrayOfUniqueYears != nil, isFiltering else {return arrayOfUniqueYears}
        return createArrayOfUniqueYears()
    }
    
    func makeGroupsIfNeeded(gamesList: [Game]) -> [String : [Game]]  {
        guard isFiltering else {return groups}
        let newGroups = Dictionary(grouping: gamesList.sorted { $0.title! < $1.title! }, by :{ $0.year! })
        return newGroups
    }
    
    func sortByYear() {
        if !reverseActive {
            var uniqueYears = getUniqueYearsIfNeeded()
            uniqueYears.sort()
            arrayOfUniqueYears = uniqueYears
        }
        else {
            var uniqueYears = getUniqueYearsIfNeeded()
            uniqueYears.sort(by: >)
            arrayOfUniqueYears = uniqueYears
        }
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
        gamesList = tab.baseGamesList
        sortByYear()
        tableView.reloadData()
    }
    
    // MARK UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
    
    func filterContentForSearchText(_ searchText: String) {
        filteredGames = gamesList.filter { (game: Game) -> Bool in
    return game.title!.lowercased().contains(searchText.lowercased())
        }
       // makeGroups(gamesList: filteredGames)
        tableView.reloadData()
    }
    
    // MARK TableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return getUniqueYearsIfNeeded().count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return getUniqueYearsIfNeeded()[section]
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if tabBarController?.selectedIndex == 2 { return getUniqueYearsIfNeeded()}
        else {return nil}
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let year = getUniqueYearsIfNeeded()[section]
        let groupSection = makeGroupsIfNeeded(gamesList: visibleGamesList)[year]
        return groupSection!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameTableCell", for: indexPath) as! GameTableCell
        let section = getUniqueYearsIfNeeded()[indexPath.section]
        var group = makeGroupsIfNeeded(gamesList: visibleGamesList)[section]!
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
        let section = getUniqueYearsIfNeeded()[indexPath.section]
        viewedGame = makeGroupsIfNeeded(gamesList: visibleGamesList)[section]![indexPath.row]
        performSegue(withIdentifier: "GamesDetailSegue", sender: self)
    }
}
