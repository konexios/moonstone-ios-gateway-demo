//
//  BaseViewController.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 10/6/15.
//  Copyright © 2015 Arrow Electronics. All rights reserved.
//

import Foundation
import AcnSDK

class BaseViewController: UIViewController {
    
    var contentActivityView: UIView?
    
    func popAndPushWithToolbar(controller: UIViewController) {
        controller.toolbarItems = toolbarItems
        
        navigationController?.popToViewController(self, animated: false)
        navigationController?.pushViewController(controller, animated: false)
    }
    
    func pushWithToolbar(controller: UIViewController) {
        controller.toolbarItems = toolbarItems
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func showAlert(_ title: String, message: String, handler:(() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = .defaultTint
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { alertAction in
            handler?()
        })
            
        self.present(alert, animated: true) {
            // fix: iOS 9.x - reapply tint color after presenting
            alert.view.tintColor = .defaultTint
        }
    }
    
    func showActivityIndicator(forView view: UIView) {
        contentActivityView = UIView(frame: view.bounds)
        contentActivityView!.backgroundColor = UIColor.white
        
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityView.color = UIColor.gray0
        activityView.center = CGPoint(x: contentActivityView!.frame.size.width / 2.0, y: contentActivityView!.frame.size.height / 3.0)
        activityView.startAnimating()
        
        contentActivityView!.addSubview(activityView)
        view.addSubview(contentActivityView!)
    }
    
    func showActivityIndicator() {
        contentActivityView = UIView(frame: view.frame)
        contentActivityView!.backgroundColor = UIColor.white
        
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityView.color = UIColor.gray0
        activityView.center = CGPoint(x: view.frame.size.width / 2.0, y: view.frame.size.height / 3.0)
        activityView.startAnimating()
        
        contentActivityView!.addSubview(activityView)
        view.addSubview(contentActivityView!)
    }
    
    func hideActivityIndicator() {
        if contentActivityView != nil {
            contentActivityView!.removeFromSuperview()
            contentActivityView = nil
        }
    }
    
    func gatewayConfig(hid: String) {
        ArrowConnectIot.sharedInstance.gatewayApi.gatewayConfig(hid: hid) { success in
            if success {
                DispatchQueue.global().async {
                    ArrowConnectIot.sharedInstance.connectMQTT(gatewayId: hid)
                }
                ArrowConnectIot.sharedInstance.startHeartbeat(interval: DatabaseManager.sharedInstance.settings.heartbeatInterval, gatewayId: hid)
            } else {
                FIRCrashPrintMessage("Gateway Config Error")
            }
        }
    }
}
