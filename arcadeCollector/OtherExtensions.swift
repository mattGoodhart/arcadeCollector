//
//  OtherExtensions.swift
//  arcadeCollector
//
//  Created by TrixxMac on 7/5/21.
//  Copyright © 2021 CatBoiz. All rights reserved.
//

import UIKit

extension UIImage {
    public func resizeImage(image: UIImage, newSize: CGSize) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0.0, y: 0.0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return newImage
    }
}
