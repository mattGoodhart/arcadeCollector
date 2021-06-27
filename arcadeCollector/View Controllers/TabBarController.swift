//
//  TabBarController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 5/23/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildren()
    }
    
    private func setupChildren() {
        guard let viewControllers = viewControllers else {
            return
        }
        
        let myGamesViewController = viewControllers[1].children[0] as! TableViewController
        let allGamesViewController = viewControllers[2].children[0] as! TableViewController
        let wantedViewController = viewControllers[3].children[0] as! TableViewController

        myGamesViewController.tab = .myGames
        allGamesViewController.tab = .allGames
        wantedViewController.tab = .wanted
    }
    
}
