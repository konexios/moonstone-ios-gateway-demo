//
//  UIViewController+Extension.swift
//  AcnGatewayiOS
//
//  Created by Alexey Chechetkin on 15/01/2018.
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func setupNavBarWithArrowLogo() {
        if let nc = navigationController {
            navigationItem.titleView = UIImageView(image: UIImage(named:"Arrow_worm_white_nav"))
            nc.navigationBar.barTintColor = .black
            nc.navigationBar.isTranslucent = false       // if true, top bar looks a bit gray
            nc.navigationBar.barStyle = .black
        }
    }
    
    func alert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = .defaultTint
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true) {
            // fix: iOS9.x tint color should be reapplyed
            alert.view.tintColor = .defaultTint
        }
    }
    
    func alertFromRoot( _ title: String, message: String, completionHandler: @escaping () -> () = {} ) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = .defaultTint
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completionHandler() }))        
        
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true) {
            // fix: iOS9.x tint color should be reapplyed
            alert.view.tintColor = .defaultTint
        }
    }
    
    func markView(view: UIView, valid:Bool) {
        view.layer.borderColor = valid ? UIColor.gray1.cgColor : UIColor.red.cgColor
        view.layer.borderWidth = valid ? 1.0 : 2.0
    }
    
    func hideKeyboardOnTap() {
        let gr = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
        self.view.addGestureRecognizer(gr)
    }
    
    @objc func hideKeyboard( _ sender: AnyObject? = nil) {
        self.view.endEditing(true)
    }
}
