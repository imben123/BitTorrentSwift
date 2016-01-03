//
//  Bytes.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

typealias Byte = UInt8

extension NSData {
    
    convenience init(byteArray: [UInt8]) {
        let pointer = UnsafePointer<Byte>(byteArray)
        self.init(bytes: pointer, length: byteArray.count)
    }
    
    func dataByAppendingData(data: NSData) -> NSData {
        let result = self.mutableCopy() as! NSMutableData
        result.appendData(data)
        return result
    }
    
}

extension NSMutableData {
    
    func andData(data: NSData) -> NSMutableData {
        self.appendData(data)
        return self
    }
    
}

extension UInt8 {
    
    func toBytes() -> NSData {
        return NSData(byteArray: [self])
    }
    
}