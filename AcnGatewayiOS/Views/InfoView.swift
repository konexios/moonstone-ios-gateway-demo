//
//  InfoView.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import UIKit

/// The view class to hold icon and text with two
/// lines at top and bottom
class InfoView: UIView {
    
    // all views are tagged in IB
    var topLine: UIView?       // tag - 1
    var bottomLine: UIView?    // tag - 2
    var label: UILabel?        // tag - 3
    var icon: UIImageView?     // tag - 4

    override func awakeFromNib() {
        super.awakeFromNib()
        
        topLine = viewWithTag(1)
        bottomLine = viewWithTag(2)
        icon = viewWithTag(4) as? UIImageView
        label = viewWithTag(3) as? UILabel
    }
    
    /// set main color for all elements
    var mainColor = UIColor.white {
        didSet {
            topLine?.backgroundColor = mainColor
            bottomLine?.backgroundColor = mainColor
            icon?.tintColor = mainColor
            label?.textColor = mainColor
        }
    }
    
    /// set predefinded icon image
    var iconType: ImageIconKeys = .infoCircle {
        didSet {
            icon?.image = UIImageView.templateImage(iconType)
            icon?.tintColor = mainColor
        }
    }
    
    /// set text and set info icon
    var infoText = "" {
        didSet {
            iconType = .infoCircle
            label?.text = infoText
        }
    }
    
    /// set text and set warning (error) icon
    var warnText = "" {
        didSet {
            iconType = .exclamationTriangle
            label?.text = warnText
        }
    }

    /// set text and set waiting icon
    var waitText = "" {
        didSet {
            iconType = .clock
            label?.text = waitText
        }
    }
    
    /// set text and set success icon
    var successText = "" {
        didSet {
            iconType = .checkmark
            label?.text = successText
        }
    }
}
