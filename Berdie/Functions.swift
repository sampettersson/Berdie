//
//  Functions.swift
//  TheLostKiwi
//
//  Created by Sam Pettersson (Skolan) on 18/09/14.
//  Copyright (c) 2014 lesr. All rights reserved.
//

import Foundation
import UIKit

func getSquareColorImage (color: UIColor) -> UIImage {
    var rect: CGRect = CGRectMake(0, 0, 1, 1)
    UIGraphicsBeginImageContext(rect.size)
    var context: CGContextRef = UIGraphicsGetCurrentContext()
    
    CGContextSetFillColorWithColor(context, color.CGColor)
    CGContextFillRect(context, rect)
    
    var image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
}