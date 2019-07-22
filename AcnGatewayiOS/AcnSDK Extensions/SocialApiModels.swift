//
//  SocialEvent.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import Foundation
import AcnSDK

class SocialEventDevice
{
    var pinCode: String
    var macAddress: String
    
    init?( json: [String: Any] ) {
        
        if  let pinCode = json["pinCode"] as? String,
            let mac = json["macAddress"] as? String
        {
            self.pinCode = pinCode
            self.macAddress = mac.lowercased()
        }
        else {
            return nil
        }
    }
}


class SocialEvent
{
    var hid: String
    var name: String
    var startDate: String
    var endDate: String
    var zoneHid: String
    var zoneSystemName: String
    
    init?( json: [String:AnyObject] )  {
        
        if let hid = json["hid"] as? String,
           let name = json["name"] as? String,
           let startDate = json["startDate"] as? String,
           let endDate = json["endDate"] as? String,
           let zoneHid = json["zoneHid"] as? String,
           let zoneSystemName = json["zoneSystemName"] as? String
        {
            self.hid = hid
            self.name = name
            self.startDate = startDate
            self.endDate = endDate
            self.zoneHid = zoneHid
            self.zoneSystemName = zoneSystemName
        }
        else {
            return nil
        }
    }
}


class VerifyCodeResponse
{
    var appHid : String
    var userHid: String
    var companyHid: String
    var zoneSystemName: String?     
    
    init?( json: [String:AnyObject] ) {
        
        if let appHid = json["applicationHid"] as? String,
           let userHid = json["userHid"] as? String,
           let companyHid = json["companyHid"] as? String
        {
            self.appHid = appHid
            self.userHid = userHid
            self.companyHid = companyHid
        }
        else {
            return nil
        }
    }
}

class EventRegisterAccModel: RequestModel
{
    var email: String
    var eventCode: String
    var name: String
    var password: String
    var eventHid: String
    var eventZoneSystemName: String
    
    override var params: [String: AnyObject]  {
        return [ "email"            : email as AnyObject,
                 "eventCode"        : eventCode as AnyObject,
                 "name"             : name as AnyObject,
                 "password"         : password as AnyObject,
                 "socialEventHid"   : eventHid as AnyObject,
                 "zoneSystemName"   : eventZoneSystemName as AnyObject]
    }
    
    init( email: String, eventCode: String, name: String, password: String, eventHid: String, eventZoneSystemName: String ) {
        
        self.email = email
        self.eventCode = eventCode
        self.name = name
        self.password = password
        self.eventHid = eventHid
        self.eventZoneSystemName = eventZoneSystemName
        
        super.init()
    }
}
