//
//  DeviceSettingsViewControllerProtocol.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 15/06/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

protocol DeviceSettingsViewControllerProtocol {
    var device: Device? { get set }
    func reloadSettings()
}
