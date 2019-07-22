//
//  AboutViewController.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 9/29/15.
//  Copyright © 2015 Arrow Electronics. All rights reserved.
//

import UIKit
import AcnSDK

class AboutViewController: BaseViewController {
    
    @IBOutlet weak var labelVersion: UILabel!
    @IBOutlet weak var labelSDKVersion: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .gray0
        
        labelVersion.text = "Arrow Connect Gateway Version \(SoftwareVersion.Version).\(SoftwareVersion.BuildNumber)"
        labelSDKVersion.text = "SDK Version \(AcnSDK.AcnSDKVersionNumber)"
    }
    

    @IBAction func dismiss(_ sender: AnyObject) {
        let _ = navigationController?.popViewController(animated: true)
    }
}
