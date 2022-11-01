//
//  MAMEPopOver.swift
//  arcadeCollector
//
//  Created by TrixxMac on 4/9/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

class TextPopOverViewController: UIViewController {

    let masterCollection = CollectionManager.shared
    var notes = String()

    @IBOutlet weak var notesView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        self.showAnimate()

        notesView.text = notes
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @IBAction func dismissButtonTapped() {
        removeAnimate()
    }

    func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.view.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }

    func removeAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.view.alpha = 0.0
        }, completion: {(finished: Bool)  in
            if finished {
                self.view.removeFromSuperview()
            }
        })
    }
}
