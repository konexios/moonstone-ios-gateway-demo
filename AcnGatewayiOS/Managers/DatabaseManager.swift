//
//  DatabaseManager.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 25/10/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import RealmSwift

fileprivate let SCHEMA_VERSION: UInt64 = 14

class DatabaseManager {

    static let sharedInstance = DatabaseManager()
    
    var realm: Realm
    var currentAccount: Account?
    var settings: Settings!
    
    private init() {
        // set migration config
        var config = Realm.Configuration()
        config.schemaVersion = SCHEMA_VERSION
        config.migrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < SCHEMA_VERSION {
                print("Realm() -> migration, oldSchema: \(oldSchemaVersion) <-> \(config.schemaVersion)")
            }
        }
        
        Realm.Configuration.defaultConfiguration = config
        
        realm = try! Realm()
        currentAccount = getCurrentAccount()
        settings = getSettings()
    }
    
    // MARK: Accounts
    
    func addAccount(_ account: Account) {
        account.isActive = true
        account.devicesCount = DevicesCount()
        account.profileSettings = ProfileSettings()
        account.lastUsedDateString = Date().stringForLastUsedDate
        
        try! realm.write {
            currentAccount?.isActive = false
            realm.add(account)
        }
        currentAccount = account
    }
    
    func deleteAccount(_ account: Account) {
        if !account.isActive {
            try! realm.write {
                realm.delete(account)
            }
        }
    }
    
    func accounts() -> [Account] {
        return Array(realm.objects(Account.self))
    }
    
    func switchAccount(_ account: Account) {
        try! realm.write {
            currentAccount?.lastUsedDateString = Date().stringForLastUsedDate
            currentAccount?.isActive = false
            account.isActive = true
        }
        currentAccount = account
    }
    
    var lastUsedDateString: String {
        if let lastUsed = currentAccount?.lastUsedDateString {
            return lastUsed
        } else {
            return Date().stringForLastUsedDate
        }
    }
    
    func updateLastUsedDate() {
        try! realm.write {
            currentAccount?.lastUsedDateString = Date().stringForLastUsedDate
        }
    }
    
    // MARK: Gateway
    
    var gatewayId: String? {
        if let id = currentAccount?.gatewayId, id.count > 0 {
                return id
        }
        return nil
    }
    
    func saveGatewayId(_ gatewayId: String) {
        try! realm.write {
            currentAccount?.gatewayId = gatewayId
        }
    }
    
    // MARK: Settings
    
    func saveLocationServicesStatus(status: Bool) {
        try! realm.write {
            settings.locationServices = status
        }
    }
    
    func saveDevicePollingInterval(interval: Double) {
        try! realm.write {
            settings.devicePollingInterval = interval
        }
    }
    
    func saveHeartbeatInterval(interval: Double) {
        try! realm.write {
            settings.heartbeatInterval = interval
        }
    }
    
    // MARK: Profile settings
    
    var demoConfiguration: Bool {
        if let status = currentAccount?.profileSettings?.demoConfiguration {
            return status
        } else {
            return true
        }
    }
    
    func saveDemoConfigurationStatus(status: Bool) {
        try! realm.write {
            currentAccount?.profileSettings?.demoConfiguration = status
        }
    }
    
    func saveDemoConfigurationStatus(account: Account, status: Bool) {
        try! realm.write {
            account.profileSettings?.demoConfiguration = status
        }
    }
    
    // MARK: Devices
    
    func deviceCount(type: DeviceType) -> Int {
        if let devicesCount = currentAccount?.devicesCount {
            return devicesCount.deviceCount(device: type)
        } else {
            return 0
        }        
    }
    
    func increaseDeviceCount(device: DeviceType) {
        switch device {
        case .SiLabsSensorPuck:
            try! realm.write {
                currentAccount?.devicesCount?.siLabsSensorPuckCount += 1
            }
        case .IPhoneDevice:
            try! realm.write {
                currentAccount?.devicesCount?.iPhoneDeviceCount += 1
            }
        case .ThunderboardReact:
            try! realm.write {
                currentAccount?.devicesCount?.thunderboardCount += 1
            }
        case .SensorTile:
            try! realm.write {
                currentAccount?.devicesCount?.sensorTileCount += 1
            }
        case .SimbaPro:
            try! realm.write {
                currentAccount?.devicesCount?.simbaProCount += 1
            }
        case .OnSemiRSL10:
            try! realm.write {
                currentAccount?.devicesCount?.onSemiBleCount += 1
            }
        }
    }
    
    func decreaseDeviceCount(device: DeviceType) {
        switch device {
        case .SiLabsSensorPuck:
            try! realm.write {
                currentAccount?.devicesCount?.siLabsSensorPuckCount -= 1
            }
        case .IPhoneDevice:
            try! realm.write {
                currentAccount?.devicesCount?.iPhoneDeviceCount -= 1
            }
        case .ThunderboardReact:
            try! realm.write {
                currentAccount?.devicesCount?.thunderboardCount -= 1
            }
        case .SensorTile:
            try! realm.write {
                currentAccount?.devicesCount?.sensorTileCount -= 1
            }
        case .SimbaPro:
            try! realm.write {
                currentAccount?.devicesCount?.simbaProCount -= 1
            }
        case .OnSemiRSL10:
            try! realm.write {
                currentAccount?.devicesCount?.onSemiBleCount -= 1
            }
        }
    }
    
    func updateDeviceUUID(deviceType: DeviceType, uuid: UUID) {
        switch deviceType {
        case .SimbaPro:
            updateSimbaProDeviceUUID(uuid)
            
        case .OnSemiRSL10:
            updateOnSemiRSL10DeviceUUID(uuid)
            
        case .SensorTile:
            updateSensorTileDeviceUUID(uuid)
            
        default:
            break
        }
    }
    
    private func updateOnSemiRSL10DeviceUUID(_ uuid: UUID) {
        try! realm.write {
            currentAccount?.devicesCount?.onSemiRSL10DeviceUUID = uuid.uuidString
        }
    }
    
    private func updateSimbaProDeviceUUID(_ uuid: UUID) {
        try! realm.write {
            currentAccount?.devicesCount?.simbaProDeviceUUID = uuid.uuidString
        }
    }
    
    private func updateSensorTileDeviceUUID(_ uuid: UUID) {
        try! realm.write {
            currentAccount?.devicesCount?.sensorTileDeviceUUID = uuid.uuidString
        }
    }
    
    var simbaProDeviceUUID : String? {
        return currentAccount?.devicesCount?.simbaProDeviceUUID
    }
    
    var onSemiRSL10DeviceUUID: String? {
        return currentAccount?.devicesCount?.onSemiRSL10DeviceUUID
    }
    
    var sensorTileDeviceUUID: String? {
        return currentAccount?.devicesCount?.sensorTileDeviceUUID
    }
    
    /// devices that have been added via discovery screen
    /// keeps its UUID in database, for these devices we return
    /// its UUID or nil otherwise
    static func deviceUUIDfor(lookupName: String) -> String? {
        switch lookupName {
        case SimbaPro.AdvertisementName:
            return DatabaseManager.sharedInstance.simbaProDeviceUUID ?? ""
            
        case OnSemiRSL10.AdvertisementName:
            return DatabaseManager.sharedInstance.onSemiRSL10DeviceUUID ?? ""
            
//        case SensorTile.AdvertisementName:
//            return DatabaseManager.sharedInstance.sensorTileDeviceUUID ?? ""
            
        default:
            return nil
        }
    }
    
    // MARK: helper method
    
    func with(_ block: () -> Void) {
        try! realm.write {
            block()
        }
    }    
    
    // MARK: Private
    
    private func getSettings() -> Settings {
        if let settings = realm.objects(Settings.self).first {
            return settings
        } else {
            let settings = Settings()
            try! realm.write {
                realm.add(settings)
            }
            return settings
        }
    }
    
    private func getCurrentAccount() -> Account? {
        let accounts = realm.objects(Account.self).filter("isActive == true").first
        return accounts
    }
}
