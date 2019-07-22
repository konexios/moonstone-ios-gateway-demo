//
//  DeviceUpgradeState.swift
//  AcnGatewayiOS
//
//  Created by Alexey Chechetkin on 02/04/2018.
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import Foundation
import RealmSwift

/// this class keeps the upgrade state and all related data with diffrent states
/// this class is used as persistent data storage for FOTA management process
class DeviceUpgradeState: Object {
    
    /// persistent upgrade states
    /// each of this state is persistent for given device
    /// see: https://arrows3.atlassian.net/wiki/spaces/KR/pages/71699110/Device+Firmware+Management
    @objc enum State: Int {
        case idle                       // idle state - the app is ready to upgrade device
        case scheduled                  // upgrade was sheduled ok - waiting mqtt command to start file downloading
        case downloading                // mqtt command is received - downloading firmware file
        case preparing                  // file has been downloaded ok - prepearing to upgrade
        case upgrading                  // upgrading is in progress
        case success                    // upgrade was ok
        case error                      // error is occured
    }

    @objc dynamic var state: State = .idle                  // main upgrade state

    @objc dynamic var userHid = ""                          // current user id
    
    @objc dynamic var deviceHid = ""                        // upgraded device id
    
    @objc dynamic var deviceName = ""                       // used when erorrs or success occured
    
    @objc dynamic var transactionHid = ""                   // used with various states
    
    @objc dynamic var errorMessage = ""                     // used with error state
    
    @objc dynamic var firmwareFileUrl = ""                  // used with downloading state
    
    @objc dynamic var firmwareFileSize = ""                 // used with downloading state
    
    @objc dynamic var confirmAsFailedTransaction = false    // used with sendingConfirmation state
    
    @objc dynamic var md5checksum = ""                      // used with downloading state
    
    @objc dynamic var releaseHid = ""                       // used with scheduled state
    
    @objc dynamic var fileToken = ""                        // used with downloading state
    
    @objc dynamic var startUpgradeTime: Double = 0          // used as start time of upgrading
    
    @objc dynamic var canceled = false                      // this flag is used when we need to cancel upgrade
}
