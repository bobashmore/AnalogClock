//
//  UIAnalogClock.swift
//  analogClockSwift
//
//  Created by bob.ashmore on 10/02/2016.
//  Copyright © 2016 bob.ashmore. All rights reserved.
//

import UIKit

class UIAnalogClock: UIControl {

    var clockFaceLayer:CAAnalogClock?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clockFaceLayer = CAAnalogClock()
        setupClockLayer()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        clockFaceLayer = CAAnalogClock()
        setupClockLayer()
    }
    
    func setupClockLayer() {
        backgroundColor = UIColor.clearColor()
        let width = ((self.bounds.size.width < self.bounds.size.height) ? self.bounds.size.width : self.bounds.size.height)
        
        // Stop the layer from animating during resizing
        let newActions: [String: CAAction] = [ "onOrderIn" : NSNull() as CAAction, "onOrderOut" : NSNull() as CAAction, "sublayers" : NSNull() as CAAction, "contents" : NSNull() as CAAction, "bounds" : NSNull() as CAAction, "position" : NSNull() as CAAction]
        if let cLayer = clockFaceLayer {
            cLayer.contentsScale = UIScreen.mainScreen().scale
            cLayer.actions = newActions
            cLayer.bounds = CGRectMake(0.0, 0.0, width, width)
            cLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
            cLayer.anchorPoint = CGPointMake(0.5, 0.5)
            self.layer.addSublayer(cLayer)
            cLayer.setNeedsDisplay()
        }
    }
    func setMotionType(motionType:MotionType) {
        if let cLayer = clockFaceLayer {
            cLayer.setMotionType(motionType)
        }
    }

    func setNumeralType(type:NumeralType) {
        if let cLayer = clockFaceLayer {
            cLayer.setNumeralType(type)
        }
    }

    func setZoneType(type:ZoneType) {
        if let cLayer = clockFaceLayer {
            cLayer.setZoneType(type)
        }
    }

    func solidFace(type:Bool) {
        if let cLayer = clockFaceLayer {
            cLayer.bSolidcolorFace = type
        }
    }

    override func drawRect(rect: CGRect) {
        adjustClockLayer()
    }
    
    func adjustClockLayer()
    {
        let width:CGFloat = ((self.bounds.size.width < self.bounds.size.height) ? self.bounds.size.width : self.bounds.size.height)
        if let cLayer = clockFaceLayer {
            cLayer.bounds = CGRectMake(0.0, 0.0, width, width)
            cLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
            cLayer.setNeedsDisplay()
        }
    }

    init(face:UIColor, rim:UIColor, hands:UIColor, ticks:UIColor, numerials:UIColor, bSolidFace:Bool, numeralType:NumeralType, zoneType:ZoneType, motionType:MotionType)
    {
        super.init(frame: CGRectMake(0, 0, 10, 10))
        clockFaceLayer = CAAnalogClock()
        setupClockLayer()
        if let cLayer = clockFaceLayer {
            cLayer.setColorSchemeFace(face, rim: rim, hands: hands, ticks: ticks, numerals: numerials, bSolidFace: bSolidFace)
        }
    }
    


}
