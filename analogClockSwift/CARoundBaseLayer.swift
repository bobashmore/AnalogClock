//
//  CARoundBaseLayer.swift
//  analogClockSwift
//
//  Created by bob.ashmore on 09/02/2016.
//  Copyright © 2016 bob.ashmore. All rights reserved.
//

import UIKit
import QuartzCore
import CoreText

enum textAlignTypes {
    case ctAlignTopLeft
    case ctAlignTopCenter
    case ctAlignTopRight
    case ctAlignCenterLeft
    case ctAlignCenterCenter
    case ctAlignCenterRight
    case ctAlignBottomLeft
    case ctAlignBottomCenter
    case ctAlignBottomRight
}

func degreesToRadian(x: CGFloat) -> CGFloat {
    return (CGFloat(M_PI) * x / 180.0)
}

func radiansToDegrees(x: CGFloat) -> CGFloat {
    return (180.0 * x / CGFloat(M_PI))
}

class CARoundBaseLayer: CALayer {
    var faceStartColor: UIColor = UIColor.blackColor()
    var faceEndColor: UIColor = UIColor.blackColor()
    var rimStartColor: UIColor = UIColor.blackColor()
    var rimEndColor: UIColor = UIColor.blackColor()
    var handColor: UIColor = UIColor.blackColor()
    var darkHandColor: UIColor = UIColor.blackColor()
    var tickColor: UIColor = UIColor.blackColor()
    var numeralColor: UIColor = UIColor.blackColor()
    var rimMediumColor: UIColor = UIColor.blackColor()
    var rimLightColor: UIColor = UIColor.blackColor()
    var myBossLayer: CABossLayer?
    var outerRimGradient: CGGradientRef?
    var innerRimGradient: CGGradientRef?
    var faceGradient: CGGradientRef?
    var scaleFactor: CGFloat = 0.0
    var radius: CGFloat = 0.0
    var bSolidcolorFace: Bool = false

    
    func drawBezeledFace(context: CGContextRef)
    {
        CGContextSaveGState(context)
        CGContextTranslateCTM(context, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
    
        processOuterBezelGradient(context, startColor: rimStartColor, midColor: rimMediumColor, lightColor: rimLightColor, endColor: rimEndColor, radius: radius)
        radius -= 10.0 * scaleFactor
        processGradient(context,startColor:rimEndColor, endColor:rimStartColor, radius:radius, gradient:innerRimGradient)
        radius -= 10 * scaleFactor
        if(self.bSolidcolorFace) {
            processFaceSolid(context, faceColor:faceStartColor, radius:radius)
        }
        else {
            processGradient(context,startColor:faceStartColor, endColor:faceEndColor, radius:radius, gradient:faceGradient)
        }
        CGContextRestoreGState(context)
    }
 
    func processOuterBezelGradient(context: CGContextRef, startColor:UIColor, midColor:UIColor, lightColor:UIColor, endColor: UIColor, radius:CGFloat)
    {
        if(outerRimGradient == nil) {
            let gradientColors: [AnyObject] = [startColor.CGColor, midColor.CGColor, lightColor.CGColor, midColor.CGColor, endColor.CGColor]
            let locations: [CGFloat] = [ 0.0, 0.4, 0.5, 0.6, 1.0 ]
            let rgbColorspace = CGColorSpaceCreateDeviceRGB()
            outerRimGradient = CGGradientCreateWithColors(rgbColorspace, gradientColors, locations)
        }
        if let grad = outerRimGradient {
            let path = CGPathCreateMutable()
            CGPathAddArc(path, nil, 0.0, 0.0, radius, 0, TWO_PI, false)
            CGContextAddPath(context, path)
            CGContextClip(context)
            CGContextDrawLinearGradient(context, grad, CGPointMake(-radius, -radius), CGPointMake(radius, radius), [])
        }
    }

    func processGradient(context: CGContextRef, startColor: UIColor, endColor: UIColor, radius:CGFloat, var gradient:CGGradientRef?)
    {
        if(gradient == nil) {
            let gradientColors: [AnyObject] = [startColor.CGColor, endColor.CGColor]
            let flocations: [CGFloat] = [ 0.0, 1.0 ]
            let rgbColorspace = CGColorSpaceCreateDeviceRGB()
            gradient = CGGradientCreateWithColors(rgbColorspace, gradientColors, flocations)
        }
        if let grad = gradient {
            let path = CGPathCreateMutable()
            CGPathAddArc(path, nil, 0.0, 0.0, radius, 0, TWO_PI, false)
            CGContextAddPath(context, path)
            CGContextClip(context)
            CGContextDrawLinearGradient(context, grad, CGPointMake(-radius, -radius), CGPointMake(radius, radius), [])
        }
    }
    
    func processFaceSolid(context: CGContextRef, faceColor: UIColor, radius: CGFloat)
    {
        faceGradient = nil
        var path = CGPathCreateMutable()
        CGPathAddArc(path, nil, 0.0, 0.0, radius, 0, TWO_PI, false)
        CGContextAddPath(context, path)
        CGContextClip(context)
        CGContextSetFillColorWithColor(context, faceColor.CGColor)
        
        path = CGPathCreateMutable()
        CGPathAddArc(path, nil, 0.0, 0.0, radius, 0, TWO_PI, false)
        CGContextAddPath(context, path)
        CGContextFillPath(context)
    }

    func removeGradients()
    {
        outerRimGradient = nil
        innerRimGradient = nil
        faceGradient = nil
    }

    func drawClockText(text: String, context: CGContextRef, origin: CGPoint, var startDegree: CGFloat, radius: CGFloat, fontRef:CTFontRef, textColor: UIColor)
    {
        CGContextSaveGState(context)
        
        startDegree = 180 - (startDegree + 90.0)
        let shadowColor = UIColor(red:0.151, green:0.152, blue:0.151, alpha:1.000)
        CGContextSetShadowWithColor(context, CGSizeMake(1, 1), 0, shadowColor.CGColor)
        let mx  = floor(radius * cos(degreesToRadian(startDegree))) + 0.5
        let my  = floor(radius * sin(degreesToRadian(startDegree))) + 0.5
        
        // Create an attributed string
        let attributes = [ NSFontAttributeName: fontRef, NSForegroundColorAttributeName: textColor ]
        let attString = NSAttributedString(string: text, attributes: attributes)
        
        // Create a text line from the attributed string
        let line: CTLineRef = CTLineCreateWithAttributedString(attString)
        let runArray = ((CTLineGetGlyphRuns(line) as [AnyObject]) as! [CTRunRef])
        let lineMetrics: CGSize = measureLine(line, context:context)
        
        // Draw the runs in our case there will allways be only 1 run
        for runIndex in 0..<CFArrayGetCount(runArray) {
            let run: CTRunRef = runArray[runIndex]
            var textMatrix = CTRunGetTextMatrix(run)
            textMatrix.tx = floor(mx - (lineMetrics.width / 2.0))
            textMatrix.ty = floor(my - (lineMetrics.height / 2.0))
            CGContextSetTextMatrix(context, textMatrix)
            CTRunDraw(run, context, CFRangeMake(0, 0))
        }
        CGContextRestoreGState(context)
    }
    
    func measureLine(line: CTLineRef, context: CGContextRef) ->CGSize
    {
        var textHeight: CGFloat = 0.0
        var ascent:CGFloat = 0.0
        var descent:CGFloat = 0.0
        var leading:CGFloat = 0.0
        var width:Double = 0.0
        
        width = CTLineGetTypographicBounds(line, &ascent,  &descent, &leading)
        
        textHeight = floor(ascent * 0.8)
        return CGSizeMake(ceil(CGFloat(width)), ceil(textHeight))
    }
    
    func adjustLuminance(currentRGB: UIColor, luminanceFactor: CGFloat) -> UIColor
    {
        var hue: CGFloat = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        if currentRGB.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            brightness += (luminanceFactor-1.0)
            brightness = max(min(brightness, 1.0), 0.0)
            return UIColor(hue:hue, saturation:saturation, brightness:brightness, alpha:alpha)
        }
        
        var white: CGFloat = 0.0
        if currentRGB.getWhite(&white, alpha:&alpha) {
            white += (luminanceFactor-1.0)
            white = max(min(white, 1.0), 0.0)
            return UIColor(white: white, alpha:alpha)
        }
        return currentRGB
    }
    
    func drawNormalText(text:String, context:CGContextRef, origin:CGPoint, x1:CGFloat, y1:CGFloat, align:textAlignTypes, fontName:String, fontSize:CGFloat, textColor:UIColor)
    {
        CGContextSaveGState(context)
        
        let shadowColor = UIColor(red:0.151, green:0.152, blue:0.151, alpha:1.000)
        CGContextSetShadowWithColor(context, CGSizeMake(1, 1), 0, shadowColor.CGColor)
        CGContextTranslateCTM(context, origin.x, origin.y) // move origin to center
        CGContextScaleCTM(context, 1.0, -1.0) // Reverse Y axis only
        
        // Create an attributed string
        let fontRef = CTFontCreateWithName(fontName, fontSize, nil)
        let attributes = [ NSFontAttributeName: fontRef, NSForegroundColorAttributeName: textColor ]
        let attString = NSAttributedString(string: text, attributes: attributes)
        
        // Create a text line from the attributed string
        let line:CTLineRef = CTLineCreateWithAttributedString(attString)
        let runArray = ((CTLineGetGlyphRuns(line) as [AnyObject]) as! [CTRunRef])
        let lineMetrics:CGSize = measureLine(line,context:context)
        for runIndex in 0..<CFArrayGetCount(runArray) {
            let run: CTRunRef = runArray[runIndex]
            var textMatrix:CGAffineTransform = CTRunGetTextMatrix(run)
            switch (align) {
                case .ctAlignTopLeft:
                    textMatrix.tx = x1
                    textMatrix.ty = y1 - lineMetrics.height
                
                case .ctAlignTopCenter:
                    textMatrix.tx = x1 + (lineMetrics.width / 2.0)
                    textMatrix.ty = y1 - lineMetrics.height
                
                case .ctAlignTopRight:
                    textMatrix.tx = x1 + lineMetrics.width
                    textMatrix.ty = y1 - lineMetrics.height
                
                case .ctAlignCenterLeft:
                    textMatrix.tx = x1
                    textMatrix.ty = y1 - (lineMetrics.height / 2.0)
                
                case .ctAlignCenterCenter:
                    textMatrix.tx = x1 - (lineMetrics.width / 2.0)
                    textMatrix.ty = y1 - (lineMetrics.height / 2.0)
                
                case .ctAlignCenterRight:
                    textMatrix.tx = x1 - lineMetrics.width
                    textMatrix.ty = y1 - (lineMetrics.height / 2.0)
                
                case .ctAlignBottomLeft:
                    textMatrix.tx = x1
                    textMatrix.ty = y1
                
                case .ctAlignBottomCenter:
                    textMatrix.tx = x1 - (lineMetrics.width / 2.0)
                    textMatrix.ty = y1
                
                case .ctAlignBottomRight:
                    textMatrix.tx = x1 - lineMetrics.width
                    textMatrix.ty = y1
                
             }
            CGContextSetTextMatrix(context, textMatrix)
            CTRunDraw (run, context, CFRangeMake(0, 0))
        }
        CGContextRestoreGState(context)
    }
    
    func setColorSchemeFace(face:UIColor, rim:UIColor, hands:UIColor, ticks:UIColor, numerals:UIColor, bSolidFace:Bool)
    {
        self.bSolidcolorFace = bSolidFace
        self.rimStartColor = rim
        self.rimEndColor = adjustLuminance(rimStartColor, luminanceFactor:0.5)
        self.rimMediumColor = adjustLuminance(rimStartColor, luminanceFactor:0.8)
        self.rimLightColor = adjustLuminance(rimStartColor, luminanceFactor:1.5)
        self.faceStartColor = face
        self.faceEndColor = adjustLuminance(faceStartColor, luminanceFactor:0.4)
        self.handColor = hands
        self.darkHandColor = adjustLuminance(handColor, luminanceFactor:0.7)
        self.tickColor = ticks
        self.numeralColor = numerals
        removeGradients()
        if(myBossLayer != nil) {
            myBossLayer!.removeGradient()
        }
        self.setNeedsDisplay()
    }

    func drawTextOnArc(text:String, context:CGContextRef, origin:CGPoint, var startDegree:CGFloat, radius:CGFloat, fontRef:CTFontRef, textColor:UIColor, bAntiClockwise:Bool) {
        CGContextSaveGState(context);
        startDegree = 360.0 - startDegree;
        
        let shadowColor = UIColor(red:0.151, green:0.152, blue:0.151, alpha:1.000)
        CGContextSetShadowWithColor(context, CGSizeMake(1, 1), 0, shadowColor.CGColor)
        
        if bAntiClockwise {
            startDegree = (startDegree < 180) ? startDegree + 180.00 : startDegree - 180.0
        }
        
        // Create an attributed string
        let attributes = [ NSFontAttributeName: fontRef, NSForegroundColorAttributeName: textColor ]
        let attString = NSAttributedString(string: text, attributes: attributes)

        // Create a text line from the attributed string
        let line:CTLineRef = CTLineCreateWithAttributedString(attString)
        let runArray = ((CTLineGetGlyphRuns(line) as [AnyObject]) as! [CTRunRef])
        let runCount = CFArrayGetCount(runArray)
        let glyphCount = CTLineGetGlyphCount(line)
        
        // Create an array to hold the width of each Glyph
        var widthArray: [CGFloat] = []
        
        // Fill the array with the width of each Glyph
        var glyphOffset:CFIndex = 0;
        
        for runIndex in 0..<CFArrayGetCount(runArray) {
            let run: CTRunRef = runArray[runIndex]
            let runGlyphCount:CFIndex = CTRunGetGlyphCount(run); // Get the number of Glyphs in this run
            for runGlyphIndex in 0..<runGlyphCount {
                let widthValue = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(runGlyphIndex, 1), nil, nil, nil))
                widthArray.insert(widthValue, atIndex: (runGlyphIndex + glyphOffset))
            }
            glyphOffset = runGlyphCount + 1
        }
        
        // Get the line length in points
        let lineLength = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        // Calculate the arc on which to print the string
        let circumference:CGFloat = (CGFloat(M_PI) * 2.0 * radius)
        let arcDegree = 360.0 * (lineLength / circumference)
        let arcStartDegree = (arcDegree / 2.0) + startDegree
        
        // Calculate the angle at which the individual glyphs must be printed on the arc (Tangent to arc)
        var angleArray:[CGFloat] = []
        
        var prevHalfWidth:CGFloat =  widthArray[0] / 2.0;
        let angleValue:CGFloat = (prevHalfWidth / lineLength) * degreesToRadian(arcDegree)
        angleArray.append(angleValue) // This is the angle to print the glyph at
        
        //for(var lineGlyphIndex:CFIndex = 1; lineGlyphIndex < glyphCount; lineGlyphIndex++) {
        for lineGlyphIndex in 1..<glyphCount {
            let halfWidth = widthArray[lineGlyphIndex] / 2.0
            let prevCenterToCenter = prevHalfWidth + halfWidth;
            let angleValue = (prevCenterToCenter / lineLength) * degreesToRadian(arcDegree)
            angleArray.insert(angleValue, atIndex:lineGlyphIndex)
            prevHalfWidth = halfWidth;
        }
        
        // Reverse the Y axis of the context and rotate counter clockwise by 90 degrees
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextTranslateCTM(context, origin.x, origin.y); // move origin to center
        
        if bAntiClockwise {
            CGContextScaleCTM(context, -1.0, -1.0); // Reverse X and Y axis
        }
        else {
            CGContextScaleCTM(context, 1.0, -1.0); // Reverse Y axis only
        }
        
        CGContextRotateCTM(context, degreesToRadian(arcStartDegree)); // Rotate context to text start pos on circle
        
        var textPosition:CGPoint
        if(bAntiClockwise) {
            textPosition = CGPointMake(0.0, -radius); // Start position of text reverse radius
            CGContextSetTextPosition(context, textPosition.x, textPosition.y);
        }
        else {
            textPosition = CGPointMake(0.0, radius); // Start position of text radius
            CGContextSetTextPosition(context, textPosition.x, textPosition.y);
        }
        
        glyphOffset = 0;
        // Process each Run in the line
        // A run is a consective set of Glyphs with the same attributes
        for runIndex in 0..<runCount {
            let run: CTRunRef = runArray[runIndex]
            let runGlyphCount:CFIndex = CTRunGetGlyphCount(run);
            let runFont = unsafeBitCast(CFDictionaryGetValue(CTRunGetAttributes(run), unsafeBitCast(kCTFontAttributeName, UnsafePointer<Void>.self)), CTFontRef.self)
            
            // Process each Glyph in the run
            for runGlyphIndex in 0..<runGlyphCount {
                let glyphRange:CFRange = CFRangeMake(runGlyphIndex, 1);
                // Get the x,y position for the Glyph
                CGContextRotateCTM(context, -angleArray[runGlyphIndex + glyphOffset])
                let glyphWidth = widthArray[runGlyphIndex + glyphOffset]
                let halfGlyphWidth = glyphWidth / 2.0;
                let positionForThisGlyph = CGPointMake(textPosition.x - halfGlyphWidth, textPosition.y);
                textPosition.x -= glyphWidth;
            
                // Now rotate to popsition the glyph around the circle
                var textMatrix:CGAffineTransform = CTRunGetTextMatrix(run);
                if(bAntiClockwise) {
                    textMatrix = CGAffineTransformScale(textMatrix,-1.0,1.0); // Reverse X axis
                    textMatrix.tx = -positionForThisGlyph.x; // negate x to agree with reversed x axis
                }
                else {
                    textMatrix.tx = positionForThisGlyph.x;
                }
                textMatrix.ty = positionForThisGlyph.y;
                CGContextSetTextMatrix(context, textMatrix);
        
                let cgFont:CGFontRef = CTFontCopyGraphicsFont(runFont, nil);
                var glyph:CGGlyph = 0
                var position:CGPoint = CGPointZero
        
                CTRunGetGlyphs(run, glyphRange, &glyph);
                CTRunGetPositions(run, glyphRange, &position);
        
                // Setup the context attributes and render the glyph onto the context
                CGContextSetFont(context, cgFont);
                CGContextSetFontSize(context, CTFontGetSize(runFont));
                CGContextSetFillColorWithColor(context, textColor.CGColor);
                CGContextShowGlyphsAtPositions(context, &glyph, &position, 1);
            }
            glyphOffset += runGlyphCount;
        }
        CGContextRestoreGState(context);
    }

    func addTickMarksOnArc(context:CGContextRef, origin:CGPoint, radius:CGFloat, var tticks:Int, var tLenth:CGFloat, tWidth:CGFloat, startDegree:CGFloat, endDegree:CGFloat, strokeColor:UIColor, arcWidth:CGFloat)
    {
        CGContextSaveGState(context);
        // Dont want a devide by zero error
        tticks = (tticks == 0) ? 1 : tticks
        
        let totalDegrees:CGFloat
        var x1,x2,y1,y2:CGFloat
        
        tLenth = tLenth * self.scaleFactor
        
        // want my origin at center and 0 degrees at top
        CGContextTranslateCTM(context, origin.x, origin.y) // move origin to center
        CGContextRotateCTM(context, -CGFloat(M_PI_2)) // rotate 90 degrees anticlockwise

        if arcWidth > 0.01 {
            CGContextSaveGState(context)
            CGContextAddArc(context, 0, 0, radius, degreesToRadian(startDegree), degreesToRadian(endDegree ), 0)
            CGContextSetStrokeColorWithColor(context, strokeColor.CGColor)
            CGContextSetLineWidth(context, arcWidth*self.scaleFactor)
            CGContextStrokePath(context)
            CGContextRestoreGState(context)
        }

        if startDegree > endDegree {
            totalDegrees = 360.0 - startDegree + endDegree
        }
        else {
            totalDegrees = endDegree - startDegree
        }
        
        let dxTicks = totalDegrees / CGFloat(tticks-1)
        var currentDegree:Int
        for i in 0..<tticks {
            currentDegree = Int(((startDegree + (CGFloat(i) * dxTicks))) % 360)
            x1  = cos(degreesToRadian(CGFloat(currentDegree))) * radius
            y1  = sin(degreesToRadian(CGFloat(currentDegree))) * radius
            x2  = cos(degreesToRadian(CGFloat(currentDegree))) * (radius-tLenth)
            y2  = sin(degreesToRadian(CGFloat(currentDegree))) * (radius-tLenth)
            CGContextMoveToPoint(context, x1, y1)
            CGContextAddLineToPoint(context, x2, y2)
        }
        
        CGContextSetStrokeColorWithColor(context, strokeColor.CGColor)
        CGContextSetLineWidth(context, tWidth*self.scaleFactor)
        CGContextStrokePath(context)
        CGContextRestoreGState(context)
    }

    
}
