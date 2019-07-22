//
//  Account.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 25/10/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import RealmSwift
import AcnSDK

class Account: Object {
    @objc dynamic var isActive = false
    @objc dynamic var profileName = ""
    @objc dynamic var userId = ""
    @objc dynamic var name = ""
    @objc dynamic var email = ""
    @objc dynamic var applicationHid = ""
    @objc dynamic var gatewayId = ""
    @objc dynamic var lastUsedDateString = ""
    @objc dynamic var zoneSystemName = Connection.defaultZone
    
    @objc dynamic var devicesCount: DevicesCount?
    @objc dynamic var profileSettings: ProfileSettings?
    
    // keeps the device upgrade states binded with current account
    // list of states should be "let"
    let upgradeStates = List<DeviceUpgradeState>()
    
    /// keeps the pended upgrade transactions
    /// these transactions were not confirmed as failed or succeeded
    let pendedUpgradeTransactions = List<UpgradeTransaction>()
    
    // MARK: helper methods for registration

    func updateWith(registrationResponse response: AccountRegistrationResponse) {
        userId = response.hid
        name = response.name
        email = response.email
        applicationHid = response.applicationHid
    }
    
    func updateWith(authResponse response: UserAppModel) {
        userId = response.userHid
        applicationHid = response.applicationHid
        
        if (!response.zoneSystemName.isEmpty) {
            zoneSystemName = response.zoneSystemName
        }
        
        let contact = response.contact
        var fullName = ""
        if (!contact.firstName.isEmpty) {
            fullName += contact.firstName
        }
        if (!contact.lastName.isEmpty) {
            if (!fullName.isEmpty) {
                fullName += " "
            }
            fullName += contact.lastName
        }
        if (!fullName.isEmpty) {
            name = fullName
        }
        if (!contact.email.isEmpty) {
            email = contact.email
        }
    }
}

// MARK: Database manager extension for DeviceUpgradeState support

extension DatabaseManager {
    
    /// Return upgrade state for device with given deviceHid (objectHid)
    /// - parameter deviceHid: device hid
    /// - returns: device upgrade state object or nil if not found
    func upgradeStateForDevice(_ deviceHid: String) -> DeviceUpgradeState? {
       
        guard let states = currentAccount?.upgradeStates, let state = states.first(where: { $0.deviceHid == deviceHid }) else {
            return nil
        }
        
        return state
    }

    /// Update given upgrade state or append this state to the list
    /// - parameter state: upgrade state to update or append
    /// - returns: true if state was updated or false if state was added
    @discardableResult
    func updateUpgradeState(_ state: DeviceUpgradeState) -> Bool {
        
        if let states = currentAccount?.upgradeStates {
            for (idx, obj) in states.enumerated() {
                if obj.deviceHid == state.deviceHid {
                    // update
                    try! realm.write {
                        currentAccount?.upgradeStates[idx] = state
                    }
                    return true
                }
            }
            
            // state not found we should add it
            try! realm.write {
                currentAccount?.upgradeStates.append(state)
            }
        }
        
        return false
    }
    
    /// Delete state for device with given device hid
    /// - parameter deviceHid: device hid to find and delete upgrade state
    /// - returns: true is state is found and deleted otherwise false
    @discardableResult
    func deleteUpgradeStateForDevice(_ deviceHid: String) -> Bool {
        
        guard let states = currentAccount?.upgradeStates else {
            return false
        }

        for (idx, state) in states.enumerated() {
            if state.deviceHid == deviceHid {
                try! realm.write {
                    currentAccount?.upgradeStates.remove(at: idx)
                }
                return true
            }
        }
        
        return false
    }    
}

// MARK: DatabaseManager extension for upgrade pended transactions
extension DatabaseManager {
    
    /// adds pended transaction to the current accoount
    /// if there is no transaction with the same id
    func addUpgradePendedTransaction(_ transactionHid: String, type: UpgradeTransaction.TransactionType, message: String = "") {
        guard let trans = DatabaseManager.sharedInstance.currentAccount?.pendedUpgradeTransactions else {
            print("[DatabaseManager] - addUpgradePendedTransaction(), transaction list is nil")
            return
        }

        guard trans.first(where: { $0.transactionHid == transactionHid }) == nil else {
            print("[DatabaseManager] - addUpgradePendedTransaction(), transaction \(transactionHid) is already in the list")
            return
        }
        
        try! realm.write {
            let pendedTransation = UpgradeTransaction()
            pendedTransation.transactionHid = transactionHid
            pendedTransation.type = type
            pendedTransation.message = message
            
            currentAccount?.pendedUpgradeTransactions.append(pendedTransation)
        }
    }
    
    /// removes upgrade pended transaction with given id
    func removeUpgradePendedTransaction(_ transactionHid: String) {
        guard let trans = DatabaseManager.sharedInstance.currentAccount?.pendedUpgradeTransactions else {
            print("[DatabaseManager] - removeUpgradePendedTransaction(), transaction list is nil")
            return
        }
        
        for (idx, transaction) in trans.enumerated() {
            if transaction.transactionHid == transactionHid {
                try! realm.write {
                    currentAccount?.pendedUpgradeTransactions.remove(at: idx)
                }
                return
            }
        }
        
        print("[DatabaseManager] - removeUpgradePendedTransaction(), transaction \(transactionHid) not found in the list")
    }
    
    /// clear all pended upgrade transactions
    func clearAllUpgradePendedTransactions() {
        guard let trans = DatabaseManager.sharedInstance.currentAccount?.pendedUpgradeTransactions, trans.count > 0 else {
            print("[DatabaseManager] - clearAllUpgradePendedTransactions(), transaction list is nil")
            return
        }
        
        print("[DatabaseManager] - clearAllUpgradePendedTransactions(), cleared \(trans.count) pended transaction")
        try! realm.write {
            currentAccount?.pendedUpgradeTransactions.removeAll()
        }
    }
}


