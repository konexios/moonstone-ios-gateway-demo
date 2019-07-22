//
//  CircleView.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 28/12/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit

class CircleView: UIView {
    
    let millionUnit = 1000000
    let thousandUnit = 10000
    
    var count: Int = 0 {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.setNeedsDisplay()
            }
        }
    }
    
    var infoText: String = ""
    
    var textColor: UIColor = UIColor.white
    var color: UIColor = UIColor.darkGray
    
    func countText() -> String {
        if count >= millionUnit  {
            let double = Double(count) / Double(millionUnit)
            return countText(double) + " M"
        } else if count >= thousandUnit {
            let double = Double(count) / 1000
            return countText(double) + " K"
        } else {
            return "\(count)"
        }
    }
    
    func countText(_ double: Double) -> String {
        let rounded = round(double * 10) / 10
        if rint(rounded) == rounded {
            return String(format: "%.0f", rounded)
        } else {
            return String(format: "%.1f", rounded)
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        // Circle
        
        let size = min(bounds.size.height, bounds.size.width)

        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                radius: size / 2.0,
                                startAngle: 0,
                                endAngle: CGFloat(2 * Double.pi),
                                clockwise: false)
        color.setFill()
        path.fill()
        
        // Info
        
        var infoRect = CGRect()
        
        let infoFont = UIFont.systemFont(ofSize: 13.0)
        let infoColor = textColor
        
        let attributes = [
            NSAttributedStringKey.font : infoFont,
            NSAttributedStringKey.foregroundColor: infoColor
        ]
        
        infoRect.size = infoText.size(withAttributes: attributes)
        infoRect.origin = CGPoint(x: bounds.midX - infoRect.size.width / 2.0,
                                  y: bounds.midY + 5.0)
        
        infoText.draw(in: infoRect, withAttributes: attributes)
        
        // Text
        
        let text = countText()
        
        var textRect = CGRect()
        
        let textFont = UIFont.systemFont(ofSize: 20.0)
        
        let textAttributes = [
            NSAttributedStringKey.font : textFont,
            NSAttributedStringKey.foregroundColor: infoColor
        ]
        
        textRect.size = text.size(withAttributes: textAttributes)
        textRect.origin = CGPoint(x: bounds.midX - textRect.size.width / 2.0,
                                  y: bounds.midY - textRect.size.height / 2.0 - 10)
        
        text.draw(in: textRect, withAttributes: textAttributes)

    }
    
}
