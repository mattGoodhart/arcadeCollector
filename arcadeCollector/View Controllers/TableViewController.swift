//
//  TableViewController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 5/11/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//


import UIKit


//enum FilterOption {
//    case orientation
//    case players
//    case manufacturer
//}

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

    //MARK: Properties
   // var popOverVC : FilterOptionsPopup!
    let searchController = UISearchController(searchResultsController: nil)
    let dataController = DataController.shared

    var reverseActive = false
    
    var popUpVC: FilterOptionsPopup!
    var filterOptionSelected = "orientation"
    var filterOptionString = ""
    var filteredUniqueYears = [String]()
    var groups = [String : [Game]]()
    var doubleFilteredYears = [String]()
    var filterOptionedUniqueYears = [String]()
    var doubleFilteredGames = [Game]()
    var filterOptionedGames = [Game]()
    var arrayOfUniqueYears = [String]()
    var gamesList = [Game]()
    var viewedGame : Game!
    var filteredGames : [Game] = []
    var tab: Tab!
    
    var visibleGamesList: [Game] {
        
        //base
        if !isFiltering && !isFilterOptionChosen {
            return gamesList
        }
        
    // search filtered list
        else if isFiltering && !isFilterOptionChosen {
            return filteredGames
        }
    //option filtered list
        else if !isFiltering && isFilterOptionChosen {
            return filterOptionedGames
        }
        
    //option list then search filtered  --- or just disable the search bar in this case?
        else if isFiltering && isFilterOptionChosen {
            return doubleFilteredGames
        }
        else {return gamesList}
  //do i need to sort again when using optionFiltered?
       //  return isFiltering ? filteredGames : gamesList
    }
    
    var visibleUniqueYears : [String] { // need 4 versions of this too
        var uniqueYears = [String]()
        
        
        //base
        if !isFiltering && !isFilterOptionChosen { uniqueYears = arrayOfUniqueYears }
        
        //filtered
        else if isFiltering && !isFilterOptionChosen { uniqueYears = filteredUniqueYears }
        
        //optionfiltered
        else if !isFiltering && isFilterOptionChosen { uniqueYears = filterOptionedUniqueYears }
        
        //doublefiltered
        else if isFiltering && isFilterOptionChosen { uniqueYears = doubleFilteredYears }
        
        
        //let uniqueYears = isFiltering ? filteredUniqueYears : arrayOfUniqueYears
        
        
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

    //MARK: Outlets
    
    @IBOutlet weak var reverseButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
     //popOverVC = storyboard!.instantiateViewController(withIdentifier: "FilterOptionsPopup") as! FilterOptionsPopup
        
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
        //refreshDataSourceIfFilterOptionSet()
        //checkIfFilterOptionChosen()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GamesDetailSegue" {
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.viewedGame = viewedGame
        }
    }
    
    //MARK: Actions
    
    @IBAction func reverseButtonTapped(_ sender: UIButton) {
        reverseActive.toggle()
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableView.ScrollPosition.top, animated: false)
    }

    @IBAction func filterButtonTapped(_ sender: UIButton) {
        if let popOver = popUpVC {
            handleButtons(enabled: false, button: filterButton)
            present(popOver, animated: true, completion: nil)
        } else {
            
            popUpVC = storyboard!.instantiateViewController(withIdentifier: "FilterOptionsPopup") as? FilterOptionsPopup
            popUpVC.delegate = self
            popUpVC.gamesList = gamesList
            popUpVC.modalPresentationStyle = .overCurrentContext
            popUpVC.modalTransitionStyle = .crossDissolve
            
            handleButtons(enabled: false, button: filterButton)
            
            present(popUpVC, animated: true, completion: nil)
        }
    }
    
    func refreshDataInBackground() {
        handleActivityIndicator(indicator: activityIndicator, vc: self, show: true)
        
        DispatchQueue.global().async {
            self.refreshDataSource()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.handleActivityIndicator(indicator: self.activityIndicator, vc: self, show: false)
            }
        }
    }
    
    func refreshDataSourceIfFilterOptionSet() {
        if isFilterOptionChosen {
            
            switch filterOptionSelected {
            case "orientation": filterOptionedGames = gamesList.filter { (game: Game) -> Bool in
                return game.orientation!.lowercased() == filterOptionString.lowercased()
                }
            case "players": filterOptionedGames = gamesList.filter { (game: Game) -> Bool in
                return game.players!.lowercased().contains(filterOptionString.lowercased())
                }
            case "manufacturer": filterOptionedGames = gamesList.filter { (game: Game) -> Bool in
                return game.manufacturer!.lowercased().contains(filterOptionString.lowercased())
                }
            default: break;
            }
            
            
            //            refreshDataSource()
            //            tableView.reloadData()
            //        } else {
            //            refreshDataSource()
            //            tableView.reloadData()
            //        }
        }
         refreshDataInBackground()
    }
    
    func createArrayOfUniqueYears(listOfGames: [Game]) -> [String] { // use my array extension?
        var uniqueYears = [String]()
        for game in listOfGames {
            uniqueYears += [game.year!]
        }
        var uniqueYearsArray = Array(Set(uniqueYears))
        uniqueYearsArray.sort()
        return uniqueYearsArray
    }
    
    func refreshDataSource() {
        gamesList = tab.baseGamesList
        
        if !isFiltering && !isFilterOptionChosen {
            arrayOfUniqueYears = createArrayOfUniqueYears(listOfGames: visibleGamesList)
        } else if isFiltering && !isFilterOptionChosen {
             filteredUniqueYears = createArrayOfUniqueYears(listOfGames: visibleGamesList)
        } else if !isFiltering && isFilterOptionChosen {
            filterOptionedUniqueYears = createArrayOfUniqueYears(listOfGames: visibleGamesList)
        } else if isFiltering && isFilterOptionChosen {
            doubleFilteredYears = createArrayOfUniqueYears(listOfGames: visibleGamesList)
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
        refreshDataInBackground()
//        refreshDataSource()
//        tableView.reloadData()
    }
    
    // MARK UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
    
    func filterContentForSearchText(_ searchText: String) {
        //originally used gamesList
        
        if !isFilterOptionChosen {
            filteredGames = gamesList.filter { (game: Game) -> Bool in
                return game.title!.lowercased().contains(searchText.lowercased())
            }
        } else {
            doubleFilteredGames = filterOptionedGames.filter { (game: Game) -> Bool in
                return game.title!.lowercased().contains(searchText.lowercased())
            }
        }
        
        refreshDataInBackground()
//        refreshDataSource()
//        tableView.reloadData()
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
    
    
    // MARK: - FilterSelectionDelegate
    
    func didSelect(filter: String, filterOptionString: String) {
        //apply the results of selecting the filter
        filterOptionSelected = filter
        self.filterOptionString = filterOptionString
        refreshDataSourceIfFilterOptionSet()
    }
    
    func didFinish() {
        handleButtons(enabled: true, button: filterButton)

    }
    
}
