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

enum SortMethod {
    case name
    case year
    case manufacturer
    case orientation
    case players
}

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    //MARK: Properties
    let searchController = UISearchController(searchResultsController: nil)
    let dataController = DataController.shared

    var gamesList = [Game]()
    var viewedGame : Game!
    var filteredGames : [Game] = []
    var tab: Tab!
    var currentSortMethod: SortMethod = .name
    var reverseActive : Bool = false
    
    var visibleGamesList: [Game] {
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
  //  @IBOutlet weak var sortOptions: UISegmentedControl!
    
    //MARK Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.frame = view.frame
        
//        let font = UIFont.systemFont(ofSize: 12)
//        sortOptions.setTitleTextAttributes([NSAttributedString.Key.font : font], for: .normal)
        
        tableView.dataSource = self
        tableView.delegate = self
        gamesList = tab.baseGamesList
        searchController.searchResultsUpdater = self as UISearchResultsUpdating
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for Game by Title"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        sortByYear()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        refreshCollectionIfnNeeded()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GamesDetailSegue" {
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.viewedGame = viewedGame
        }
    }
    
//    @IBAction func segmentedControlPressed(_sender: UISegmentedControl){
//        switch sortOptions.selectedSegmentIndex {
//        case 0:
//            sortByName()
//
//        case 1:
//            sortByYear()
//
//        default:
//            break;
//        }
//    }

    
//    func sortByName() {
//        gamesList.sort() {
//            let isGreater = $0.title! < $1.title!
//            return isGreater
//        }
//        tableView.reloadData()
//    }
    
    @IBAction func reverseButtonTapped(_ sender: UIButton) {
        reverseActive = !reverseActive
        sortByYear()
    }
    
    func sortByYear() { // I will want to sort by name after this
        gamesList.sort() {
            if $0.year != $1.year {
                if !reverseActive {
                    let isGreater = $0.year! < $1.year!
                    return isGreater
                }
                else {
                    let isLessThan = $0.year! > $1.year!
                    return isLessThan
                }
            }
            else {
                return $0.title! < $1.title!
            }
        }
        tableView.reloadData()
    }
    
    private func refreshCollectionIfnNeeded() {
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
    
    // MARK TableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleGamesList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameTableCell", for: indexPath) as! GameTableCell
    
        let game = visibleGamesList[indexPath.item]
        if let name = game.romSetName, let dataAsset = NSDataAsset(name: "icons/\(name)") {
            let iconImage = UIImage(data: dataAsset.data)
            cell.iconImageView.image = iconImage
        }
        
        cell.titleText.text = visibleGamesList[indexPath.item].title
        cell.detailtext.text = (visibleGamesList[indexPath.item].manufacturer ?? "Jesus") + ", " + (visibleGamesList[indexPath.item].year ?? "0000")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewedGame = visibleGamesList[indexPath.item]
        performSegue(withIdentifier: "GamesDetailSegue", sender: self)
    }
}
