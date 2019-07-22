//
//  Location.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 9/30/15.
//  Copyright © 2015 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreLocation
import AcnSDK

class Location : NSObject, CLLocationManagerDelegate {
    static let sharedInstance = Location()
    
    var locationManager: CLLocationManager!
    var lastKnownLocation: CLLocation?
    let lock = NSLock()
    
    override fileprivate init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100
    }
    
    func start() {
        if locationManager != nil && DatabaseManager.sharedInstance.settings.locationServices {
            print("[LocationManager] start ...")
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    func stop() {
        if locationManager != nil {
            print("[LocationManager] stop...")
            locationManager.stopUpdatingLocation()
        }
    }
    
    func currentLocation() -> CLLocation? {
        var result: CLLocation?
        synchronized(lock) {
            result = self.lastKnownLocation
        }
        return result
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("[LocationManager] didUpdateLocations() - \(String(describing: lastKnownLocation))")
        synchronized(lock) {
            self.lastKnownLocation = locations.last
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] didFailWithError() - \(error)")
    }
}
