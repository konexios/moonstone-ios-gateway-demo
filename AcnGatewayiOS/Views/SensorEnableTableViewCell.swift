//
//  SensorEnableTableViewCell.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 03/06/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit

class SensorEnableTableViewCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var stateSwitch: UISwitch!

    var property: DeviceProperty?
    var device: Device?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        stateSwitch.onTintColor = .mainColor
        backgroundColor = .gray1
        contentView.backgroundColor = .gray1
    }
    
    func setupCellWithProperty(property: DeviceProperty) {
        self.property = property
        title.text = property.nameForDisplay
        if let properties = device?.deviceProperties {
            stateSwitch.setOn(properties.isSensorEnabled(key: property), animated: true)
        }        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func stateChanged(_ sender: UISwitch) {
        device?.deviceProperties?.saveProperty(property: sender.isOn as AnyObject, forKey: property!.value)
        device?.updateProperty(property: property!)
    }
}
