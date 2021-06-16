//
//  PopOverViewController.swift
//  arcadeCollector
//
//  Created by TrixxMac on 5/5/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit
import WebKit
import PDFKit

class PopOverViewController: UIViewController, UIScrollViewDelegate {
    
    var margins: UILayoutGuide!
    var orientation: String!
    var manual: PDFDocument!
    var marqueeImage: UIImage!
    var image: UIImage!
    var text: String!
    var type: String!
    var webURL: URL!
  
    
   // @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
     //   self.tabBarController?.tabBar.isHidden = true
        // view.addSubview(webView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
 
        margins = view.layoutMarginsGuide
        
//        scrollView.delegate = self
//        scrollView.minimumZoomScale = 1.0
//        scrollView.maximumZoomScale = 5.0
//        //Todo - allow view to translate when zooming
        
        hideAllViews()
        setView()
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        imageView.removeAllConstraints()
        setView()
       
        // this aint workin ..  really just want to reset constraints after rotation
      //  imageView.setNeedsLayout()
    }
   
//    override func viewWillAppear(_ animated: Bool) {
//        super .viewWillAppear(true)
//       // self.showAnimate(viewController: self)
//
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
       // self.tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        //removeAnimate(viewController: self)
        
        dismiss(animated: true, completion: nil)
    }
    
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return imageView
//    }
    
    
    func setView() {
        
        switch type {
            
        case "pdfView":
            pdfView.isHidden = false
            pdfView.document = manual
            pdfView.frame = view.frame
            
        case "textView":
            textView.isHidden = false
            textView.text = text
            textView.backgroundColor = UIColor.black
            textView.frame = view.frame
            
        case "webView":
            webView.isHidden = false
            webView.configuration.allowsInlineMediaPlayback = true // done in storyboard
            webView.frame = view.frame
            
            let request = URLRequest(url: webURL)
            webView.load(request)
            
        case "marqueeView": //
            view.backgroundColor = UIColor.black
            imageView.translatesAutoresizingMaskIntoConstraints = true // great.. now rotation is all fucked
            imageView.image = marqueeImage
            imageView.contentMode = .scaleAspectFit
            imageView.frame = view.frame
            imageView.isHidden = false
            
        case "flyerView":
            view.backgroundColor = UIColor.black
            imageView.translatesAutoresizingMaskIntoConstraints = true
            imageView.image = image
            imageView.frame = view.frame
            imageView.contentMode = .scaleAspectFit
            imageView.isHidden = false
            
        case "hardwareView":
            view.backgroundColor = UIColor.black
            imageView.translatesAutoresizingMaskIntoConstraints = true
            imageView.image = image
            imageView.contentMode = .scaleAspectFit
            imageView.frame = view.frame
            imageView.isHidden = false
            
        case "gameImageView":
            
            view.backgroundColor = UIColor.black
            
            let centerX =        imageView.centerXAnchor.constraint(equalTo: margins.centerXAnchor)
            
            let centerY =           imageView.centerYAnchor.constraint(equalTo: margins.centerYAnchor)
            
            let portraitHeightAnchor = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 3.0/4.0)
            
            let portraitWidthAnchor = imageView.widthAnchor.constraint(equalTo: margins.widthAnchor)
            
            let landscapeHeightAnchor =  imageView.heightAnchor.constraint(equalTo: margins.heightAnchor)
            
            let landscapeWidthAnchor = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 4.0/3.0)
            
            imageView.contentMode = .scaleToFill
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            imageView.isHidden = false
            imageView.image = image
            
            
            
            switch orientation { // ToDo: need to update rotational behavior of horizontal / vert
                
                
                
            case "Horizontal": // Force 4:3 Aspect ratio
                
                
                
                
                if UIDevice.current.orientation.isPortrait {
                    
                    
                    centerX.isActive = true
                    centerY.isActive = true
                    //     landscapeHeightAnchor.isActive = false
                    //     landscapeWidthAnchor.isActive = false
                    portraitWidthAnchor.isActive = true
                    portraitHeightAnchor.isActive = true
                    
                } else {
                    //
                    //                centerX.isActive = false
                    //                centerY.isActive = false
                    centerX.isActive = true
                    centerY.isActive = true
                    //                portraitWidthAnchor.isActive = false
                    //                portraitHeightAnchor.isActive = false
                    landscapeHeightAnchor.isActive = true
                    landscapeWidthAnchor.isActive = true
                    //
                }
                
                
            case "Vertical": // Force 3:4 Aspect Ratio
                
                //imageView.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
                //imageView.bottomAnchor.constraint(equalTo:
                //    margins.bottomAnchor).isActive = true
                
                if UIDevice.current.orientation.isPortrait {
                    imageView.widthAnchor.constraint(equalTo: margins.widthAnchor).isActive = true
                    centerX.isActive = true
                    centerY.isActive = true
                    imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 4.0/3.0).isActive = true
                }
                else {
                    centerX.isActive = true
                    centerY.isActive = true
                    imageView.heightAnchor.constraint(equalTo: margins.heightAnchor).isActive = true
                    imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 3.0/4.0).isActive = true
                    
                    
                }
            default :
                imageView.translatesAutoresizingMaskIntoConstraints = true
                imageView.contentMode = .scaleAspectFit
                imageView.frame = view.frame
            }
        default: break
        }
    }
    
    func hideAllViews() {
        pdfView.isHidden = true
        textView.isHidden = true
        pdfView.isHidden = true
        webView.isHidden = true
    }
}
