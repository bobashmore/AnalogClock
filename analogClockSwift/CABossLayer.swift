//
//  CABossLayer.swift
//  analogClockSwift
//
//  Created by bob.ashmore on 09/02/2016.
//  Copyright © 2016 bob.ashmore. All rights reserved.
//

import UIKit
import CoreGraphics

let TWO_PI:CGFloat = CGFloat(M_PI) * 2.0

class CABossLayer: CALayer {

    var startColor: UIColor = UIColor.blackColor()
    var endColor: UIColor = UIColor.blackColor()
    var gradient: CGGradientRef?
    
    func removeGradient() {
        self.gradient = nil
    }

    override func drawInContext(context: CGContext) {
        CGContextSaveGState(context)
        CGContextTranslateCTM(context, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        
        if gradient == nil {
            let gradientColors: [AnyObject] = [self.startColor.CGColor, self.endColor.CGColor]
            let locations: [CGFloat] = [ 0.0, 1.0 ]
            let rgbColorspace = CGColorSpaceCreateDeviceRGB()
            gradient = CGGradientCreateWithColors(rgbColorspace, gradientColors, locations)
        }
        if let grad = gradient {
            let path = CGPathCreateMutable()
            CGPathAddArc(path, nil, 0.0, 0.0, (self.bounds.size.width/2)-1, 0, TWO_PI, false)
            CGContextAddPath(context, path)
            CGContextClip(context)
            // Draw it!
            let gradStartPt = CGPointMake(round((self.bounds.size.width/2) * -0.3), round((self.bounds.size.width/2) * -0.3))
            CGContextDrawRadialGradient(context, grad, gradStartPt, 0, gradStartPt, self.bounds.size.width/2, [.DrawsAfterEndLocation])
        }
        CGContextRestoreGState(context)
    }
    
}
