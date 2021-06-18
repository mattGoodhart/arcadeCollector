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
    var collections: [CollectionEntity]!
    var allGamesCollection: CollectionEntity!
    var myGamesCollection: CollectionEntity!
    var wantedGamesCollection: CollectionEntity!
    var allGames = [Game]()
    var myGames = [Game]()
    var wantedGames = [Game]()
    
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
        
        let allGamesColl = CollectionEntity(context: dataController.viewContext)
        let myGamesColl = CollectionEntity(context: dataController.viewContext)
        let wantedGamesColl = CollectionEntity(context: dataController.viewContext)
        
        allGamesColl.name = CollectionName.allGames.rawValue
        myGamesColl.name = CollectionName.myGames.rawValue
        wantedGamesColl.name = CollectionName.wantedGames.rawValue
        
        allGamesCollection = allGamesColl
        myGamesCollection = myGamesColl
        wantedGamesCollection = wantedGamesColl
        collections = [allGamesColl, myGamesColl, wantedGamesColl]

        try? dataController.viewContext.save()
        initializeAllGames()
    }
  
    private func readLocalFile(forName name: String) -> Data? { // Trixx - discuss do-try-catch vs guard
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
            let decodedData = try JSONDecoder().decode(ScrollingDataDecoder.self,
                                                       from: jsonData)
            for game in decodedData.result {
                let gameEntity = Game(context: dataController.viewContext)
                gameEntity.romSetName = game.romName
                gameEntity.title = game.title
                gameEntity.year = game.year
                gameEntity.manufacturer = game.manufacturer
                gameEntity.players = game.players
                gameEntity.orientation = game.orientation
                gameEntity.hasBezel = false // There's gotta be a way to refactor these chumbawumbas (booleans)
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

    private func fetchCollectionsFromCoreData() -> [CollectionEntity]? {
        let fetchRequest: NSFetchRequest<CollectionEntity> = CollectionEntity.fetchRequest()
        let fetchResult = try? dataController.viewContext.fetch(fetchRequest)
        return fetchResult
    }
    
    private func load(from collections: [CollectionEntity]) {
        guard let collections = fetchCollectionsFromCoreData() else {
            print("Unable to fetch collections")
            return
        }
        allGamesCollection = collection(from: collections, with: .allGames)
        myGamesCollection = collection(from: collections, with: .myGames)
        wantedGamesCollection = collection(from: collections, with: .wantedGames)
    }
    
    private func collection(from collections: [CollectionEntity],
                            with name: CollectionName) -> CollectionEntity? {
        return collections.first(where: { $0.name == name.rawValue })
    }

    func fetchGamesForCollection(collection: CollectionEntity) -> [Game]? {
        let fetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
        let predicate = NSPredicate(format: "collection CONTAINS %@", collection)
        fetchRequest.predicate = predicate
        let result = try? DataController.shared.viewContext.fetch(fetchRequest)
       // print(result as Any)
        return result
    }
    
   func fetchCollectionsForGame(game: Game) -> [CollectionEntity]? {
    let fetchRequest: NSFetchRequest<CollectionEntity> = CollectionEntity.fetchRequest()
    let predicate = NSPredicate(format: "(ANY games == %@)", game)
    fetchRequest.predicate = predicate
    let result = try? DataController.shared.viewContext.fetch(fetchRequest)
    print(result as Any)
    return result
    }
    
    func fetchGamesForAllCollections() {
        self.myGames += fetchGamesForCollection(collection: myGamesCollection) ?? []
        self.allGames += fetchGamesForCollection(collection: allGamesCollection) ?? []
        self.wantedGames += fetchGamesForCollection(collection: wantedGamesCollection) ?? []
    }
}
