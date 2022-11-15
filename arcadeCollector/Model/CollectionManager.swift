//
//  CollectionManager.swift
//  arcadeCollector
//
//  Created by Matt Goodhart on 3/17/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import CoreData

enum CollectionName: String {
    case allGames = "All Games"
    case myGames = "My Games"
    case wantedGames = "Wanted Games"
    case repairLogs = "Repair Logs"
}

class CollectionManager {

    static let shared = CollectionManager()

    let dataController = DataController.shared
    var collections: [CollectionEntity] = []
    var allGamesCollection: CollectionEntity! // Can these not be bung?
    var myGamesCollection: CollectionEntity!
    var wantedGamesCollection: CollectionEntity!
    var gamesInRepairCollection: CollectionEntity!
    var allGames: [Game] = []
    var myGames: [Game] = []
    var wantedGames: [Game] = []
    var workingBoards: [Game] = []
    var partiallyWorkingBoards: [Game] = []
    var nonWorkingBoards: [Game] = []
    var boardsInCollection: [Game] = []
    var gamesInRepair: [Game] = []

    // make me a struct
    var hardwareCountsDictionary: [String: Double] = [:]

    // MARK: - Initialization

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
        let gamesInRepairCollection = CollectionEntity(context: dataController.viewContext)

        allGamesCollection.name = CollectionName.allGames.rawValue
        myGamesCollection.name = CollectionName.myGames.rawValue
        wantedGamesCollection.name = CollectionName.wantedGames.rawValue
        gamesInRepairCollection.name = CollectionName.repairLogs.rawValue

        self.allGamesCollection = allGamesCollection
        self.myGamesCollection = myGamesCollection
        self.wantedGamesCollection = wantedGamesCollection
        self.gamesInRepairCollection = gamesInRepairCollection
        collections = [allGamesCollection, myGamesCollection, wantedGamesCollection, gamesInRepairCollection]

        try? dataController.viewContext.save()
        initializeAllGames()
    }

    private func collection(from collections: [CollectionEntity],
                            with name: CollectionName) -> CollectionEntity? {
        return collections.first(where: { $0.name == name.rawValue })
    }

    private func load(from collections: [CollectionEntity]) {
        allGamesCollection = collection(from: collections, with: .allGames)
        myGamesCollection = collection(from: collections, with: .myGames)
        wantedGamesCollection = collection(from: collections, with: .wantedGames)
        gamesInRepairCollection = collection(from: collections, with: .repairLogs)
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
                gameEntity.hasBoard = false
                gameEntity.isBootleg = false
                gameEntity.functionalCondition = 0
                gameEntity.extendedPlayStatus = 0
                gameEntity.audioStatus = 0
                gameEntity.bootStatus = 0
                gameEntity.controlsStatus = 0
                self.allGames.append(gameEntity)
                allGamesCollection.addToGames(gameEntity)
            }
            try dataController.viewContext.save()
        } catch {
            print(error)
        }
    }

    func initializeAllGames() {
        parse(jsonData: readLocalFile(forName: "ScrollingData")!)
    }

    // MARK: - Fetching

    private func fetchCollectionsFromCoreData() -> [CollectionEntity]? {
        let fetchRequest: NSFetchRequest<CollectionEntity> = CollectionEntity.fetchRequest()
        let fetchResult = try? dataController.viewContext.fetch(fetchRequest)
        return fetchResult
    }

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
        self.gamesInRepair += fetchGamesForCollection(collection: gamesInRepairCollection) ?? []
    }

    // MARK: - Other Methods

    func getBoardsByWorkingCondition() {
        workingBoards = []
        partiallyWorkingBoards = []
        nonWorkingBoards = []

        for game in myGames {
            if game.hasBoard {
                switch Int(game.functionalCondition) {
                case 0:
                    workingBoards += [game]
                case 1:
                    partiallyWorkingBoards += [game]
                case 2:
                    nonWorkingBoards += [game]
                default:
                    break
                }
            }
        }
        boardsInCollection = workingBoards + partiallyWorkingBoards + nonWorkingBoards
    }

    func countOfOwnedGameBy(_ property: KeyPath<Game, Bool>) -> Int {
        // TODO can we use entity description instead of magic string?
        // Don't remember what I was doing with this exactly. Maybe a good jumping off point for a second pie chart with a breakdown of reapir log issues e.g. audio, video, controls, boot, extended play etc. Would need to include these properties in the Game entity, of course
        let request = NSFetchRequest<NSFetchRequestResult>.init(entityName: "Game")

        let sumDescription = NSExpressionDescription()
        sumDescription.name = "sum"
        let keypathExpression = NSExpression(forKeyPath: property)
        let expression = NSExpression(forFunction: "\(sumDescription.name):", arguments: [keypathExpression])
        sumDescription.expression = expression
        sumDescription.expressionResultType = .integer16AttributeType

        request.returnsObjectsAsFaults = false
        request.propertiesToFetch = [sumDescription]
        request.resultType = .countResultType

        do {
            return try dataController.viewContext.fetch(request).first as? Int ?? 0
        } catch {
            return 0
        }
    }
}
