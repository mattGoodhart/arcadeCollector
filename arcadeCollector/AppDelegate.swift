//
//  AppDelegate.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/3/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit
import CoreData

/* TODOs
 
 Update to Swift 5
 Update to Clean MVVM Architecture
 Repair Log Feature
    -
    -
 Write Unit Tests
 UI Tests?
 Update Scrolling Data
  - keep latest version on github
  - Add ability to check for updated gameslist on launch
  - allow all videogames from MAME (to support repair logs for games with no full MAME driver)
  - Maybe make MAME-working games the default filter in All Games tab to keep trim
    -Add color to gameTable cell to indicatue MAME working
 
 */


@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var allowedOrientations: UIInterfaceOrientationMask = .portrait

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        DataController.shared.load()

        // Do this in a background context
        CollectionManager.shared.createCollectionsIfNeeded()
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return allowedOrientations
    }

    func saveViewContext() {
        try? DataController.shared.viewContext.save()
    }

   // MARK: APP Life Cycle

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveViewContext()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        saveViewContext()
    }
}
