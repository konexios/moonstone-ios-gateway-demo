//
//  String+Extension.swift
//  AcnGatewayiOS
//
//  Created by Alexey Chechetkin on 06.02.2018.
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import Foundation

extension String {
    
    var trimmed: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    var trimmedLowercased: String {
        return self.trimmed.lowercased()
    }
}
