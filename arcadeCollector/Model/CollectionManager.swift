//
//  CollectionManager.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/17/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import CoreData

enum CollectionName: String {
    case allGames = "All Games"
    case myGames = "My Games"
    case wantedGames = "Wanted Games"
}

class CollectionManager {
    
    static let shared = CollectionManager()
    
    let dataController = DataController.shared
    var collections: [CollectionEntity] = []
    var allGamesCollection: CollectionEntity!
    var myGamesCollection: CollectionEntity!
    var wantedGamesCollection: CollectionEntity!
   // var arrayOfUniqueYears: [String] = []
    var allGames: [Game] = []
    var myGames: [Game] = []
    var wantedGames: [Game] = []
    var numberOfWorkingBoards: Int = 0
    var numberOfBootingBoards: Int = 0
    var numberOfNonWorkingBoards: Int = 0
//    var workingBoards: [Game] = []
//    var partiallyWorkingBoards: [Game] = []
//    var nonWorkingBoards: [Game] = []
   // var collectedCabinetHardWare: [Game] = []
    var numberOfBoardsInCollection: Int = 0
  //  var allHardwareInCollection: [Game] = []
    var hardwareCountsDictionary: [String: Double] = [:]
   // var cabinetHardwareCountsDictionary: [String: Double] = [:]
    
    // MARK: - Initialization

    private init() {}
    
    func createCollectionsIfNeeded() {
        if let collections = fetchCollectionsFromCoreData(), !collections.isEmpty {
            self.collections = collections
            load(from: collections)
            fetchGamesForAllCollections()
        } else {
            createCollections()
        }
    }
    
    func createCollections() {
        let allGamesCollection = CollectionEntity(context: dataController.viewContext)
        let myGamesCollection = CollectionEntity(context: dataController.viewContext)
        let wantedGamesCollection = CollectionEntity(context: dataController.viewContext)
        
        allGamesCollection.name = CollectionName.allGames.rawValue
        myGamesCollection.name = CollectionName.myGames.rawValue
        wantedGamesCollection.name = CollectionName.wantedGames.rawValue
        
        self.allGamesCollection = allGamesCollection
        self.myGamesCollection = myGamesCollection
        self.wantedGamesCollection = wantedGamesCollection
        collections = [allGamesCollection, myGamesCollection, wantedGamesCollection]

        try? dataController.viewContext.save()
        initializeAllGames()
    }
    
    private func fetchCollectionsFromCoreData() -> [CollectionEntity]? {
        let fetchRequest: NSFetchRequest<CollectionEntity> = CollectionEntity.fetchRequest()
        let fetchResult = try? dataController.viewContext.fetch(fetchRequest)
        return fetchResult
    }
    
    private func load(from collections: [CollectionEntity]) {
        allGamesCollection = collection(from: collections, with: .allGames)
        myGamesCollection = collection(from: collections, with: .myGames)
        wantedGamesCollection = collection(from: collections, with: .wantedGames)
    }
    
    // MARK: - Parsing
  
    private func readLocalFile(forName name: String) -> Data? {
        do {
            if let bundlePath = Bundle.main.path(forResource: name, ofType: "json"), let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
                return jsonData
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    private func parse(jsonData: Data) {
        do {
            let decodedData = try JSONDecoder().decode(ScrollingDataResult.self,
                                                       from: jsonData)
            for game in decodedData.result {
                let gameEntity = Game(context: dataController.viewContext)
                gameEntity.romSetName = game.romName
                gameEntity.title = game.title
                gameEntity.year = game.year
                gameEntity.manufacturer = game.manufacturer
                gameEntity.players = game.players
                gameEntity.orientation = game.orientation
                gameEntity.hasBezel = false
                gameEntity.hasBoard = false
                gameEntity.hasCabinet = false
                gameEntity.hasCabinetArt = false
                gameEntity.hasCabinetHardware = false
                gameEntity.hasControlPanelOverlay = false
                gameEntity.hasControls = false
                gameEntity.hasMonitorFlag = false
                gameEntity.isBootleg = false
                gameEntity.functionalCondition = 0
                self.allGames.append(gameEntity)
                allGamesCollection.addToGames(gameEntity)
            }
            try dataController.viewContext.save()
        } catch {
            print("scrolling data JSON decoding error")
        }
    }
    
    func initializeAllGames() {
        parse(jsonData: readLocalFile(forName: "ScrollingData")!)
    }
    
    private func collection(from collections: [CollectionEntity],
                            with name: CollectionName) -> CollectionEntity? {
        return collections.first(where: { $0.name == name.rawValue })
    }
    
    // MARK: - Fetching

    func fetchGamesForCollection(collection: CollectionEntity) -> [Game]? {
        let fetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
        let predicate = NSPredicate(format: "collection CONTAINS %@", collection)
        fetchRequest.predicate = predicate
        let result = try? DataController.shared.viewContext.fetch(fetchRequest)
        return result
    }
    
    func fetchCollectionsForGame(game: Game) -> [CollectionEntity]? {
        let fetchRequest: NSFetchRequest<CollectionEntity> = CollectionEntity.fetchRequest()
        let predicate = NSPredicate(format: "(ANY games == %@)", game)
        fetchRequest.predicate = predicate
        let result = try? DataController.shared.viewContext.fetch(fetchRequest)
        return result
    }
    
    func fetchGamesForAllCollections() {
        self.myGames += fetchGamesForCollection(collection: myGamesCollection) ?? []
        self.allGames += fetchGamesForCollection(collection: allGamesCollection) ?? []
        self.wantedGames += fetchGamesForCollection(collection: wantedGamesCollection) ?? []
    }
    
    func getBoardsByWorkingCondition() {
        var workingBoards : [Game] = []
        var partiallyWorkingBoards : [Game] = []
        var nonWorkingBoards : [Game] = []
        
        for board in myGames {
            switch Int(board.functionalCondition) {
            case 0:
                workingBoards += [board]
            case 1:
                partiallyWorkingBoards += [board]
            case 2:
                nonWorkingBoards += [board]
            default:
                break
            }
        }
        numberOfWorkingBoards = workingBoards.count
        numberOfBootingBoards = partiallyWorkingBoards.count
        numberOfNonWorkingBoards = nonWorkingBoards.count
        numberOfBoardsInCollection = workingBoards.count + partiallyWorkingBoards.count + nonWorkingBoards.count
    }
    
    func getCabinetHardware() {
      //  collectedCabinetHardWare = []
        
        var cabinets = [Game]()
        var monitors = [Game]()
        var controls = [Game]()
        var bezels = [Game]()
        var controlPanelOverlays = [Game]()
        var artworks = [Game]()
        var marquees = [Game]()
        
        for game in myGames {
            if game.hasCabinetHardware {
                
            if game.hasCabinet { cabinets += [game] }
            if game.hasMonitorFlag { monitors += [game] }
            if game.hasControls { controls += [game] }
            if game.hasBezel { bezels += [game] }
            if game.hasControlPanelOverlay { controlPanelOverlays += [game] }
            if game.hasCabinetArt { artworks += [game] }
            if game.hasMarquee { marquees += [game] }
            }
        }
     
        //collectedCabinetHardWare = cabinets + monitors + controls + bezels + controlPanelOverlays + artworks + marquees
        
        hardwareCountsDictionary = ["Boards" : Double(numberOfBoardsInCollection), "Monitors" : Double(monitors.count), "Controls" : Double(controls.count), "Bezels" : Double(bezels.count), "CPOs": Double(controlPanelOverlays.count), "Art" : Double(artworks.count), "Marquees" : Double(marquees.count)]
        
    }
    
//    func getAllHardware() {
//        allHardwareInCollection = boardsInCollection + collectedCabinetHardWare
//    }
}
