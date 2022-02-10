//
//  GameTableCell.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/4/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

class GameTableCell: UITableViewCell {
    
    static let reuseIdentifier = "GameTableCell"
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var detailtext: UILabel!
    
   // let dataAsset = NSDataAsset(name: "space_invaders_icon")!
    
    let dataAsset = NSDataAsset(name: "space_invaders_resized")!

    // MARK: UICollectionReusableView
    override func prepareForReuse() {
        super.prepareForReuse()
       // let iconImage = UIImage(named: "space_invaders_icon")
        let iconImage = UIImage(data: dataAsset.data)
        iconImageView.image = iconImage
    }
}
