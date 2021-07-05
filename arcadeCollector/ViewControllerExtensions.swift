//
//  Extensions.swift
//  arcadeCollector
//
//  Created by TrixxMac on 5/4/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

extension UIViewController {
    func handleActivityIndicator(indicator: UIActivityIndicatorView, vc: UIViewController, show: Bool) {
        if show {
            _ = indicator
            DispatchQueue.main.async {
                indicator.bringSubviewToFront(vc.view)
                indicator.center = vc.view.center
                indicator.isHidden = false // could also set hidesWhenStopped to true
                indicator.startAnimating()
            }
        } else {
            _ = indicator
            DispatchQueue.main.async {
                indicator.sendSubviewToBack(vc.view)
                indicator.isHidden = true
                indicator.stopAnimating()
            }
        }
    }
    
    func handleButtons(enabled: Bool, button: UIButton) {
        if enabled {
            DispatchQueue.main.async {
                button.isEnabled = true
                button.alpha = 1.0
            }
        } else {
            DispatchQueue.main.async {
                button.isEnabled = false
                button.alpha = 0.5
            }
        }
    }
}







