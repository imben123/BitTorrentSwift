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
        return UInt8(self + 48) // 48 is ascii for 0
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
    
    private func digitAsAsciiByte() throws -> NSData {
        return try UInt8(self).asciiValue().toBytes()
    }
    
    private func splitAndAsciiEncodeLastDigit() -> (head: Int, tail: NSData) {
        let (head, tail) = splitDigitsOnLast()
        return (head, try! tail.digitAsAsciiByte())
    }
    
    private func splitDigitsOnLast() -> (head: Int, tail: Int) {
        return (self / 10, self % 10)
    }
    
}

extension Character {
    
    func asciiValue() throws -> NSData {
        let unicodeScalarCodePoint = self.unicodeScalarCodePoint()
        if !unicodeScalarCodePoint.isASCII() {
            throw AsciiError.Invalid
        }
        return UInt8(ascii: unicodeScalarCodePoint).toBytes()
    }
    
    func unicodeScalarCodePoint() -> UnicodeScalar {
        let characterString = String(self)
        let scalars = characterString.unicodeScalars
        return scalars[scalars.startIndex]
    }
    
}

extension String {
    
    func asciiValue() -> NSData {
        let data = NSMutableData()
        for character in self.utf8 {
            data.appendData(character.toBytes())
        }
        return data
    }
    
}