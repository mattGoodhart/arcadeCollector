//
//  DataController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/3/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    static let shared = DataController(modelName: "ArcadeCollector")
    let persistentContainer:NSPersistentContainer
    
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init(modelName:String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSave()
            self.configureContexts()
            completion?()
        }
    }
}

// MARK: - Autosaving

extension DataController { //necessary?
    func autoSave(interval:TimeInterval = 45) {
        print("autosaving")
        
        guard interval > 0 else {
            print("cannot set negative autosave interval")
            return
        }
        
        if viewContext.hasChanges {
            print("autosaving")
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSave(interval: interval)
        }
    }
}
