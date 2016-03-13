//
//  BEncoder+decode.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

public extension BEncoder {
    
    /**
     Decodes BEncoded data to swift objects
     
     - parameter byteStream: Any class implementing the ByteStream protocol that will feed the
     decoder sequential bytes from BEncoded data.
     
     - throws: BEncoderException.InvalidBEncode if unable to decode the data
     
     - returns: An Int, String, NSData, Array or Dictionary depending on the type of the
     BEncoded data
     */
    public class func decode(byteStream: ByteStream) throws -> AnyObject {
        let firstByte = byteStream.nextByte()
        byteStream.advanceBy(-1)

        if firstByte == ascii_i {
            return try self.decodeInteger(byteStream)
        } else if firstByte == ascii_l {
            return try self.decodeList(byteStream)
        } else if firstByte == ascii_d {
            return try self.decodeDictionary(byteStream)
        } else {
            return try self.decodeByteString(byteStream)
        }
    }
    
    /**
     Convenience method to decode NSData.
     */
    public class func decode(data: NSData) throws -> AnyObject {
        return try self.decode(NSDataByteStream(data: data))
    }

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

    public class func decodeString(byteStream: ByteStream) throws -> String {
        let data = try self.decodeByteString(byteStream)
        guard let result = String(asciiData: data) else {
            throw BEncoderException.InvalidBEncode
        }
        return result
    }
    
    public class func decodeList(data: NSData) throws -> [AnyObject] {
        return try self.decodeList(NSDataByteStream(data: data))
    }
    
    public class func decodeList(byteStream: ByteStream) throws -> [AnyObject] {
        var result: [AnyObject] = []
        let firstByte = byteStream.nextByte()
        
        if firstByte != ascii_l {
            throw BEncoderException.InvalidBEncode
        }
        
        var currentByte = byteStream.nextByte()
        while currentByte != ascii_e {
            byteStream.advanceBy(-1)
            let object = try self.decode(byteStream)
            result.append(object)
            currentByte = byteStream.nextByte()
        }
        return result
    }
    
    public class func decodeDictionary(data: NSData) throws -> [NSData: AnyObject] {
        return try self.decodeDictionary(NSDataByteStream(data: data))
    }

    public class func decodeDictionary(byteStream: ByteStream) throws -> [NSData: AnyObject] {
        
        var result: [NSData:AnyObject] = [:]
        
        var currentByte = byteStream.nextByte()
        currentByte = byteStream.nextByte()
        
        while currentByte != ascii_e {
            
            byteStream.advanceBy(-1)
            
            let key = try self.decodeByteString(byteStream)
            let object = try self.decode(byteStream)
            
            result[key] = object
            
            currentByte = byteStream.nextByte()
            
        }
        return result
    }

}
