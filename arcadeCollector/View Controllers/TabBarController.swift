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

        let tableControllers = viewControllers.compactMap({ $0.children.first as? TableViewController })
        let controllersToTabs = zip(tableControllers, Tab.allCases)

        controllersToTabs.forEach { controller, tab in
            controller.tab = tab
        }
    }
}
