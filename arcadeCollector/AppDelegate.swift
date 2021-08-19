//
//  AppDelegate.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/3/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var allowedOrientations: UIInterfaceOrientationMask = .all
  
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        DataController.shared.load()
        CollectionManager.shared.createCollectionsIfNeeded()
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return allowedOrientations
    }
    
    func saveViewContext() {
        try? DataController.shared.viewContext.save()
    }
    
   // APP Life Cycle
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        saveViewContext()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        saveViewContext()
    }
}
