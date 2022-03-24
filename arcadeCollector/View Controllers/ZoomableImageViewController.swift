//
//  ZoomableImageViewController.swift
//  arcadeCollector
//
//  Created by Matt Goodhart on 2/14/22.
//  Copyright © 2022 CatBoiz. All rights reserved.
//

import UIKit

class ZoomableImageViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView! // at this point do I even need it in Storyboard?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var image: UIImage!
    var orientation: String?
    var isInGameImage: Bool = true //will need to force aspect ratio if it is
    var imageView: UIImageView!
    let backgroundColor = UIColor(displayP3Red: 0.45, green: 0.62, blue: 0.5, alpha: 1.0)
    var contentView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeView()
        setConstraints()
    }
    
    func initializeView() {
        view.backgroundColor = backgroundColor
        
        imageView = UIImageView(image: image)
        
        contentView = UIView(frame: imageView.frame)
        contentView.backgroundColor = UIColor.blue
        contentView.addSubview(imageView)
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = 1.0
        scrollView.addSubview(contentView)
        
    }
    
    func setConstraints() {
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        contentView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        
        self.imageView.frame = view.frame
        self.imageView.contentMode = .scaleAspectFit
        
        if isInGameImage {
            resizeInGameImageSoPanningWorks()
        }
        
    
//        if !isInGameImage {
//            self.imageView.frame = view.frame
//            self.imageView.contentMode = .scaleAspectFit
//
//        } else {
//            forceAspectForInGameImage()
//        }
    }
    
    /// Forces image to a 4:3 (Yoko) or 3:4 (Tate)  aspect ratio, regardless of image resolution
    func resizeInGameImageSoPanningWorks() {
        var newSize: CGSize
        
        switch orientation {
        
            
        case "Horizontal": //force 4:3
            let newWidth = UIScreen.main.bounds.size.width//view.intrinsicContentSize.width
            let newHeight = newWidth * (3/4)
             newSize = CGSize(width: newWidth, height: newHeight)
        case "Vertical": //Force 3:4
            let newWidth = image.size.width / 3
            let newHeight = image.size.height / 4
            
             newSize = CGSize(width: newWidth, height: newHeight)
        default: return
        }
        
        
        
        
        
    // let centerSize = CGSize(width: (UIScreen.main.bounds.width/6.5), height: (UIScreen.main.bounds.height/10))
        
        //unbung
        let resizedImage = image.resizeImage(image: image, newSize: newSize)
        imageView.image = resizedImage
    }
    
    func forceAspectForInGameImage() {
        
        let margins: UILayoutGuide = view.layoutMarginsGuide
        let yokoHeightAnchor: NSLayoutConstraint
        let tateHeightAnchor: NSLayoutConstraint
        
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.centerXAnchor.constraint(equalTo: margins.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: margins.widthAnchor).isActive = true
        
        yokoHeightAnchor = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 3.0/4.0)
        tateHeightAnchor = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 4.0/3.0)
        
        switch orientation {
            
        case "Horizontal":
            yokoHeightAnchor.isActive = true
            
        case "Vertical":
            tateHeightAnchor.isActive = true
            
        default: return
        }
        
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//
//        if isInGameImage {
//            return contentView
//        } else {
//            return imageView
//        }
        return imageView
    }
}
