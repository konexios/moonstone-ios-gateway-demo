//
//  ActionEditTableViewCell.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 21/07/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import AcnSDK

class ActionEditTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: ActionTextField!
    
    var actionModel: ActionModel?
    var field: ActionEditField?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupToolbar()

        backgroundColor = .gray0
        contentView.backgroundColor = .gray0
    }
    
    func setupToolbar() {
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        toolbar.items = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction))]
        toolbar.sizeToFit()
        
        textField.inputAccessoryView = toolbar
    }
    
    @objc func doneAction() {
        textField.resignFirstResponder()
    }
    
    func setupCellWithActionEditField(actionEditField: ActionEditField, model: ActionModel) {
        
        field = actionEditField
        actionModel = model
        
        titleLabel.text = actionEditField.rawValue
        textField.text = model.textForField(field: actionEditField)
    }
    
    @IBAction func desciptionChanged(_ sender: UITextField) {
        actionModel?.setDataForField(data: sender.text!, field: field!)        
    }

}


