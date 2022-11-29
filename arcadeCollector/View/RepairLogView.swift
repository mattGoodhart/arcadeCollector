//
//  RepairLogView.swift
//  arcadeCollector
//
//  Created by Matt Goodhart on 11/9/22.
//  Copyright © 2022 CatBoiz. All rights reserved.
//

import UIKit

class RepairLogView: UIView {
    
    var date: UILabel!
    var logNotes: UITextView!
    var addPhotoButton: UIButton!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let date = Date()
        self.date.text = String(describing: date)
        self.date.isHidden = false
        self.logNotes.isHidden = false
        self.addPhotoButton.isHidden = false
    }
    
    //logNotes.sizeToFit()
//    init(date: UILabel!, logNotes: UITextView!, addPhotoButton: UIButton!) {
//        self.date = date
//        self.logNotes = logNotes
//        self.addPhotoButton = addPhotoButton
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
}
