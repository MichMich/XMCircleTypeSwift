//
//  XMCircleTypeView.swift
//  XMCircleTypeSwift
//
//  Created by Michael Teeuw on 01-03-16.
//  Copyright © 2016 Michael Teeuw. All rights reserved.
//

import UIKit

enum XMCircleTypeVerticalAlignment {
    case Outside
    case Center
    case Inside
}

@IBDesignable class XMCircleTypeView: UIView {
    
    /**
     *  Set the text to display in the XMCircleTypeView
     **/
    @IBInspectable var text:String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     *  Set the Text Attributes for the text.
     *  Refer to the Text Attributes documentation for more info.
     **/
    var textAttributes:[String:AnyObject]?  {
        didSet {
            clearKerningCache()
            setNeedsDisplay()
        }
    }
    
    /**
     *  Align the text left, right or center reletive to the baseAngle.
     **/
    @IBInspectable var textAlignment:NSTextAlignment = .Center {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     *  Align the text inside, outside or centered on the circle.
     **/
    @IBInspectable var verticalTextAlignment:XMCircleTypeVerticalAlignment = .Center {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     *  Set the radius of the circle.
     *  When no radius is set, the maximum radius is calculated and used.
     **/
    @IBInspectable var radius:CGFloat? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     * Where on the circle do we want to start typing?
     **/
    @IBInspectable var baseAngle:CGFloat = 0{
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     *  Adjust the spacing of the characters.
     *  1 = default spacing, 0.5 = half spacing, 2 = double spacing, etc ...
     **/
    @IBInspectable var characterSpacing:CGFloat = 1 {
        didSet {
            setNeedsDisplay()
        }
    }

	/**
	*  Flip the text inside out.
	**/
	
	@IBInspectable var flipped = false {
		didSet {
			setNeedsDisplay()
		}
	}
	
    /**
     *  Show some visual guidelines.
     **/
    
    @IBInspectable var visualDebug = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     *  Disable the kerning cache.
     **/
    @IBInspectable var disableKerningCache = false {
        didSet {
            clearKerningCache()
            setNeedsDisplay()
        }
    }
    
    private var circleCenterPoint:CGPoint = CGPointZero
    private var kerningCacheDictionairy:[String:CGFloat] = [:]

    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Subclassing
    
    override func layoutSubviews() {
        self.circleCenterPoint = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        if let text = self.text {
        
            //Get the string size
            let stringSize = NSString(string: text).sizeWithAttributes(textAttributes)
            
            //Get the radius
            let radius = self.radius ?? maximumRadiusWithStringSize(stringSize, andVerticalAlignment: verticalTextAlignment)
            
            //We store both radius and textRadius. Since we might need an
            //unadjusted radius for visual debugging.
            var textRadius = radius
            
            //Handle vertical alignment bij adjusting the textRadius;
            if (self.verticalTextAlignment == .Inside) {
                textRadius = textRadius - stringSize.height;
            } else if (self.verticalTextAlignment == .Center) {
                textRadius = textRadius - stringSize.height/2;
            }
			
			//If the text is flipped upside down, we need to make the radius bigger.
			if flipped {
				textRadius += stringSize.height
			}
            
            //Calculate the angle per charater.
            let circumference:CGFloat = 2 * textRadius * CGFloat(M_PI);
			let anglePerPixel:CGFloat = CGFloat(M_PI) * 2 / circumference * self.characterSpacing * ((flipped) ? -1 : 1);
			
            //Set initial angle.
            var startAngle: CGFloat = 0
            if (self.textAlignment == .Right) {
                startAngle = self.baseAngle - (stringSize.width * anglePerPixel);
            } else if(self.textAlignment == .Left) {
                startAngle = self.baseAngle;
            } else {
                startAngle = self.baseAngle - (stringSize.width * anglePerPixel/2);
            }
            
            //Set drawing context.
            let context = UIGraphicsGetCurrentContext();
            
            //Set helper vars.
            var characterPosition:CGFloat = 0;
            var lastCharacter:String?
            
            //Loop thru characters of string.
            for charIdx in 0..<text.characters.count {
                
                //Set current character.
                let currentCharacter = text.substringWithRange(Range<String.Index>(start: text.startIndex.advancedBy(charIdx), end: text.startIndex.advancedBy(charIdx + 1)))
                
                //Set currenct character size & kerning.
                let stringSize = NSString(string: currentCharacter).sizeWithAttributes(textAttributes)
                var kerning:CGFloat = 0
                if let lastCharacter = lastCharacter {
                    kerning = kerningForCharacter(currentCharacter, afterCharacter: lastCharacter)
                }
                
                //Add half of character width to characterPosition, substract kerning.
                characterPosition += (stringSize.width / 2) - kerning;
                
                //Calculate character Angle
                let angle = characterPosition * anglePerPixel + startAngle;
                
                //Calculate character drawing point.
                let characterPoint = CGPoint(x: textRadius * cos(angle) + circleCenterPoint.x, y: textRadius * sin(angle) + circleCenterPoint.y);
                
                //Strings are always drawn from top left. Calculate the right pos to draw it on bottom center.
                let stringPoint = CGPointMake(characterPoint.x - stringSize.width/2 , characterPoint.y - stringSize.height);
                
                //Save the current context and do the character rotation magic.
                CGContextSaveGState(context);
                CGContextTranslateCTM(context, characterPoint.x, characterPoint.y);
				let flippedAngle:CGFloat = (flipped) ? CGFloat(M_PI) : 0
                let textTransform = CGAffineTransformMakeRotation(angle + CGFloat(M_PI_2) + flippedAngle);
                CGContextConcatCTM(context, textTransform);
                CGContextTranslateCTM(context, -characterPoint.x, -characterPoint.y);
                
                //Draw the character
                NSString(string: currentCharacter).drawAtPoint(stringPoint, withAttributes: textAttributes)
                
                //If we need some visual debugging, draw the visuals.
                if visualDebug {
                    //Show Character BoundingBox
                    UIColor(red: 1, green: 0, blue: 0, alpha: 0.5).setStroke()
                    UIBezierPath(rect: CGRect(x: stringPoint.x, y: stringPoint.y, width: stringSize.width, height: stringSize.height)).stroke()

                    //Show character point
                    UIColor.blueColor().setStroke()
                    UIBezierPath(arcCenter: characterPoint, radius: 1, startAngle: 0, endAngle: 2*CGFloat(M_PI), clockwise: true).stroke()
                }
                
                //Restore context to make sure the rotation is only applied to this character.
                CGContextRestoreGState(context);
                
                //Add the other half of the character size to the character position.
                characterPosition += stringSize.width / 2;
                
                //Stop if we've reached one full circle.
                if characterPosition * anglePerPixel >= CGFloat(M_PI*2) {
                    break;
                }
                
                //store the currentCharacter to use in the next run for kerning calculation.
                lastCharacter = currentCharacter;
            }
            
            if visualDebug {
                UIColor.greenColor().setStroke()
                UIBezierPath(arcCenter: self.circleCenterPoint, radius: radius, startAngle: 0, endAngle: 2*CGFloat(M_PI), clockwise: true).stroke()
                
                let line = UIBezierPath()
                line.moveToPoint(CGPoint(x: self.circleCenterPoint.x, y: self.circleCenterPoint.y - radius))
                line.addLineToPoint(CGPoint(x: self.circleCenterPoint.x, y: self.circleCenterPoint.y + radius))
                line.moveToPoint(CGPoint(x: self.circleCenterPoint.x-radius, y: self.circleCenterPoint.y))
                line.addLineToPoint(CGPoint(x: self.circleCenterPoint.x+radius, y: self.circleCenterPoint.y))
                line.stroke()
            }
            
        }
    }
    
    
    
    // MARK: - Public Methods
    
    func clearKerningCache() {
        self.kerningCacheDictionairy = [:]
    }
    
    func setColor(color:UIColor) {
        if var textAttributes = textAttributes {
            textAttributes[NSForegroundColorAttributeName] = color
            self.textAttributes = textAttributes
        } else {
            self.textAttributes = [NSForegroundColorAttributeName:color]
        }
    }
    
    
    // MARK: - Private Methods
    
    private func initialize() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleMemoryWarning", name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    func handleMemoryWarning() {
        clearKerningCache()
    }
    
    private func maximumRadiusWithStringSize(stringSize:CGSize, andVerticalAlignment verticalAlignment:XMCircleTypeVerticalAlignment) -> CGFloat{
        var radius:CGFloat = (self.bounds.size.width <= self.bounds.size.height) ? self.bounds.size.width / 2: self.bounds.size.height / 2;
        
        if (verticalTextAlignment == .Outside) {
            radius = radius - stringSize.height;
        } else if (verticalTextAlignment == .Center) {
            radius = radius - stringSize.height/2;
        }
        
        return radius;
    }
    
    private func kerningForCharacter(character:String, afterCharacter previousCharacter:String) -> CGFloat {
        
        //Create a unique cache key
        let kerningCacheKey = "\(previousCharacter)\(character)"
        
        //Look for kerning in the cache dictionary. If kerning is found: return.
        if !disableKerningCache {
            if let chachedKerning = kerningCacheDictionairy[kerningCacheKey] {
                return chachedKerning
            }
        }
        
        //Otherwise, calculate.
        let totalSize = NSString(string: "\(previousCharacter)\(character)").sizeWithAttributes(textAttributes).width
        let currentCharacterSize = NSString(string: character).sizeWithAttributes(textAttributes).width
        let previousCharacterSize = NSString(string: previousCharacter).sizeWithAttributes(textAttributes).width
        
        let kerning = (currentCharacterSize + previousCharacterSize) - totalSize;
        
        //Store kerning in cache.
        kerningCacheDictionairy[kerningCacheKey] = kerning
        
        //Return kerning.
        return kerning;
    }
    
    
}
