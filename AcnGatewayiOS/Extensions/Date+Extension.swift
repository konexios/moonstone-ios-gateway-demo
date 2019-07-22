//
//  Date+Extension.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 13/04/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

extension Date {
    
    struct Formatter {
        
        static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
            return formatter
        }()
        
        static let lastUserDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy HH:mm"
            return formatter
        }()
        
        static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter
        }()
        
        static let dateOnlyFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()
    }
    
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }

    var stringForLastUsedDate: String {
        return Formatter.lastUserDateFormatter.string(from: self)
    }
    
    var stringForTimer: String {
        return Formatter.timeFormatter.string(from: self)
    }
    
    var formattedString: String {
        return Formatter.lastUserDateFormatter.string(from: self)
    }

    var formattedDateOnly: String {
        return Formatter.dateOnlyFormatter.string(from: self)
    }

    var dateWithoutTime: Date {
        
        guard let timeZone = TimeZone(identifier: "UTC") else {
            return self
        }
        
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: self)
        
        if let date = calendar.date(from: dateComponents) {
            return date
        } else {
            return self
        }
    }    
}
