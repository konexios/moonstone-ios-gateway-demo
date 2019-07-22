//
//  AccountTableViewCell.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 27/10/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

class AccountTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var activeLabel: UILabel!
    
    func setupCellWithAccountModel(_ model: Account) {
        backgroundColor = .gray0
        contentView.backgroundColor = .gray0
        nameLabel.text = model.profileName
        if model.isActive {
            activeLabel.text = "Active"
        } else {
            activeLabel.text = ""
        }
    }
}
