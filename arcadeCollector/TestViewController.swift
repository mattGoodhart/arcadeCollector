//
//  TestViewController.swift
//  arcadeCollector
//
//  Created by Matt Kauper on 2/13/22.
//  Copyright © 2022 CatBoiz. All rights reserved.
//

import UIKit

class MyViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.delegate = self
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}
