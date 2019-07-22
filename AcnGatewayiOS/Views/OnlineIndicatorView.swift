//
//  OnlineIndicatorView.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 31/05/2017.
//  Copyright © 2017 Arrow Electronics, Inc. All rights reserved.
//

import UIKit

class OnlineIndicatorView: UIView {
    
    var color: UIColor = .green
    var radius: CGFloat = 4.0
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        
        // Circle
        
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
                                radius: radius,
                                startAngle: 0,
                                endAngle: CGFloat(2 * Double.pi),
                                clockwise: false)
        color.setFill()
        path.fill()
    }
}
