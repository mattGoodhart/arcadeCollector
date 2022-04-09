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

    var image: UIImage!
    var orientation: String?
    var isInGameImage: Bool = true //will need to resize image to force aspect ratio if it is
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
    }
    
    /// Forces image to a 4:3 (Yoko) or 3:4 (Tate)  aspect ratio, regardless of image resolution
    func resizeInGameImageSoPanningWorks() {
        let newWidth = UIScreen.main.bounds.size.width
        var newHeight = CGFloat()
        var newSize: CGSize
        
        if orientation == "Horizontal" {
            newHeight = newWidth * (3/4)
        } else if orientation == "Vertical" {
            newHeight = newWidth * (4/3)
        }
        newSize = CGSize(width: newWidth, height: newHeight)

        let resizedImage = image.resizeImage(image: image, newSize: newSize)
        imageView.image = resizedImage
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
