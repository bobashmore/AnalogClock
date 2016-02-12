//
//  ViewController.swift
//  analogClockSwift
//
//  Created by bob.ashmore on 09/02/2016.
//  Copyright © 2016 bob.ashmore. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var myControl:UIAnalogClock?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //myControl = UIAnalogClock(frame: CGRectMake(10,10,300,300))
        myControl = UIAnalogClock()
        if let ctl = myControl {
            ctl.setMotionType(.type_smooth)
            ctl.setZoneType(.type_utc)
            ctl.solidFace(false)
            self.view.addSubview(ctl)
            setupConstraints(ctl, mainView: self.view)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func setupConstraints(subView:UIView, mainView:UIView)
    {
        subView.translatesAutoresizingMaskIntoConstraints = false

        let width:NSLayoutConstraint = NSLayoutConstraint(item: subView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Width, multiplier: 0.95, constant: 0)
        mainView.addConstraint(width)

        let height:NSLayoutConstraint = NSLayoutConstraint(item: subView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Height, multiplier: 0.95, constant: 0)
        mainView.addConstraint(height)

        let top:NSLayoutConstraint = NSLayoutConstraint(item: subView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        mainView.addConstraint(top)

        let bottom:NSLayoutConstraint = NSLayoutConstraint(item: subView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        mainView.addConstraint(bottom)
    }
    
    // Make sure the control is informed of any size or oriantation changes in the view
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if let ctl = myControl {
            ctl.setNeedsDisplay()
        }
        
    }


}

