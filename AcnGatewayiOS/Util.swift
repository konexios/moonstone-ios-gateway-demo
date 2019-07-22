//
//  Util.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 02/11/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import FirebaseCrash

func FIRCrashPrintMessage(_ message: String) {
    print(message)
    FirebaseCrashMessage(message)
}
