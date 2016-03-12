//
//  BEncoder+decode.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

public protocol ByteStream {
    var currentIndex: Int { get }
    func nextByte() -> Byte?
    func indexIsValid(index: Int) -> Bool
    func nextBytes(numberOfBytes: Int) -> NSData?
}

class NSDataByteStream: ByteStream {
    
    var currentIndex = 0
    private let data: NSData
    private let length: Int
    private var pointer: UnsafePointer<Byte>
    
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
    
    func indexIsValid(index: Int) -> Bool {
        return index >= 0 && index <= self.length
    }
    
    func nextBytes(numberOfBytes: Int) -> NSData? {
        if !self.indexIsValid(self.currentIndex + numberOfBytes) {
            return nil
        }
        return self.data.subdataWithRange(NSMakeRange(self.currentIndex, numberOfBytes))
    }
    
}

public extension BEncoder {
    
    public class func decodeInteger(data: NSData) throws -> Int {
        return try self.decodeInteger(NSDataByteStream(data: data))
    }
    
    public class func decodeInteger(byteStream: ByteStream) throws -> Int {
        
        try self.testFirstByte(byteStream, expectedFirstByte: ascii_i)

        return try self.buildAsciiIntegerFromStream(byteStream, terminator: ascii_e)
    }
    
    private class func buildAsciiIntegerFromStream(byteStream: ByteStream, terminator: Byte) throws -> Int {
        var currentDigit = byteStream.nextByte()
        var result: Int = 0
        while currentDigit != terminator {
            result = try self.appendNextDigitIfNotNil(result, currentDigit: currentDigit)
            currentDigit = byteStream.nextByte()
        }
        return result
    }
    
    private class func testFirstByte(byteStream: ByteStream, expectedFirstByte: Byte) throws {
        let firstByte = byteStream.nextByte()
        if firstByte != expectedFirstByte {
            throw BEncoderException.InvalidBEncode
        }
    }
    
    private class func appendNextDigitIfNotNil(integer: Int, currentDigit: Byte?) throws -> Int {
        if let digit = currentDigit {
            return try self.appendAsciiDigitToInteger(integer, digit: digit)
        } else {
            throw BEncoderException.InvalidBEncode
        }
    }
    
    private class func appendAsciiDigitToInteger(integer: Int, digit: UInt8) throws -> Int {
        do {
            return try integer.appendAsciiDigit(digit)
        } catch let e as AsciiError where e == AsciiError.Invalid {
            throw BEncoderException.InvalidBEncode
        }
    }
    
    public class func decodeByteString(data: NSData) throws -> NSData {
        return try self.decodeByteString(NSDataByteStream(data: data))
    }
    
    class func decodeByteString(byteStream: ByteStream) throws -> NSData {
        let numberOfBytes = try self.buildAsciiIntegerFromStream(byteStream, terminator: ascii_colon)
        if !byteStream.indexIsValid(byteStream.currentIndex + numberOfBytes) {
            throw BEncoderException.InvalidBEncode
        }
        return byteStream.nextBytes(numberOfBytes)!
    }

    
}
