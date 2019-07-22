//
//  EventTableViewCell.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 02/08/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import AcnSDK

class EventTableViewCell: UITableViewCell {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var criteriaLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    func setupCellWithEventModel(_ model: DeviceEvent) {
        
        statusLabel.text = model.status
        if let typeString = model.deviceActionTypeName {
            typeLabel.text = typeString
        } else {
            typeLabel.text = "No type"
        }
        
        criteriaLabel.text = model.criteria
        dateLabel.text = model.dateString
        timeLabel.text = model.timeString
    }
    
}
