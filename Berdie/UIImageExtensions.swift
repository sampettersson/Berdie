//
//  UIImageExtensions.swift
//  Berdie
//
//  Created by Sam Pettersson (Skolan) on 06/11/14.
//  Copyright (c) 2014 lesr. All rights reserved.
//

import UIKit

extension UIImage {
    class func imageFromColor(color: UIColor) -> UIImage {
        
        var rect: CGRect = CGRectMake(0, 0, 1, 1)
        UIGraphicsBeginImageContext(rect.size)
        var context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        var image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
        
    }
}
