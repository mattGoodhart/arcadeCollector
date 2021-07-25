//
//  aboutViewController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/26/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        appDelegate.allowedOrientations = .portrait
    }
}
    
