//
//  SocialEventManager.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import Foundation

// NotificationCenter constants
extension  Notification.Name {
    
    // sended by code verification controller upon successfull verification
    static let socialEventVerificationSuccess = Notification.Name( "kSocialEventVerificationSuccess" )
    
    // sended by event registration account controller when user has entered
    // existing account credentials
    static let socialEventSignInWithExistingAccCredentials = Notification.Name( "kSocialEventSignInWithExistingInfo" )
    
    // sended by attend view controller when user says "no" to attend en event
    static let socialEventAttendDecline = Notification.Name( "kSocialEventAttendDecline" )
}

// Notification center userInfo keys
struct AccountKeys {
    static let name = "kAccNameKey"
    static let email = "kAccEmailKey"
    static let pass = "kAccPassKey"
}

// UserDefaults pending keys
struct PendingRegKeys {
    static let name                = "eventRegName"
    static let email               = "eventRegEmail"
    static let pass                = "evetnRegPass"
    static let code                = "eventRegCode"
    static let eventHid            = "eventRegHid"
    static let eventName           = "eventName"
    static let eventZoneSystemName = "eventZoneSystemName"
    static let waitForVerification = "kWaitForVerification"
}

// holds fetched social events
class SocialEventManager {
    
    static let sharedInstance = SocialEventManager()
    
    // get list of current social events
    var events: [SocialEvent] = []
    
    // get / set wait for verification flag
    var waitingForVerification: Bool {
        get {
            return UserDefaults.standard.bool(forKey: PendingRegKeys.waitForVerification)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: PendingRegKeys.waitForVerification)
            UserDefaults.standard.synchronize()
        }
    }
    
    // saves registraation values for pending state
    func saveAccountRegistrationPeindingValues(name: String, email: String, pass: String, code: String, eventHid: String, eventName: String, zoneName: String) {
        let ud = UserDefaults.standard
        
        ud.set(name, forKey: PendingRegKeys.name)
        ud.set(email, forKey: PendingRegKeys.email)
        ud.set(code, forKey: PendingRegKeys.code)
        ud.set(eventHid, forKey: PendingRegKeys.eventHid)
        ud.set(eventName, forKey: PendingRegKeys.eventName)
        ud.set(zoneName, forKey: PendingRegKeys.eventZoneSystemName)
        
        ud.synchronize()
    }
    
    // reset pending values
    func resetAccountRegistrationPendingValues() {
        let ud = UserDefaults.standard
        
        ud.removeObject(forKey: PendingRegKeys.name)
        ud.removeObject(forKey: PendingRegKeys.email)
        ud.removeObject(forKey: PendingRegKeys.pass)
        ud.removeObject(forKey: PendingRegKeys.code)
        ud.removeObject(forKey: PendingRegKeys.eventHid)
        ud.removeObject(forKey: PendingRegKeys.eventName)
        ud.removeObject(forKey: PendingRegKeys.eventZoneSystemName)
        
        ud.synchronize()
    }
}
