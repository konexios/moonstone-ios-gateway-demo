//
//  UIApplication+Extension.swift
//  AcnGatewayiOS
//
//  Created by Alexey Chechetkin on 01/03/2018.
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import UIKit

extension UIApplication {
    func showLocalNotification(title: String, body: String, showOnlyInBackground: Bool = true) {
        
        if showOnlyInBackground && self.applicationState == .active {
            return
        }        
        
        let notification = UILocalNotification()
        notification.alertTitle = title
        notification.alertBody = body
        
        UIApplication.shared.presentLocalNotificationNow(notification)
    }
}
