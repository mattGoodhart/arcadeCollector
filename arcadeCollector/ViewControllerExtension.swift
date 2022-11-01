//
//  Extensions.swift
//  arcadeCollector
//
//  Created by TrixxMac on 5/4/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

extension UIViewController {
    func handleActivityIndicator(indicator: UIActivityIndicatorView, viewController: UIViewController, show: Bool) {
        if show {
            DispatchQueue.main.async {
                indicator.bringSubviewToFront(viewController.view)
                indicator.center = viewController.view.center
                indicator.isHidden = false // could also set hidesWhenStopped to true -- do this
                indicator.startAnimating()
            }
        } else {
            DispatchQueue.main.async {
                indicator.sendSubviewToBack(viewController.view)
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
