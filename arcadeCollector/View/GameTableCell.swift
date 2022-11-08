//
//  GameTableCell.swift
//  arcadeCollector
//
//  Created by Matt Goodhart on 3/4/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit


class GameTableCell: UITableViewCell, Identifiable {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var detailtext: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        reset()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }

    func reset() {
        titleText.text = nil
        detailtext.text = nil
        let iconImage = UIImage(named: "space-invaders-placeholder")
        iconImageView.image = iconImage
    }

}
