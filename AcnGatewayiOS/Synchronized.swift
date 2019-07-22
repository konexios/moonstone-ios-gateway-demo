//
//  Synchronized.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 9/30/15.
//  Copyright © 2015 Arrow Electronics. All rights reserved.
//

import Foundation

///// Protocol for NSLocking objects that also provide tryLock()
//public protocol TryLockable: NSLocking {
//    func tryLock() -> Bool
//}
//
//// These Cocoa classes have tryLock()
//extension NSLock: TryLockable {}
//extension NSRecursiveLock: TryLockable {}
//extension NSConditionLock: TryLockable {}
//
//
///// Protocol for NSLocking objects that also provide lockBeforeDate()
//public protocol BeforeDateLockable: NSLocking {
//    func lockBeforeDate(_ limit: Date) -> Bool
//}
//
//// These Cocoa classes have lockBeforeDate()
//extension NSLock: BeforeDateLockable {}
//extension NSRecursiveLock: BeforeDateLockable {}
//extension NSConditionLock: BeforeDateLockable {}


/// Use an NSLocking object as a mutex for a critical section of code
public func synchronized<L: NSLocking>(_ lockable: L, criticalSection: () -> ()) {
    lockable.lock()
    criticalSection()
    lockable.unlock()
}

///// Use an NSLocking object as a mutex for a critical section of code that returns a result
//public func synchronizedResult<L: NSLocking, T>(_ lockable: L, criticalSection: () -> T) -> T {
//    lockable.lock()
//    let result = criticalSection()
//    lockable.unlock()
//    return result
//}
//
///// Use a TryLockable object as a mutex for a critical section of code
/////
///// Return true if the critical section was executed, or false if tryLock() failed
//public func trySynchronized<L: TryLockable>(_ lockable: L, criticalSection: () -> ()) -> Bool {
//    if !lockable.tryLock() {
//        return false
//    }
//    criticalSection()
//    lockable.unlock()
//    return true
//}
//
///// Use a BeforeDateLockable object as a mutex for a critical section of code
/////
///// Return true if the critical section was executed, or false if lockBeforeDate() failed
//public func synchronizedBeforeDate<L: BeforeDateLockable>(_ limit: Date, lockable: L, criticalSection: () -> ()) -> Bool {
//    if !lockable.lockBeforeDate(limit) {
//        return false
//    }
//    criticalSection()
//    lockable.unlock()
//    return true
//}

