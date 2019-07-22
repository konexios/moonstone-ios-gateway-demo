//
//  DeviceDetailsCommonViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 19/04/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit

class DeviceDetailsCommonViewController: BaseViewController, DeviceDelegate {
    
    var device: Device?
    
    // MARK: DeviceDelegate
    
    func stateUpdated(sender: Device, newState: DeviceState) {
        
    }
    
    func telemetryUpdated(sender: Device, values: [SensorType: String]) {

    }
    
    func statesUpdated(sender: Device, states: [String : Any]) {
        
    }
    
    func nameUpdated(sender: Device, name: String) {
        
    }
}
