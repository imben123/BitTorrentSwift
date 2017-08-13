//
//  StringUtilities.swift
//  BitTorrentExample
//
//  Created by Ben Davis on 13/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

extension TimeInterval {
    
    var milliseconds: Int {
        return Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
    }
    
    var seconds: Int {
        return Int(self.remainder(dividingBy: 60))
    }
    
    var minutes: Int {
        return Int((self/60).remainder(dividingBy: 60))
    }
    
    var hours: Int {
        return Int(self / (60*60))
    }
    
    var stringTime: String {
        if self.hours != 0 {
            return "\(self.hours)h \(self.minutes)m \(self.seconds)s"
        } else if self.minutes != 0 {
            return "\(self.minutes)m \(self.seconds)s"
        } else if self.milliseconds != 0 {
            return "\(self.seconds)s \(self.milliseconds)ms"
        } else {
            return "\(self.seconds)s"
        }
    }
}

public let bytesInKB = 1024
public let bytesInMB = bytesInKB*1024
public let bytesInGB = bytesInMB*1024

public func twoDecimalPlaceFloat(_ float: Float) -> String {
    return String(format: "%.2f", float)
}

public func bytesToString(_ numberOfBytes: Int) -> String {
    if (numberOfBytes > bytesInGB) {
        let numberOfGBs: Float = Float(numberOfBytes) / Float(bytesInGB)
        return "\(twoDecimalPlaceFloat(numberOfGBs)) GB"
    } else if (numberOfBytes > bytesInMB) {
        let numberOfMBs: Float = Float(numberOfBytes) / Float(bytesInMB)
        return "\(twoDecimalPlaceFloat(numberOfMBs)) MB"
    } else if (numberOfBytes > bytesInKB) {
        let numberOfKBs: Float = Float(numberOfBytes) / Float(bytesInKB)
        return "\(twoDecimalPlaceFloat(numberOfKBs)) KB"
    } else {
        return "\(numberOfBytes) Bytes"
    }
}
