//
//  AppDelegate.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 9/29/15.
//  Copyright © 2015 Arrow Electronics. All rights reserved.
//

import UIKit
import Firebase
import AcnSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {    

    var window: UIWindow?
    
    var events: [SocialEvent]?
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window?.tintColor = UIColor.white
        
        FirebaseApp.configure()
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound], categories: nil))
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
        DatabaseManager.sharedInstance.updateLastUsedDate()
        
        backgroundTaskIdentifier =
        UIApplication.shared.beginBackgroundTask { [unowned self] in
            self.endBackgroundTask()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        self.endBackgroundTask()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }    
    
    private func endBackgroundTask() {
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }
}

