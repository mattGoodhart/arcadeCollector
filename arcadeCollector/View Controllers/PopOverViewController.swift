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
        margins = view.layoutMarginsGuide
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        hideAllViews()
        dismissButton.removeAllConstraints()
        setView()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        imageView.removeAllConstraints()
        setView()
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func setAnchors() {
        centerX = imageView.centerXAnchor.constraint(equalTo: margins.centerXAnchor)
        centerY = imageView.centerYAnchor.constraint(equalTo: margins.centerYAnchor)
        widthAnchor = imageView.widthAnchor.constraint(equalTo: margins.widthAnchor)
        heightAnchor = imageView.heightAnchor.constraint(equalTo: margins.heightAnchor)
    }
    
    func setGameImageAnchors() {
        portraitHeightAnchor = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 3.0/4.0)
        portraitWidthAnchor = imageView.widthAnchor.constraint(equalTo: margins.widthAnchor)
        landscapeHeightAnchor =  imageView.heightAnchor.constraint(equalTo: margins.heightAnchor)
        landscapeWidthAnchor = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 4.0/3.0)
    }
    
    func setView() {
        
        setAnchors()
        
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
            setDismissButton()
            
        case "Horizontally Scrolling textView":
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
            // textView.frame = view.frame
            
           textView.isScrollEnabled = false
           scrollView.addSubview(textView)
           textView.text = text
           setDismissButton()
            
            
        case "textView":
            //appDelegate.allowedOrientations = .portrait
            textView.isHidden = false
            textView.text = text
            //textView.backgroundColor = UIColor.black
            textView.frame = view.frame
            setDismissButton()
            
        case "marqueeView":
            appDelegate.allowedOrientations = .all
            view.backgroundColor = UIColor.black
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = marqueeImage
            imageView.contentMode = .scaleAspectFit
            imageView.frame = view.frame
            centerX.isActive = true
            centerY.isActive = true
            widthAnchor.isActive = true
            heightAnchor.isActive = true
            imageView.isHidden = false
            setDismissButton()
            
        case "flyerView", "hardwareView":
            appDelegate.allowedOrientations = .all
            view.backgroundColor = UIColor.black
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.image = image
            imageView.frame = view.frame
            imageView.contentMode = .scaleAspectFit
            centerX.isActive = true
            centerY.isActive = true
            widthAnchor.isActive = true
            heightAnchor.isActive = true
            imageView.isHidden = false
            setDismissButton()
            
        case "gameImageView":
            appDelegate.allowedOrientations = .all
            view.backgroundColor = UIColor.black
            setGameImageAnchors()
            imageView.contentMode = .scaleToFill
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.isHidden = false
            imageView.image = image
            setOrientation()
            
        default: break
        }
        setDismissButton()
    }
    
    func setOrientation() {
        
        switch orientation {
        case "Horizontal": // Force 4:3 Aspect ratio
            
            if UIDevice.current.orientation.isPortrait {
                centerX.isActive = true
                centerY.isActive = true
                portraitWidthAnchor.isActive = true
                portraitHeightAnchor.isActive = true
            } else {
                centerX.isActive = true
                centerY.isActive = true
                landscapeHeightAnchor.isActive = true
                landscapeWidthAnchor.isActive = true
            }
            
        case "Vertical": // Force 3:4 Aspect Ratio
            
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
        imageView.isHidden = true
    }
}
