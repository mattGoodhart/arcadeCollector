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
    var filteredUniqueYears = [String]()
    var segmentOfGames = [Game]()
    var groups = [String : [Game]]()
    let searchController = UISearchController(searchResultsController: nil)
    let dataController = DataController.shared

    var arrayOfUniqueYears = [String]()
    var gamesList = [Game]()
    var viewedGame : Game!
    var filteredGames : [Game] = []
    var tab: Tab!
    var reverseActive : Bool = false
    
    var visibleGamesList: [Game] {
       return isFiltering ? filteredGames : gamesList
    }
    
    var visibleUniqueYears : [String] {
        let filtered = isFiltering ? filteredUniqueYears : arrayOfUniqueYears
        guard reverseActive else {
            return filtered
        }
        return filtered.sorted(by: >)
    }
    
//    var sortedUniqueYears: [String] {
//        guard reverseActive else {
//            return arrayOfUniqueYears
//        }
//        return arrayOfUniqueYears.sorted(by: >)
//    }
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
  
    @IBOutlet weak var reverseButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.frame = view.frame
        tableView.dataSource = self
        tableView.delegate = self
        searchController.searchResultsUpdater = self as UISearchResultsUpdating
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for Game by Title"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        refreshDataSource()
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
        reverseActive.toggle()
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableView.ScrollPosition.top, animated: false)
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
    
    func makeGroupsIfFiltered(gamesList: [Game]) -> [String : [Game]]  {
        guard isFiltering else {
            return groups
        }
        let newGroups = Dictionary(grouping: gamesList.sorted { $0.title! < $1.title! }, by :{ $0.year! })
        return newGroups
    }
    
    func refreshDataSource() {
        gamesList = tab.baseGamesList
        
        if !isFiltering {
            arrayOfUniqueYears = createArrayOfUniqueYears(listOfGames: visibleGamesList)}
        else {
             filteredUniqueYears = createArrayOfUniqueYears(listOfGames: visibleGamesList)
        }
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
        refreshDataSource()
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
        // shit do i have to call refreshDataSource here?
        refreshDataSource()
        tableView.reloadData()
    }
    
    // MARK TableViewDelegate
    
    /// Prevents the deleting of rows when viewing allGames on TableVC
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        guard tabBarController?.selectedIndex != 2 else {
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
        
        if tabBarController?.selectedIndex == 1 { //mygames
            let removalIndex = CollectionManager.shared.myGames.firstIndex(of: game)
            CollectionManager.shared.myGames.remove(at: removalIndex!)
            CollectionManager.shared.myGamesCollection.removeFromGames(game)
            
        } else if tabBarController?.selectedIndex == 3 {
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
        return visibleUniqueYears.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return visibleUniqueYears[section]
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard tabBarController?.selectedIndex == 2 else {
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
}
