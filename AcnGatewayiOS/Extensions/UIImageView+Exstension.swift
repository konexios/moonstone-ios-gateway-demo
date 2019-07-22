//
//  UIImage+Exstension.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import UIKit

enum ImageIconKeys: String {
    case fail                     = "ic-fail"
    case checkmark                = "ic-checkmark"
    case checkmarkCircle          = "ic-checkmark-circle"
    case clock                    = "ic-clock"
    case exclamationTriangle      = "ic-exclamation-triangle"
    case infoCircle               = "ic-info-circle"
    case exclamationTriangleSmall = "ic-exclamation-triangle-37x37"
    case cloudDownload            = "im-fw-update"
}

extension UIImageView {
    
    static var iconFail: UIImageView {
        return UIImageView.imageViewWithIconName( ImageIconKeys.fail.rawValue )
    }
    
    static var iconCheckmark: UIImageView {
        return UIImageView.imageViewWithIconName( ImageIconKeys.checkmark.rawValue )
    }
    
    static var iconExclamationTriangleSmall: UIImageView {
        return UIImageView.imageViewWithIconName( ImageIconKeys.exclamationTriangleSmall.rawValue )
    }
    
    static func imageViewWithIconName(_ iconName: String) -> UIImageView {
        return UIImageView(image: UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate))
    }
    
    static func templateImage(_ name: String) -> UIImage {
        let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
        return image!
    }
    
    static func templateImage(_ iconKey: ImageIconKeys) -> UIImage {
        return UIImageView.templateImage(iconKey.rawValue)
    }
}
