//
//  GameTableCell.swift
//  arcadeCollector
//
//  Created by TrixxMac on 3/4/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

// Move me to my own file!
protocol Identifiable {
    static var reuseIdentifier: String { get }
}

extension Identifiable where Self: UITableViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

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
