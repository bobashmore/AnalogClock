//
//  CAAnalogClock.swift
//  analogClockSwift
//
//  Created by bob.ashmore on 10/02/2016.
//  Copyright © 2016 bob.ashmore. All rights reserved.
//

import UIKit
import CoreGraphics

enum MotionType {
    case type_smooth
    case type_tick
}

enum NumeralType {
    case type_decimal
    case type_roman
}

enum ZoneType {
    case type_local
    case type_utc
}

class CAAnalogClock: CARoundBaseLayer {
    var updateTimer:NSTimer?
    var hourHand:CAShapeLayer?
    var minuteHand:CAShapeLayer?
    var secondHand:CAShapeLayer?
    var currentDay:Int = -1
    var bSmoothMotion:Bool = false
    var clockNumeralType:NumeralType = .type_decimal
    var timeZone:ZoneType = .type_local
    
    override init() {
        super.init()
        setDefaultScheme()
        startUpdates()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setDefaultScheme() {
        self.rimStartColor = UIColor(red:0.580, green:0.580, blue:0.580, alpha:1.0)
        self.rimEndColor = adjustLuminance(rimStartColor, luminanceFactor:0.5)
        self.rimMediumColor = adjustLuminance(rimStartColor, luminanceFactor:1.0)
        self.rimLightColor = adjustLuminance(rimStartColor, luminanceFactor:1.5)
        self.faceStartColor = UIColor(red:0.373, green:0.620, blue:0.905, alpha:1.0)
        self.faceEndColor = adjustLuminance(faceStartColor, luminanceFactor:0.4)
        self.handColor = UIColor(red:246.0/255.0, green:79.0/255.0, blue:71.0/255.0, alpha:1.0)
        self.darkHandColor = adjustLuminance(handColor, luminanceFactor:0.7)
        self.tickColor = UIColor.whiteColor()
        self.numeralColor = UIColor.whiteColor()
        self.bSmoothMotion = false
        self.clockNumeralType = .type_decimal
        self.timeZone = .type_local
    }

    override func drawInContext(context:CGContextRef) {
        // This is the only place where the size of the control can be determined correctly
        self.scaleFactor  = ((self.bounds.size.width < self.bounds.size.height) ? self.bounds.size.width : self.bounds.size.height) / 277
        self.radius       = ((self.bounds.size.width < self.bounds.size.height) ? self.bounds.size.width : self.bounds.size.height) / 2
        
        // build up the clock face
        drawBezeledFace(context)
        
        let fontRef:CTFontRef = CTFontCreateWithName("Helvetica", round(8 * self.scaleFactor), nil)
        let makeColor:UIColor = UIColor(red:0.7, green:0.7, blue:0.7, alpha:0.7)
        drawTextOnArc("designed in Ireland by Bob Ashmore \u{00A9} 2016", context:context, origin:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)), startDegree:180, radius:self.radius-8, fontRef:fontRef, textColor:makeColor, bAntiClockwise:true)
        
        //addTickMarksOnArc(context, origin:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)), radius:self.radius-40, tticks:11, tLenth:3, tWidth:0.5, startDegree:315, endDegree:45, strokeColor:UIColor.whiteColor(),arcWidth:1.0)
        
        drawSmallClockTickmarks(context, radius:self.radius)
        drawClockFace(context, radius:radius)
        drawClockNumerals(context, radius:radius)
        // Add the hands as seperate layers so they can be anumated
        drawClockHands(context, radius:radius)
        // Set the hands to the current time
        updateHands()
    }

    func drawClockFace(context:CGContextRef, radius:CGFloat) {
        let totalTickmarks:Int = 60
        CGContextSaveGState(context)
        CGContextTranslateCTM(context, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        CGContextScaleCTM(context, 1.0, -1.0) // Reverse Y axis only
        
        var tickLength:CGFloat = 0.0
        let rotationAngle = degreesToRadian(360.0/CGFloat(totalTickmarks))
        for i in 0..<totalTickmarks {
            tickLength = (i % 5 == 0) ? 10.0 * self.scaleFactor : 5.0 * self.scaleFactor
            CGContextMoveToPoint(context, 0, radius-tickLength)
            CGContextAddLineToPoint(context, 0, radius)
            CGContextRotateCTM(context, -rotationAngle) // Rotate context to tick start pos on circle
        }
        CGContextSetStrokeColorWithColor(context, self.tickColor.CGColor)
        CGContextSetLineWidth(context, 0.8 * self.scaleFactor)
        CGContextStrokePath(context)
        CGContextRestoreGState(context)
    }

    func drawSmallClockTickmarks(context:CGContextRef, radius:CGFloat) {
        let totalTickmarks:Int = 600
        CGContextSaveGState(context)
        CGContextTranslateCTM(context, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        CGContextScaleCTM(context, 1.0, -1.0) // Reverse Y axis only
        
        let tickLength:CGFloat = 2.5 * self.scaleFactor
        let rotationAngle:CGFloat = degreesToRadian(360.0/CGFloat(totalTickmarks))
        for _ in 0..<totalTickmarks {
            CGContextMoveToPoint(context, 0, radius-tickLength)
            CGContextAddLineToPoint(context, 0, radius)
            CGContextRotateCTM(context, -rotationAngle) // Rotate context to next tick start pos on circle clockwise
        }
        CGContextSetStrokeColorWithColor(context, self.tickColor.CGColor)
        CGContextSetLineWidth(context, 0.3 * self.scaleFactor)
        CGContextStrokePath(context)
        CGContextRestoreGState(context)
    }

    func drawClockNumerals(context:CGContextRef, radius:CGFloat) {
        let decimalNumerals = ["1","2","3","4","5","6","7","8","9","10","11","12"]
        let romanNumerals   = ["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII"]
        CGContextSaveGState(context)
        CGContextTranslateCTM(context, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        CGContextScaleCTM(context, 1.0, -1.0) // Reverse Y axis only
        
        let origin = CGPointMake(0, 0)
        let fontName:String = (self.clockNumeralType == .type_decimal) ? "Helvetica" : "Baskerville"
        let textFontRef:CTFontRef = CTFontCreateWithName(fontName, round(17 * self.scaleFactor), nil)
        
        for hour in 0..<12 {
            if self.clockNumeralType == .type_decimal {
                 drawClockText(decimalNumerals[hour], context:context ,origin:origin, startDegree:(CGFloat(hour)+1.0)*30.0, radius:radius-(21.0 * self.scaleFactor), fontRef:textFontRef, textColor:self.numeralColor)
            }
            else {
                drawClockText(romanNumerals[hour], context:context ,origin:origin, startDegree:(CGFloat(hour)+1.0)*30.0, radius:radius-(21.0 * self.scaleFactor), fontRef:textFontRef, textColor:self.numeralColor)
            }
        }
        
        // Put the Y axis back to standard positive extending down, if we didnt all text would be rendered upside down & back to front
        CGContextScaleCTM(context, 1.0, -1.0)
        let zoneText:String = (self.timeZone == .type_local) ? "LOCAL" : "UTC"
        drawNormalText(zoneText, context:context, origin:origin, x1:0.0, y1:radius * 0.40, align: .ctAlignCenterCenter, fontName:"Helvetica", fontSize:16*self.scaleFactor, textColor:numeralColor)
        
        drawNormalText(getCurrentDate(), context:context, origin:origin, x1:0.0, y1:-radius * 0.40, align: .ctAlignCenterCenter, fontName:"Helvetica", fontSize:12*self.scaleFactor, textColor:numeralColor)
        CGContextRestoreGState(context)
    }
    
    func drawClockHand(context:CGContextRef, radius:CGFloat, length:CGFloat, width:CGFloat, var hand:CAShapeLayer?, actions:[String :CAAction]) ->CAShapeLayer? {
        var path:CGMutablePathRef
        
        if(hand == nil) {
            hand = CAShapeLayer()
        }
        if let hnd = hand {
            hnd.actions = actions
            hnd.bounds = CGRectMake(0.0, 0.0, width * self.scaleFactor, radius * length)
            hnd.anchorPoint = CGPointMake(0.5, 0.8)
            hnd.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
            hnd.lineWidth = (self.scaleFactor < 1.0) ? 0.5  * self.scaleFactor : 0.5
            hnd.strokeColor = self.darkHandColor.CGColor
            hnd.fillColor = self.handColor.CGColor
            hnd.shadowOffset = CGSizeMake(0.0, 3.0)
            hnd.shadowOpacity = 0.3
            hnd.lineCap = kCALineCapRound
            
            let rotationPointY = hand!.bounds.size.height * 0.8
            path = CGPathCreateMutable()
            CGPathMoveToPoint(path, nil, CGRectGetMidX(hnd.bounds), 0)
            CGPathAddLineToPoint(path, nil, hnd.bounds.size.width, rotationPointY)
            CGPathAddLineToPoint(path, nil, CGRectGetMidX(hnd.bounds), hnd.bounds.size.height)
            CGPathAddLineToPoint(path, nil, 0, rotationPointY)
            CGPathAddLineToPoint(path, nil, CGRectGetMidX(hnd.bounds), 0)
            
            hnd.path = path
            self.addSublayer(hnd)
            return hand
        }
        else {
            return nil
        }
    }

    func drawClockHands(context:CGContextRef, radius:CGFloat) {
        // Stop the layer from animating during resizing
        let newActions: [String: CAAction] = [ "onOrderIn" : NSNull() as CAAction, "onOrderOut" : NSNull() as CAAction, "sublayers" : NSNull() as CAAction, "contents" : NSNull() as CAAction, "bounds" : NSNull() as CAAction, "position" : NSNull() as CAAction]
        hourHand = drawClockHand(context, radius:radius, length:0.8, width:10.0, hand:hourHand, actions:newActions)
        minuteHand = drawClockHand(context, radius:radius, length:1.0, width:6.0, hand:self.minuteHand, actions:newActions)
        secondHand = drawClockHand(context, radius:radius, length:1.2, width:4.0, hand:self.secondHand, actions:newActions)
        
        // Draw the center Boss
        if myBossLayer == nil {
            myBossLayer = CABossLayer()
        }
        if let mbs = myBossLayer {
            mbs.actions = newActions
            mbs.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
            mbs.bounds = CGRectIntegral(CGRectMake(0.0, 0.0, radius * 0.3, radius * 0.3))
            mbs.startColor = faceStartColor
            mbs.endColor = faceEndColor
            self.addSublayer(mbs)
            mbs.setNeedsDisplay()
        }
    }
    
    func updateHands() {
        if self.bSmoothMotion == true {
            updateHandsSmooth()
        }
        else {
            updateHandsTick()
        }
    }
    
    func updateHandsTick() {
        // Get the Local set in the iphone and retrive its name
        let cal = NSCalendar.currentCalendar()
        let timeZone = NSTimeZone.localTimeZone()
        var tzName = timeZone.name
        
        // now set the displayed zone according to user requirements
        if self.timeZone != .type_local {
            tzName = "UTC"
        }
        if let zone = NSTimeZone(name:tzName) {
            cal.timeZone = zone
        }
        
        // Now get the current time
        let comps = cal.components([NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second], fromDate: NSDate())
        // if the day has changed then update the date on Clockface
        if(comps.day != currentDay) {
            currentDay = comps.day
            setNeedsDisplay()
        }
        
        let minutesIntoDay:Int = Int(comps.hour * 60 + comps.minute)
        let elapsedHours   = CGFloat(minutesIntoDay) / (720.0) // devide by 1440 for 24 hour clock
        let elapsedMinutes = CGFloat(comps.minute) / 60.0
        let elapsedSeconds = CGFloat(comps.second) / 60.0
        if let sHand = secondHand {
            sHand.transform = CATransform3DMakeRotation(TWO_PI * elapsedSeconds, 0, 0, 1)
        }
        if let mHand = minuteHand {
            mHand.transform = CATransform3DMakeRotation(TWO_PI * elapsedMinutes, 0, 0, 1)
        }
        if let hHand = hourHand {
            hHand.transform   = CATransform3DMakeRotation(TWO_PI * elapsedHours, 0, 0, 1)
        }
    }
    
    func getCurrentDate() -> String {
        var tzName = NSTimeZone.localTimeZone().name
        // now set the displayed zone according to user requirements
        if timeZone != .type_local {
            tzName = "UTC"
        }
        
        // Need to get the time to nearest millisecond for smooth motion
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: tzName)
        dateFormatter.dateFormat = "d MMM y"
        return dateFormatter.stringFromDate(NSDate())
    }
    
    func updateHandsSmooth() {
        var tzName = NSTimeZone.localTimeZone().name
        // now set the displayed zone according to user requirements
        if timeZone != .type_local {
            tzName = "UTC"
        }

        let cal = NSCalendar.currentCalendar()
        if let zone = NSTimeZone(name:tzName) {
            cal.timeZone = zone
        }
        let comps = cal.components([NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second], fromDate: NSDate())
        // if the day has changed then update the date on Clockface
        if(comps.day != currentDay) {
            currentDay = comps.day
            setNeedsDisplay()
        }

        // Need to get the time to nearest millisecond for smooth motion
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: tzName)
        dateFormatter.dateFormat = "hh:mm:ss.SSS"
        let string = dateFormatter.stringFromDate(NSDate())
        let timeComponents:[String] = string.componentsSeparatedByString(":")
        // parse out the time components using optional chaining
        if let hour:Int = Int(timeComponents[0]), min:Int  = Int(timeComponents[1]),sec:Float = Float(timeComponents[2]) {
            let floatSec:CGFloat = CGFloat(sec)
            let floatMin = CGFloat(min) + (floatSec / 60.0)
            let floatHour = CGFloat(hour) + (floatMin / 60.0)
            // Only process the animations if the layers exist
            if let sHand = secondHand {
                sHand.transform = CATransform3DMakeRotation(TWO_PI * (floatSec/60), 0, 0, 1)
            }
            if let mHand = minuteHand {
                mHand.transform = CATransform3DMakeRotation(TWO_PI * (floatMin/60), 0, 0, 1)
            }
            if let hHand = hourHand {
                hHand.transform   = CATransform3DMakeRotation(TWO_PI * (floatHour/12), 0, 0, 1)
            }
        }
    }

    func startUpdates() {
        // run the timer in common mode so that it fires even when ui is scrolling or touches are working
        // if user requires smooth motion of the second then we will fire the time every 100th of a second
        // otherwise just use 1 second interval no point in abusing the CPU
        let timerInterval = (self.bSmoothMotion) ? 0.01 : 1.0
        updateTimer = NSTimer(timeInterval: timerInterval, target: self, selector: "updateHands", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(updateTimer!, forMode: NSRunLoopCommonModes)
    }
    
    func stopUpdates() {
        updateTimer!.invalidate()
    }
    
    func setNumeralType(type:NumeralType) {
        clockNumeralType = type
        self.setNeedsDisplay()
    }
    
    func getNumeralType() -> NumeralType {
        return clockNumeralType
    }
    
    func setZoneType(type:ZoneType) {
        timeZone = type
        setNeedsDisplay()
    }
    
    func getZoneType() -> ZoneType {
        return timeZone
    }
    
    func setMotionType(motionType:MotionType) {
        stopUpdates()
        if(motionType == .type_smooth) {
            self.bSmoothMotion = true
        }
        else {
            self.bSmoothMotion = false
        }
        updateHands()
        startUpdates()
    }
    
    func getMotionType() -> MotionType {
        if(self.bSmoothMotion == true) {
            return .type_smooth
        }
        else {
            return .type_tick
        }
    }
    
    func setWithColorSchemeFace(face:UIColor, rim:UIColor, hands:UIColor, ticks:UIColor, numerials:UIColor, solidFace:Bool, numeralType:NumeralType, zoneType:ZoneType, motionType:MotionType) {
        setColorSchemeFace(face, rim:rim, hands:hands, ticks:ticks, numerals:numerials, bSolidFace:solidFace)
        self.clockNumeralType = numeralType
        self.timeZone = zoneType
        if(motionType == .type_smooth) {
            self.bSmoothMotion = true
        }
        else {
            self.bSmoothMotion = false
        }
    }


}
