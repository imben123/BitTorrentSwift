//
//  Ascii.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

enum AsciiError: ErrorType {
    case Invalid
}

extension UInt8 {
    
    func asciiValue() throws -> UInt8 {
        if self >= 10 {
            throw AsciiError.Invalid
        }
        return self + 48 // 48 is ascii for 0
    }
    
    func fromAsciiValue() throws -> UInt8 {
        if self > 57 || self < 48 {
            throw AsciiError.Invalid
        }
        return self - 48 // 48 is ascii for 0
    }
    
}

extension Int {
    
    func digitsInAscii() -> NSData {
        let (head, tailByte) = self.splitAndAsciiEncodeLastDigit()
        if head > 0 {
            return head.digitsInAscii().dataByAppendingData(tailByte)
        }
        return tailByte
    }
    
    private func splitAndAsciiEncodeLastDigit() -> (head: Int, tail: NSData) {
        let (head, tail) = splitDigitsOnLast()
        return (head, try! tail.digitAsAsciiByte())
    }
    
    private func digitAsAsciiByte() throws -> NSData {
        return try UInt8(self).asciiValue().toData()
    }
    
    private func splitDigitsOnLast() -> (head: Int, tail: Int) {
        return (self / 10, self % 10)
    }
    
    static func fromAsciiData(data: NSData) throws -> Int {
        if data.length == 0 {
            return 0
        }
        let (headOfData, decodedLastByte) = try self.splitDataAndDecodeLastByte(data)
        let resultOfDecodingTheHead = try self.fromAsciiData(headOfData)
        return decodedLastByte + ( 10 * resultOfDecodingTheHead )
    }
    
    private static func splitDataAndDecodeLastByte(data: NSData) throws -> (NSData, Int) {
        let (headOfData, lastByte) = self.splitDataBeforeLastByte(data)
        let decodedLastByte = try lastByte.fromAsciiValue()
        return (headOfData, Int(decodedLastByte))
    }
    
    private static func splitDataBeforeLastByte(data: NSData) -> (NSData, UInt8) {
        let lastByte = self.getLastByte(data)
        let headOfData = data.subdataWithRange(NSMakeRange(0, data.length-1))
        return (headOfData, lastByte)
    }
    
    private static func getLastByte(data: NSData) -> Byte {
        let bytePointer = UnsafePointer<Byte>(data.bytes)
        let lastBytePointer = bytePointer.advancedBy(data.length-1)
        return lastBytePointer.memory
    }
    
}

extension Int {
    
    func appendAsciiDigit(asciiDigit: Byte) throws -> Int {
        let digit = Int(try asciiDigit.fromAsciiValue())
        return self*10 + digit
    }
    
}

extension Character {
    
    func asciiValue() throws -> NSData {
        let unicodeScalarCodePoint = self.unicodeScalarCodePoint()
        if !unicodeScalarCodePoint.isASCII() {
            throw AsciiError.Invalid
        }
        return UInt8(ascii: unicodeScalarCodePoint).toData()
    }
    
    func unicodeScalarCodePoint() -> UnicodeScalar {
        let characterString = String(self)
        let scalars = characterString.unicodeScalars
        return scalars[scalars.startIndex]
    }
    
}

extension String {
    
    init?(asciiData: NSData) {
        self.init(data: asciiData, encoding: NSASCIIStringEncoding)
    }
    
    func asciiValue() throws -> NSData {
        guard let result = (self as NSString).dataUsingEncoding(NSASCIIStringEncoding) else {
            throw AsciiError.Invalid
        }
        return result
    }
    
}