//
//  AcnButton.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 05/06/2017.
//  Copyright © 2017 Arrow Electronics, Inc. All rights reserved.
//

import UIKit

class AcnButton: UIButton {
    
    let arrowSize: CGFloat = 37.0
    
    var downArrow: UILabel?
    
    var isArrowHidden: Bool = false {
        didSet {
            downArrow?.isHidden = isArrowHidden
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        downArrow = UILabel(frame: CGRect(x: frame.size.width - arrowSize, y: 0.0, width: arrowSize, height: arrowSize))
        downArrow?.textAlignment = .center
        downArrow?.textColor = .white
        downArrow?.text = "▼"
        addSubview(downArrow!)
        
        titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 0.0)

        backgroundColor = .gray1
        
        layer.borderColor = UIColor.gray2.cgColor
        layer.borderWidth = 1.0
    }

}
