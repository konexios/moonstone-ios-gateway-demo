//
//  GradientView.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 18/04/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit

class GradientView: UIView {

    override class var layerClass : AnyClass {
        return CAGradientLayer.self
    }

}
