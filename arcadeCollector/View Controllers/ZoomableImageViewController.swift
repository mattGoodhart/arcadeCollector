//
//  ZoomableImageViewController.swift
//  arcadeCollector
//
//  Created by Matt Goodhart on 2/14/22.
//  Copyright © 2022 CatBoiz. All rights reserved.
//

import UIKit

class ZoomableImageViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var image: UIImage?
    var orientation: String?
    var isInGameImage: Bool = true //will need to force aspect ratio if it is
    var imageView: UIImageView!
    let backgroundColor = UIColor(displayP3Red: 0.45, green: 0.62, blue: 0.5, alpha: 1.0)
    var contentView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //  appDelegate.allowedOrientations = .all
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = 1.0
        
      //  scrollView.translatesAutoresizingMaskIntoConstraints = false
      //  scrollView.frame = view.frame
     
        self.imageView = UIImageView(image: image)
        
        contentView = UIView(frame: scrollView.frame)
        //   let contentView = UIView(frame: scrollView.frame)
        contentView.backgroundColor = backgroundColor
        view.backgroundColor = backgroundColor
        contentView.addSubview(imageView)
        scrollView.addSubview(contentView)
        
        setView()
        
        
    }
    
    
    
    
    func setView() {
        if !isInGameImage {
            self.imageView.frame = view.frame
            self.imageView.contentMode = .scaleAspectFit
        } else {
            forceAspectForInGameImage()
        }
    }
    
    
    func forceAspectForInGameImage() {
        
    //    contentView.frame = view.frame
        
        let margins: UILayoutGuide = view.layoutMarginsGuide
        let portraitHeightAnchor: NSLayoutConstraint
        let portraitWidthAnchor: NSLayoutConstraint
        let centerX: NSLayoutConstraint
        let centerY: NSLayoutConstraint
        
        imageView.contentMode = .scaleToFill
        
     //   contentView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        
//          scrollView.translatesAutoresizingMaskIntoConstraints = false
//          scrollView.frame = view.frame
       
      //  contentView.frame = view.frame
        
        centerX = imageView.centerXAnchor.constraint(equalTo: margins.centerXAnchor)
        centerY = imageView.centerYAnchor.constraint(equalTo: margins.centerYAnchor)
        portraitHeightAnchor = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 3.0/4.0)
        portraitWidthAnchor = imageView.widthAnchor.constraint(equalTo: margins.widthAnchor)
        
        centerX.isActive = true
        centerY.isActive = true
        
        
        switch orientation {
            
        case "Horizontal":
            
            portraitWidthAnchor.isActive = true
            portraitHeightAnchor.isActive = true
            
        case "Vertical":
            
            imageView.widthAnchor.constraint(equalTo: margins.widthAnchor).isActive = true
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 4.0/3.0).isActive = true
            
            
        default: return
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
       // return imageView
        if isInGameImage {
            return contentView
        } else {
            return imageView
        }
        
    }
}
