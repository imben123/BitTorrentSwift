//
//  AsciiTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 12/03/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class AssciiTests: XCTestCase {
    
    func testAsciiEncodeDigit() {
        doTestForAsciiEncodeDigit(0, ascii: 48)
        doTestForAsciiEncodeDigit(5, ascii: 53)
        doTestForAsciiEncodeDigit(9, ascii: 57)
    }
    
    func doTestForAsciiEncodeDigit(digit: UInt8, ascii: UInt8) {
        do {
            let value = try digit.asciiValue()
            XCTAssertEqual(value, ascii)
        } catch _ {
            XCTFail()
        }
    }
    
    func testInvalidAsciiDigit() {
        let digit: UInt8 = 10
        var caughtError = false
        
        do {
            let _ = try digit.asciiValue()
        } catch _ as AsciiError {
            caughtError = true
        } catch _ {}
        
        if !caughtError {
            XCTFail()
        }
    }
    
    func testAsciiEncodeInteger() {
        doTestForIntegerInAscii(0)
        doTestForIntegerInAscii(1)
        doTestForIntegerInAscii(123)
        doTestForIntegerInAscii(9999)
    }
    
    func doTestForIntegerInAscii(integer: Int) {
        let data = integer.digitsInAscii()
        let string = NSString(data: data, encoding: NSASCIIStringEncoding)
        XCTAssertEqual(string, "\(integer)")
    }
    
    func testAppendAsciiDigit() {
        doTestAppendAsciiDigit(123, digit: 4, expectedResult: 1234)
        doTestAppendAsciiDigit(1, digit: 0, expectedResult: 10)
        doTestAppendAsciiDigit(567, digit: 0, expectedResult: 5670)
        doTestAppendAsciiDigit(0, digit: 4, expectedResult: 4)
        doTestAppendAsciiDigit(0, digit: 0, expectedResult: 0)
    }
    
    func doTestAppendAsciiDigit(integer: Int, digit: UInt8, expectedResult: Int) {
        let result = try! integer.appendAsciiDigit(try! digit.asciiValue())
        XCTAssertEqual(result, expectedResult, "\(integer)\(digit) != \(result)")
    }
    
    func testAsciiEncodeString() {
        let string = "abc"
        let data = try! string.asciiValue()
        let result = NSString(data: data, encoding: NSASCIIStringEncoding)
        XCTAssertEqual(string, result)
    }
    
    func testAsciiEncodeStringThrowsOnInvalidAscii() {
        let string = "ab€c"
        var caughtError = false
        
        do {
            let _ = try string.asciiValue()
        } catch _ as AsciiError {
            caughtError = true
        } catch _ {}
        
        if !caughtError {
            XCTFail()
        }
    }
    
    func testAsciiEncodeCharacter() {
        doTestForCharacterInAscii("a")
        doTestForCharacterInAscii("z")
        doTestForCharacterInAscii("~")
        doTestForCharacterInAscii(" ")
    }
    
    func doTestForCharacterInAscii(character: Character) {
        let data = try! character.asciiValue()
        let string = NSString(data: data, encoding: NSASCIIStringEncoding)!
        XCTAssertEqual(string, "\(character)")
    }
    
    func testInvalidAsciiCharacter() {
        
        let character: Character = "€"
        var caughtError = false
        
        do {
            let _ = try character.asciiValue()
        } catch _ as AsciiError {
            caughtError = true
        } catch _ {}
        
        if !caughtError {
            XCTFail()
        }
    }
    
    func testAsciiToDigit() {
        doTestToConvertAsciiToDigit(0)
        doTestToConvertAsciiToDigit(5)
        doTestToConvertAsciiToDigit(9)
    }
    
    
    func doTestToConvertAsciiToDigit(integer: UInt8) {
        let ascii = try! integer.asciiValue()
        let result = try! ascii.fromAsciiValue()
        XCTAssertEqual(integer, result)
    }
    
    func testDecodeInvalidAsciiDigit() {
        doTestDecodeInvalidAsciiDigit(58)
        doTestDecodeInvalidAsciiDigit(47)
        doTestDecodeInvalidAsciiDigit(0)
        doTestDecodeInvalidAsciiDigit(UInt8.max)
    }
    
    func doTestDecodeInvalidAsciiDigit(invalidDigit: UInt8) {
        var caughtError = false
        
        do {
            let _ = try invalidDigit.fromAsciiValue()
        } catch _ as AsciiError {
            caughtError = true
        } catch _ {}
        
        if !caughtError {
            XCTFail()
        }
    }
    
    func testDecodeAsciiDigitData() {
        doTestDecodeAsciiDigitData(0)
        doTestDecodeAsciiDigitData(5)
        doTestDecodeAsciiDigitData(9)
    }
    
    func doTestDecodeAsciiDigitData(digit: UInt8) {
        let data = try! digit.asciiValue().toData()
        let result = try! UInt8.fromData(data).fromAsciiValue()
        XCTAssertEqual(digit, result)
    }
    
    func testEmptyDataGivesZeroIntegerValue() {
        let result = try! Int.fromAsciiData(NSData())
        XCTAssertEqual(result, 0)
    }
    
    func testDecodeAsciiInteger() {
        dotestDecodeAsciiInteger(0)
        dotestDecodeAsciiInteger(5)
        dotestDecodeAsciiInteger(255)
        dotestDecodeAsciiInteger(9999)
    }
    
    func dotestDecodeAsciiInteger(integer: Int) {
        let data = integer.digitsInAscii()
        let result = try! Int.fromAsciiData(data)
        XCTAssertEqual(result, integer)
    }
    
    func testErrorThrownIfInvalidAsciiData() {
        var caughtError = false
        
        do {
            let _ = try Int.fromAsciiData(NSData(byteArray: [0]))
        } catch _ as AsciiError {
            caughtError = true
        } catch _ {}
        
        if !caughtError {
            XCTFail()
        }
    }
    
}
