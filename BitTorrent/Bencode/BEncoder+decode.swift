//
//  BEncoder+decode.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

class ByteStream {
    
    let data: NSData
    private var pointer: UnsafePointer<Byte>
    private var currentIndex = 0
    private let length: Int
    
    init(data: NSData) {
        self.data = data
        self.pointer = UnsafePointer<Byte>(data.bytes)
        self.length = data.length
    }
    
    func nextByte() -> Byte? {
        if self.currentIndex == self.length {
            return nil
        }
        let result = self.pointer.memory
        self.advancePointer()
        return result
    }
    
    private func advancePointer() {
        self.pointer = self.pointer.advancedBy(1)
        self.currentIndex++
    }
    
}

public extension BEncoder {

    
}

//extension NSData {
//    
//    func rangeAfterByteAtIndex(index: Int) -> NSRange {
//        return NSMakeRange(index+1, self.length-index-1)
//    }
//    
//}
//
//public extension BEncoder {
//    
//    private static let zeroBEncodeString = try! "0:".asciiValue()
//
//    public class func decodeIntegerWithTrailingData(data: NSData) throws -> Int {
////        let indexOfTerminatingCharacter = self.findIndexOfTerminatingCharacter(data)
////        if let indexOfTerminatingCharacter = indexOfTerminatingCharacter {
////            return self.decodeInteger(data[])
////        } else {
////            throw BEncoderException.InvalidBEncode
////        }
//        return 0
//    }
//    
//    private class func findIndexOfTerminatingCharacter(data: NSData) -> Int? {
//        for var i = 0; i < data.length; i++ {
//            let byte = data[i]
//            if byte == StructureEndToken[0] {
//                return i
//            }
//        }
//        return nil
//    }
//    
//    public class func decodeInteger(data: NSData) throws -> Int {
//        let firstByte = data.subdataWithRange(NSMakeRange(0, 1))
//        let lastByte  = data.subdataWithRange(NSMakeRange(data.length-1, 1))
//        let asciiI = try! "i".asciiValue()
//        let asciiE = try! "e".asciiValue()
//        if firstByte != asciiI || lastByte != asciiE {
//            throw BEncoderException.InvalidBEncode
//        }
//        let rangeOfIntegerBytes = NSMakeRange(1, data.length-2)
//        let integerBytes = data.subdataWithRange(rangeOfIntegerBytes)
//        do {
//            return try Int.fromAsciiData(integerBytes)
//        } catch let e as AsciiError where e == AsciiError.Invalid {
//            throw BEncoderException.InvalidBEncode
//        }
//    }
//    
//    public class func decodeByteString(data: NSData) throws -> NSData {
//        let rangeOfByteString = try self.rangeOfByteStringIfValidBEncode(data)
//        return data.subdataWithRange(rangeOfByteString)
//    }
//    
//    private class func rangeOfByteStringIfValidBEncode(data: NSData) throws -> NSRange {
//        
//        guard let colonIndex = self.indexOfDelimiterIfNotZero(data) else {
//            throw BEncoderException.InvalidBEncode
//        }
//        
//        try self.testStringLength(data, colonIndex: colonIndex)
//        
//        return data.rangeAfterByteAtIndex(colonIndex)
//    }
//    
//    private class func indexOfDelimiterIfNotZero(data: NSData) -> Int? {
//        let result = self.indexOfDelimiter(data)
//        if let result = result where result == 0 {
//            return nil
//        }
//        return result
//    }
//    
//    private class func indexOfDelimiter(data: NSData) -> Int? {
//        for i in 0..<data.length {
//            let byte = data.subdataWithRange(NSMakeRange(i, 1))
//            if byte == BEncoder.StringSizeDelimiter {
//                return i
//            }
//        }
//        return nil
//    }
//    
//    private class func testStringLength(data: NSData, colonIndex: Int) throws {
//        let stringLengthData = data.subdataWithRange(NSMakeRange(0, colonIndex))
//        var stringLength = 0
//        do {
//            stringLength = try Int.fromAsciiData(stringLengthData)
//        } catch let e as AsciiError where e == AsciiError.Invalid {
//            throw BEncoderException.InvalidBEncode
//        }
//        
//        if data.length-colonIndex-1 != stringLength {
//            throw BEncoderException.InvalidBEncode
//        }
//    }
//    
//}