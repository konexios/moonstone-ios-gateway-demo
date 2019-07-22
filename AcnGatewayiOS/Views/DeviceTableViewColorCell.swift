//
//  DeviceTableViewColorCell.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 28/03/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit

class DeviceTableViewColorCell: UITableViewCell {

    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var deviceCategoryIcon: UIImageView!
    @IBOutlet weak var deviceIcon: UIImageView!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var onlineLabel: UILabel!
    
    var online: Bool? {
        didSet {
            if online! {
                onlineLabel.text = "ONLINE"
            } else {
                onlineLabel.text = ""
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        deviceName.textColor = UIColor.white
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupCellWithMenuItem(_ item: HomeMenuItem) {
        colorView.backgroundColor = item.color
        deviceCategoryIcon.image = item.categoryIconImage
        deviceIcon.image = item.iconImage
        deviceName.text = item.title.uppercased()
    }

}
