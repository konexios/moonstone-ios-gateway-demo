//
//  Definition.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 9/30/15.
//  Copyright © 2015 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreLocation
import AcnSDK

enum DeviceType : String {
    case SiLabsSensorPuck
    case IPhoneDevice
    case ThunderboardReact
    case SensorTile
    case SimbaPro = "SIMBA-PRO"
    case OnSemiRSL10 = "OnSemi-BLE"
}

enum DeviceState : String {
    case Disconnected = "Disconnected"
    case Connecting = "Connecting..."
    case Connected = "Connected"
    case Detecting = "Discovering..."
    case Monitoring
    case Stopped
    case Error = "Can not pair with device"
    case NotFound = "Device is not found"
}

enum SensorType : String {
    case heartRate
    case temperature
    case skinTemperature
    case ambientTemperature
    case surfaceTemperature
    case irTemperature
    case pedometer
    case distance
    case uv
    case barometer
    case humidity
    case light
    case accelerometerX
    case accelerometerY
    case accelerometerZ
    case gyroscopeX
    case gyroscopeY
    case gyroscopeZ
    case magnetometerX
    case magnetometerY
    case magnetometerZ
    case magnet
    case pressure
    case airflow
    case orientationAlpha
    case orientationBeta
    case orientationGamma
    case led1Status
    case led2Status
    case micLevel
    case switchStatus
    case pir                // Passive InfraRed detector
    
    var telemetryName: String {
        switch self {
            case .gyroscopeX: return "gyrometerX"
            case .gyroscopeY: return "gyrometerY"
            case .gyroscopeZ: return "gyrometerZ"
            default:          return self.rawValue
        }
    }
}

class Telemetry {
    static let NoValue = "___"
    
    var type: SensorType
    var label: String
    var labelColor: UIColor
    var value: String
    var valueColor: UIColor
    
    init(type: SensorType, label: String) {
        self.type = type
        self.label = label
        self.value = Telemetry.NoValue
        labelColor = UIColor.lightGray
        valueColor = UIColor.lightGray
    }
    
    func reset() {
        disable()
        value = Telemetry.NoValue
    }
    
    func enable() {
        labelColor = UIColor.white
        valueColor = UIColor.yellow
    }
    
    func disable() {
        labelColor = UIColor.lightGray
        valueColor = UIColor.lightGray
    }
    
    func setValue(newValue: String) {
        if !newValue.isEmpty {
            value = newValue
        } else {
            value = Telemetry.NoValue
        }
    }
}

class TelemetryDisplay {
    var label: String = ""
    var value: String = ""
}

struct SoftwareVersion {
    static let GatewayType = 200 // mobile gateway
    static let Name = "AcnGatewayiOS"
    
    static var Version: String {
        get {
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                return version
            } else {
                return "1.0"
            }
        }
    }

    static var BuildNumber: String {
        get {
            if let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String {
                return build
            } else {
                return "0"
            }
        }
    }
}

struct Connection {
    
    // set to true to set connection config to RELEASE / DEMO mode
    static let RELEASE = false
    
    static let ArrowConnectUrlDEV       = "http://pgsdev01.arrowconnect.io:11003"
    static let IoTConnectUrlDEV         = "http://pgsdev01-%@.arrowconnect.io:12001"
    static let MQTTServerHostDEV        = "pgsdev01-%@.arrowconnect.io"
    static let MQTTServerPortDEV:UInt16 = 1883
    static let MQTTVHostDEV             = "/themis.dev"

    static let ArrowConnectUrlQA        = "http://pgsqa01.arrowconnect.io:11003"
    static let IoTConnectUrlQA          = "http://pgsqa01-%@.arrowconnect.io:12001"
    static let MQTTServerHostQA         = "pgsqa01-%@.arrowconnect.io"
    static let MQTTServerPortQA:UInt16  = 1883
    static let MQTTVHostQA              = "/pegasus"

    static let ArrowConnectUrlDEMO       = "https://acs-api.arrowconnect.io"
    static let IoTConnectUrlDEMO         = "https://api-%@.arrowconnect.io"
    static let MQTTServerHostDEMO        = "mqtt-%@.arrowconnect.io"
    static let MQTTServerPortDEMO:UInt16 = 8883
    static let MQTTVHostDEMO             = "/pegasus"
    
    static let defaultZone               = "a01"
    
    // reconfigurate connection urls with provided zone
    static func reconfigConnectionWithZoneName(_ zoneName: String) {
        Connection.reconfigConnection(demo: Connection.RELEASE, zoneName: zoneName)
    }
    
    // reconfig connection urls with default config
    static func reconfigConnection() {
        Connection.reconfigConnection(demo: Connection.RELEASE, zoneName: nil)
    }
    
    static func reconfigConnection(demo: Bool, zoneName: String? = nil) {
        
        var zone: String
        
        if let zoneName = zoneName {
            zone = zoneName
        }
        else {
            zone = DatabaseManager.sharedInstance.currentAccount?.zoneSystemName ?? Connection.defaultZone
        }
        
        // don't allow zone to be empty string
        if zone.isEmpty {
            print("==> Warning: The zone is empty using default zone: \(Connection.defaultZone)")
            zone = Connection.defaultZone
        }
        
        print("==> setupConnection() with zone: \(zone), demoMode: \(demo)")
        
        if demo {
            ArrowConnectIot.sharedInstance.setupConnection(arrowConnectUrl: Connection.ArrowConnectUrlDEMO,
                                                           iotUrl: String(format: Connection.IoTConnectUrlDEMO, zone),
                                                           mqtt: String(format: Connection.MQTTServerHostDEMO, zone),
                                                           mqttPort: Connection.MQTTServerPortDEMO,
                                                           mqttVHost: Connection.MQTTVHostDEMO)
        }
        else {
            ArrowConnectIot.sharedInstance.setupConnection(arrowConnectUrl: Connection.ArrowConnectUrlDEV,
                                                           iotUrl: String(format: Connection.IoTConnectUrlDEV, zone),
                                                           mqtt: String(format: Connection.MQTTServerHostDEV, zone),
                                                           mqttPort: Connection.MQTTServerPortDEV,
                                                           mqttVHost: Connection.MQTTVHostDEV)
        }
    }
    
    // return current arrow connection host string
    static var iotHost: String {
        let zone = DatabaseManager.sharedInstance.currentAccount?.zoneSystemName ?? Connection.defaultZone
        let demo = DatabaseManager.sharedInstance.currentAccount?.profileSettings?.demoConfiguration ?? false
        let urlString =  String(format: demo ? Connection.IoTConnectUrlDEMO : Connection.IoTConnectUrlDEV, zone)
        let url = URL(string: urlString)!
        
        return url.host!
    }
}

struct Constants {
    
    struct Keys {
        static let DefaultApiKey = "PUT-YOUR-API-KEY-HERE"
        static let DefaultSecretKey = "PUT-YOUR-SECRET-KEY-HERE"
    }
}
