//
//  Settings.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 26/10/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import RealmSwift

class Settings: Object {
    @objc dynamic var locationServices = true
    @objc dynamic var heartbeatInterval = 60.0
    @objc dynamic var devicePollingInterval = 1000.0
    @objc dynamic var keepConnectionWhenDeviceIsDisabled = false
}
