//
//  IoTService+SocialEvent.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import AcnSDK
import Foundation

// consts
struct SocialEventDefs {
    // pegasus methods
    static let getEventListPath = "/api/v1/pegasus/social-events" // GET
    
    // kronos methods
    static let resendEmailPath = "/api/v1/kronos/socialevent/registrations/resend"              // POST
    static let verifyEventCodePath = "/api/v1/kronos/socialevent/registrations/verify"          // POST
    static let registerUserPath = "/api/v1/kronos/socialevent/registrations/register"           // POST
    static let getDeviceListPath = "/api/v1/kronos/social/event/devices/device/type/"           // GET
}

/// error messages map
struct ErrorMessagesMap {
    static let map = [ "account is not in pending status" : "Account has already been registered" ]
}

// extension used to get the access to the SocialEvent API
// the SocialEvents API is devided on two parts the first part is on the pegasus sid,
// the second part is on the kronos side

extension ArrowConnectIot {
    //
    // return current active social event list or nil if not available
    //
    func socialEvents(_ completionHandler: @escaping (_ events: [SocialEvent]?) -> Void) {

        let curDate = Date().dateWithoutTime.iso8601
        
        // url params
        let parameters: Parameters = [
            "startDateTo": curDate,
            "endDateFrom": curDate,
            "sortField": "name",
            "sortDirection": "ASC"
        ]
        
        guard let requestUrl = queryString(urlString: SocialEventDefs.getEventListPath, parameters: parameters) else {
            print("[ArrowConnectIotExtension: socialEvents() - Can't get request URL")
            completionHandler(nil)
            return
        }
        
        print("requestUrl: \(requestUrl)")
        
        // send request using existing apiKey
        sendPlatformCommonRequest(urlString: requestUrl,
                                  method: .GET, model: nil, info: "Get social event list") {
            json, success in
            
            if success,
                let json = json as? [String: AnyObject],
                let arr = json["data"] as? [[String: AnyObject]] {
                var res: [SocialEvent] = []
                
                for dict in arr {
                    if let socialEvent = SocialEvent(json: dict) {
                        res.append(socialEvent)
                    }
                }
                
                completionHandler(res)
            }
            else { completionHandler(nil) }
        }
    }
    
    //
    // resend code
    //
    func resendEventVerificationCode(email: String, completionHandler: @escaping (_ success: Bool, _ errMsg: String?) -> Void) {
        
        // url params
        let parameters: Parameters = ["email": email]
        
        guard let requestUrl = queryString(urlString: SocialEventDefs.resendEmailPath, parameters: parameters) else {
            print("[ArrowConnectIotExtension: resendVerificationCode() - Can't get request URL")
            completionHandler(false, nil)
            return
        }
        
        // send request using existing apiKey
        sendIotCommonRequest(urlString: requestUrl,
                             method: .POST, model: nil, info: "resend verification code") {
            json, success in
            
            if success {
                completionHandler(true, nil)
            }
            else if let json = json as? [String: AnyObject], let errMsg = json["message"] as? String {
                completionHandler(false, errMsg)
            }
            else {
                completionHandler(false, "Can not resend verification code")
            }
        }
    }
    
    //
    // verify verificationCode
    //
    func verifyVerificationCode(code: String, completionHandler: @escaping (_ response: VerifyCodeResponse?, _ errMsg: String?) -> Void) {
        
        // url params
        let parameters: Parameters = ["verificationCode": code]
        
        guard let requestUrl = queryString(urlString: SocialEventDefs.verifyEventCodePath, parameters: parameters) else {
            print("[ArrowConnectIotExtension: verifyVerificationCode() - Can't get request URL")
            completionHandler(nil, nil)
            return
        }
        
        // send request using existing apiKey
        sendIotCommonRequest(urlString: requestUrl,
                             method: .POST, model: nil, info: "verify verification code") {
            json, success in
            
            if success, let json = json as? [String: AnyObject] {
                completionHandler(VerifyCodeResponse(json: json), nil)
            }
            else if let json = json as? [String: AnyObject], let errMsg = json["message"] as? String {
                completionHandler(nil, errMsg)
            }
            else {
                completionHandler(nil, "Can not verify your code")
            }
        }
    }
    
    //
    // registration
    //
    func eventRegisterAccount(accModel: EventRegisterAccModel, completionHandler: @escaping (_ hid: String?, _ errMsg: String?) -> Void) {
        
        // send request using temporary apiKey
        sendIotCommonRequest(urlString: SocialEventDefs.registerUserPath,
                             method: .POST, model: accModel, info: "event register account")
        {
            json, success in
            
            if success, let json = json as? [String: AnyObject], let hid = json["hid"] as? String {
                completionHandler(hid, nil)
            }
            else if let json = json as? [String: AnyObject], let errMsg = json["message"] as? String {
                completionHandler(nil, ErrorMessagesMap.map[errMsg.trimmedLowercased, default: errMsg] )
            }
            else {
                completionHandler(nil, "Can not register account")
            }
        }
    }
    
    //
    // get device map ( macaddress -> pin )
    //
    func fetchDevicesMap(type: String, completionHandler: @escaping (([SocialEventDevice]?) -> Void)) {
        
        sendIotCommonRequest(urlString: "\(SocialEventDefs.getDeviceListPath)\(type)",
                             method: .GET, model: nil, info: "Fetch device list pin-map")
        {
            json, success in
            
            if  success,
                let arr = json as? [ [String: Any] ]
            {
                var res = [SocialEventDevice]()
                
                arr.forEach {
                    if let eventDevice = SocialEventDevice(json: $0) {
                        res.append(eventDevice)
                    }
                }
                
                completionHandler(res)
            }
            else {
                completionHandler(nil)
            }
        }
    }
}
