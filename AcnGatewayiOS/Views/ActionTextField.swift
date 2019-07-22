//
//  ActionTextField.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 05/06/2017.
//  Copyright © 2017 Arrow Electronics, Inc. All rights reserved.
//

import UIKit

class ActionTextField: UITextField {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        borderStyle = .none
        backgroundColor = .gray1
        textColor = .white
        font = UIFont.systemFont(ofSize: 17.0)
        
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        leftView = paddingView;
        leftViewMode = .always
        
        if placeholder != nil {
            attributedPlaceholder = NSAttributedString(string: placeholder!,
                                                       attributes: [NSAttributedStringKey.foregroundColor: UIColor.white,
                                                                    NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17.0)])
        }
        
        layer.borderColor = UIColor.gray2.cgColor
        layer.borderWidth = 1.0
    }

}
