//
//  UpgradeTransaction.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import Foundation
import RealmSwift

/// this class holds pended transaction
/// pended transaction - is the transaction, that was not been
/// confirmed as succeeded or failed
class UpgradeTransaction: Object {
    
    /// transaction type
    @objc enum TransactionType: Int {
        case success
        case failure
    }
    
    /// holds transaction type
    @objc dynamic var type: TransactionType = .success
    
    /// holds transaction id
    @objc dynamic var transactionHid = ""
    
    /// holds transaction  message
    @objc dynamic var message = ""
}

