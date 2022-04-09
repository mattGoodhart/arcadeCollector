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
    @IBOutlet weak var dismissButton: UIButton!
    
    var manual: PDFDocument!
    var text: String!
    var type: String!
    var webURL: URL!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideAllViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setView()
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func setView() {
        
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
            
        case "textView":
            appDelegate.allowedOrientations = .portrait
            textView.isHidden = false
            textView.text = text
            textView.frame = view.frame

        default: break
        }
        // setDismissButton()
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
        dismissButton.isHidden = true
    } 
}
