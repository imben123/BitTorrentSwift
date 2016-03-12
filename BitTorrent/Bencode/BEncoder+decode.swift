//
//  BEncoder+decode.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

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

    public class func decodeString(data: NSData) throws -> String {
        return try self.decodeString(NSDataByteStream(data: data));
    }

    class func decodeString(byteStream: ByteStream) throws -> String {
        let data = try self.decodeByteString(byteStream)
        guard let result = String(asciiData: data) else {
            throw AsciiError.Invalid
        }
        return result
    }
    
}
