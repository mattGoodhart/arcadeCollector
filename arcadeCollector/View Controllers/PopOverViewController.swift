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
    
    //MARK: Properties
    
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    var centerX: NSLayoutConstraint!
    var centerY: NSLayoutConstraint!
    var widthAnchor: NSLayoutConstraint!
    var heightAnchor: NSLayoutConstraint!
    var portraitHeightAnchor: NSLayoutConstraint!
    var portraitWidthAnchor: NSLayoutConstraint!
    var landscapeHeightAnchor: NSLayoutConstraint!
    var landscapeWidthAnchor: NSLayoutConstraint!
    var margins: UILayoutGuide!
    var orientation: String!
    var manual: PDFDocument!
    var marqueeImage: UIImage!
    var image: UIImage!
    var text: String!
    var type: String!
    var webURL: URL!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        margins = view.layoutMarginsGuide
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        hideAllViews()
    //    dismissButton.removeAllConstraints()
        setView()
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//        imageView.removeAllConstraints()
//        setView()
//    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func setImageViewAnchors() {
        centerX = imageView.centerXAnchor.constraint(equalTo: margins.centerXAnchor)
        centerY = imageView.centerYAnchor.constraint(equalTo: margins.centerYAnchor)
        widthAnchor = imageView.widthAnchor.constraint(equalTo: margins.widthAnchor)
        heightAnchor = imageView.heightAnchor.constraint(equalTo: margins.heightAnchor)
        centerX.isActive = true
        centerY.isActive = true
        widthAnchor.isActive = true
        heightAnchor.isActive = true
    }
    
    func setGameImageAnchors() {
      //  imageView.translatesAutoresizingMaskIntoConstraints = false
        portraitHeightAnchor = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 3.0/4.0)
        portraitWidthAnchor = imageView.widthAnchor.constraint(equalTo: margins.widthAnchor)
        landscapeHeightAnchor =  imageView.heightAnchor.constraint(equalTo: margins.heightAnchor)
        landscapeWidthAnchor = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 4.0/3.0)
        centerX = imageView.centerXAnchor.constraint(equalTo: margins.centerXAnchor)
        centerY = imageView.centerYAnchor.constraint(equalTo: margins.centerYAnchor)
        centerX.isActive = true
        centerY.isActive = true
    }
    
    func setView() {
        
     //   setAnchors()
        
        switch type {
            
        case "pdfView":
            appDelegate.allowedOrientations = .portrait
            pdfView.displayMode = .singlePageContinuous
            pdfView.autoScales = true
            pdfView.displayDirection = .vertical
            pdfView.contentMode = .scaleAspectFit
            pdfView.isHidden = false
            pdfView.document = manual
            pdfView.frame = view.frame
            //setDismissButton()
            
        case "Horizontally Scrolling textView":
            appDelegate.allowedOrientations = .portrait
            let scrollView = UIScrollView()
            let maxSize = CGSize(width:9999, height:9999)
            let font = UIFont(name: "Avenir Book", size: 17)!
            let stringSize = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : font], context: nil)
            let textFrame = CGRect(x: 0, y: 0, width: stringSize.width+50, height: stringSize.height+10)
            textView.frame = textFrame
            textView.isScrollEnabled = false
            textView.font = font
            textView.text = text
            view.addSubview(scrollView)
            scrollView.frame = view.frame
            scrollView.contentSize = CGSize(width: stringSize.width, height: stringSize.height)
            textView.isHidden = false
            textView.isScrollEnabled = false
            scrollView.addSubview(textView)
            textView.text = text
           // setDismissButton()
            
        case "textView":
            appDelegate.allowedOrientations = .portrait
            textView.isHidden = false
            textView.text = text
            textView.frame = view.frame
            //setDismissButton()
            
        case "marqueeView":
            appDelegate.allowedOrientations = .all
            view.backgroundColor = UIColor.black
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = marqueeImage
            imageView.contentMode = .scaleAspectFit
            imageView.frame = view.frame
            setImageViewAnchors()
            scrollView.isHidden = false
           // setDismissButton()
            
        case "flyerView", "hardwareView":
            appDelegate.allowedOrientations = .all
            view.backgroundColor = UIColor.black
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = image
            imageView.frame = view.frame
            imageView.contentMode = .scaleAspectFit
            setImageViewAnchors()
            scrollView.isHidden = false
           // setDismissButton()
            
        case "gameImageView":
            imageView.translatesAutoresizingMaskIntoConstraints = false
            appDelegate.allowedOrientations = .all
            view.backgroundColor = UIColor.black
            imageView.contentMode = .scaleToFill
            setGameImageAnchors()
            setOrientation()
            imageView.image = image
            scrollView.isHidden = false
            
        case "xgameImageView":
            appDelegate.allowedOrientations = .all
            imageView.translatesAutoresizingMaskIntoConstraints = false
           // let scrollView = UIScrollView()
            //let maxSize = CGSize(width:9999, height:9999)
            
//            let stringSize = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : font], context: nil)
//            let imageFrame = CGRect(x: 0, y: 0, width: stringSize.width+50, height: stringSize.height+10)
//            textView.frame = textFrame
//
            setGameImageAnchors()
            setOrientation()
           // scrollView.contentSize = imageView.bounds.size
            imageView.image = image
           
          //  view.addSubview(scrollView)
        //scrollView.frame = view.frame
           // scrollView.contentSize =  CGSize(width: (self.imageView.image?.size.width ?? 100), height: (self.imageView.image?.size.height ?? 100))
            scrollView.isHidden = false
           
           // scrollView.addSubview(imageView)
       
            
            
        default: break
        }
       // setDismissButton()
    }
    
    func setOrientation() {
        
        switch orientation {
        case "Horizontal": // Force 4:3 Aspect ratio
            
            if UIDevice.current.orientation.isPortrait {
//                centerX.isActive = true
//                centerY.isActive = true
                portraitWidthAnchor.isActive = true
                portraitHeightAnchor.isActive = true
            } else {
//                centerX.isActive = true
//                centerY.isActive = true
                landscapeHeightAnchor.isActive = true
                landscapeWidthAnchor.isActive = true
            }
            
        case "Vertical": // Force 3:4 Aspect Ratio
            
            if UIDevice.current.orientation.isPortrait {
                imageView.widthAnchor.constraint(equalTo: margins.widthAnchor).isActive = true
//                centerX.isActive = true
//                centerY.isActive = true
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 4.0/3.0).isActive = true
            }
            else {
//                centerX.isActive = true
//                centerY.isActive = true
                imageView.heightAnchor.constraint(equalTo: margins.heightAnchor).isActive = true
                imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 3.0/4.0).isActive = true
            }
        default :
            imageView.translatesAutoresizingMaskIntoConstraints = true
            imageView.contentMode = .scaleAspectFit
            imageView.frame = view.frame
        }
        
    }
    
    func setDismissButton() {
        view.addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30).isActive = true
        dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30).isActive = true
    }
    
    func hideAllViews() {
        pdfView.isHidden = true
        textView.isHidden = true
        scrollView.isHidden = true
        dismissButton.isHidden = true
    }
    
//    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        centerScrollViewContents()
//    }
//
//    private var scrollViewVisibleSize: CGSize {
//        let contentInset = scrollView.contentInset
//        let scrollViewSize = scrollView.bounds.standardized.size
//        let width = scrollViewSize.width - contentInset.left - contentInset.right
//        let height = scrollViewSize.height - contentInset.top - contentInset.bottom
//        return CGSize(width:width, height:height)
//    }
//
//    private var scrollViewCenter: CGPoint {
//        let scrollViewSize = self.scrollViewVisibleSize
//        return CGPoint(x: scrollViewSize.width / 2.0,
//                       y: scrollViewSize.height / 2.0)
//    }
//
//    private func centerScrollViewContents() {
//        guard let image = imageView.image else {
//            return
//        }
//
//        let imgViewSize = imageView.frame.size
//        let imageSize = image.size
//
//        var realImgSize: CGSize
//        if imageSize.width / imageSize.height > imgViewSize.width / imgViewSize.height {
//            realImgSize = CGSize(width: imgViewSize.width,height: imgViewSize.width / imageSize.width * imageSize.height)
//        } else {
//            realImgSize = CGSize(width: imgViewSize.height / imageSize.height * imageSize.width, height: imgViewSize.height)
//        }
//
//        var frame = CGRect.zero
//        frame.size = realImgSize
//        imageView.frame = frame
//
//        let screenSize  = scrollView.frame.size
//        let offx = screenSize.width > realImgSize.width ? (screenSize.width - realImgSize.width) / 2 : 0
//        let offy = screenSize.height > realImgSize.height ? (screenSize.height - realImgSize.height) / 2 : 0
//        scrollView.contentInset = UIEdgeInsets(top: offy,
//                                               left: offx,
//                                               bottom: offy,
//                                               right: offx)
//
//        // The scroll view has zoomed, so you need to re-center the contents
//        let scrollViewSize = scrollViewVisibleSize
//
//        // First assume that image center coincides with the contents box center.
//        // This is correct when the image is bigger than scrollView due to zoom
//        var imageCenter = CGPoint(x: scrollView.contentSize.width / 2.0,
//                                  y: scrollView.contentSize.height / 2.0)
//
//        let center = scrollViewCenter
//
//        //if image is smaller than the scrollView visible size - fix the image center accordingly
//        if scrollView.contentSize.width < scrollViewSize.width {
//            imageCenter.x = center.x
//        }
//
//        if scrollView.contentSize.height < scrollViewSize.height {
//            imageCenter.y = center.y
//        }
//
//        imageView.center = imageCenter
//    }
    
    // MARK - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    
    
//
//    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
////        self.scrollView.contentSize = CGSize(width: (self.imageView.image?.size.width ?? 100 * scale), height: (self.imageView.image?.size.height ?? 100 * scale))
////        self.contentView.frame = CGRect(x: imageView.center.x, y: imageView.center.y, width: (self.imageView.image?.size.width ?? 100 * scale), height: (self.imageView.image?.size.height ?? 100 * scale))
//
//
//
//    }

}
