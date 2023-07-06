//
//  OtherExtensions.swift
//  arcadeCollector
//
//  Created by Matt Goodhart on 7/5/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

extension UIImage {
    public func resizeImage(newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x: 0.0, y: 0.0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()

        return newImage
    }
}

protocol Identifiable {
    static var reuseIdentifier: String { get }
}

extension Identifiable where Self: UITableViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

