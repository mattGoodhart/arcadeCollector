//
//  RepairLogCell.swift
//  arcadeCollector
//
//  Created by Matt Goodhart on 11/4/22.
//  Copyright © 2022 CatBoiz. All rights reserved.
//

import UIKit

class RepairLogTableCell: UITableViewCell {
    
    @IBOutlet weak var pcbIconImageView: UIImageView!
    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var pcbName: UILabel!
    
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
        pcbName.text = nil
        let iconImage = UIImage(named: "noHardwareDefaultImage")
        pcbIconImageView.image = iconImage
    }
}
