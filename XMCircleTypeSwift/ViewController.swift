//
//  ViewController.swift
//  XMCircleTypeSwift
//
//  Created by Michael Teeuw on 01-03-16.
//  Copyright © 2016 Michael Teeuw. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var circleTypeView: XMCircleTypeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        circleTypeView.text = "XMCircleType allows you to display a circled text. It will take kerning into account."
        circleTypeView.textAttributes = [NSFontAttributeName:UIFont(name: "AmericanTypewriter", size: 15)!]
        circleTypeView.textAlignment = .Center;
        circleTypeView.verticalTextAlignment = .Outside;
        
        circleTypeView.baseAngle = -CGFloat(M_PI_2)
        circleTypeView.characterSpacing = 0.9;
        
    }
}

