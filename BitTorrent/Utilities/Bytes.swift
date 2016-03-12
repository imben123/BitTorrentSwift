//
//  Bytes.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

public typealias Byte = UInt8

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
    
    subscript(index: Int) -> Byte? {
        get {
            if index < 0 || index >= self.length {
                return nil
            }
            let originPointer = self.bytes
            let memoryPointer = UnsafePointer<Byte>(originPointer.advancedBy(index))
            return memoryPointer.memory
        }
    }
    
    subscript(range: Range<Int>) -> NSData? {
        get {
            let location = range.startIndex
            let length = range.endIndex - range.startIndex
            if range.startIndex < 0 || range.endIndex >= self.length {
                return nil
            }
            return self.subdataWithRange(NSMakeRange(location, length))
        }
    }
    
}

extension NSMutableData {
    
    func andData(data: NSData) -> NSMutableData {
        self.appendData(data)
        return self
    }
    
}

extension UInt8 {
    
    func toData() -> NSData {
        return NSData(byteArray: [self])
    }
    
    static func fromData(byte: NSData) -> UInt8 {
        let pointer = UnsafePointer<UInt8>(byte.bytes)
        return pointer.memory
    }
    
}