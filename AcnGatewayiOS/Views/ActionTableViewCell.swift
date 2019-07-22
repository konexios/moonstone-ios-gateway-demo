//
//  ActionTableViewCell.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 21/07/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import AcnSDK

class ActionTableViewCell: UITableViewCell {
    
    var actionModel: ActionModel?
    var deviceHid: String?
    
    @IBOutlet weak var actionTypeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var enableSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        enableSwitch.onTintColor = .mainColor
        
        backgroundColor = .gray0
        contentView.backgroundColor = .gray0
    }
    
    func setupCellWithActionModel(model: ActionModel, deviceHid: String) {
        
        self.actionModel = model
        self.deviceHid = deviceHid
        
        actionTypeLabel.text = model.actionType.nameForDisplay
        descriptionLabel.text = model.description
        
        enableSwitch.setOn(model.enabled, animated: false)
    }
    
    @IBAction func enabledStateChanged(_ sender: UISwitch) {
        if actionModel != nil {
            actionModel!.enabled = sender.isOn
            ArrowConnectIot.sharedInstance.deviceApi.updateDeviceAction(hid: deviceHid!, action: actionModel!)
        }        
    }
}
