//
//  BEncoderDecodeTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class ByteStreamTests: XCTestCase {

    func testCanCreateByteStreamWithData() {
        let _ = ByteStream(data: NSData())
    }
    
    func testCannotGetAnyBytesFromEmptyData() {
        let byteStream = ByteStream(data: NSData())
        let byte = byteStream.nextByte()
        XCTAssertNil(byte)
    }
    
    func testCanGetFirstByte() {
        let byteStream = ByteStream(data: NSData(byteArray: [5]))
        let byte = byteStream.nextByte()
        XCTAssertEqual(byte, 5)
    }
    
    func testCanGetFirstAndSecondByte() {
        let byteStream = ByteStream(data: NSData(byteArray: [5, 6]))
        let byte1 = byteStream.nextByte()
        let byte2 = byteStream.nextByte()
        XCTAssertEqual(byte1, 5)
        XCTAssertEqual(byte2, 6)
    }
    
    func testCannotGetMoreBytesThanExist() {
        let byteStream = ByteStream(data: NSData(byteArray: [5, 6]))
        let byte1 = byteStream.nextByte()
        let byte2 = byteStream.nextByte()
        let byte3 = byteStream.nextByte()
        XCTAssertEqual(byte1, 5)
        XCTAssertEqual(byte2, 6)
        XCTAssertNil(byte3)
    }
}

class BEncoderDecodeTests: XCTestCase {

    func testCanDecodeInteger() {
        encodeIntegerAndTestDecode(0)
        encodeIntegerAndTestDecode(1)
        encodeIntegerAndTestDecode(255)
        encodeIntegerAndTestDecode(99999)
    }
    
    func encodeIntegerAndTestDecode(integer: Int) {
        let encodedInteger = BEncoder.encodeInteger(integer)
        decodeIntegerAndCompare(encodedInteger, expectedResult: integer)
    }
    
    func decodeIntegerAndCompare(bEncodedInteger: NSData, expectedResult: Int) {
        let result = try! BEncoder.decodeInteger(bEncodedInteger)
        XCTAssertEqual(result, expectedResult)
    }
    
    func testExceptionThrownIfFirstCharacterNotLowerCaseI() {
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            try BEncoder.decodeInteger("x5e".asciiValue())
        }
    }
    
    func testExceptionThrownIfLastCharacterNotLowerCaseE() {
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            try BEncoder.decodeInteger("i5x".asciiValue())
        }
    }
    
    func testExceptionThrownIfMissingLastCharacter() {
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            try BEncoder.decodeInteger("i5".asciiValue())
        }
    }
    
    func testExceptionThrownIfNotValidNumber() {
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            try BEncoder.decodeInteger("ixe".asciiValue())
            try BEncoder.decodeInteger("i1x1e".asciiValue())
        }
    }
    
}

//class BEncoderDecodeTests: XCTestCase {
//    
//    // MARK: -
//    
//    func testDecode0ByteString() {
//        let input = try! NSMutableData(data: Character("0").asciiValue())
//            .andData(BEncoder.StringSizeDelimiter)
//        
//        let result = try! BEncoder.decodeByteString(input)
//        
//        XCTAssertEqual(result, NSData())
//    }
//    
//    func testDecode5ByteString() {
//        let byteString = NSData(byteArray: [ 1, 2, 3, 255, 0])
//        let input = try! NSMutableData(data: Character("5").asciiValue())
//            .andData(BEncoder.StringSizeDelimiter)
//            .andData(byteString)
//        
//        let result = try! BEncoder.decodeByteString(input)
//        
//        XCTAssertEqual(result, byteString)
//    }
//    
//    func testDecode10ByteString() {
//        let byteString = NSData(byteArray: [1,2,3,4,5,6,7,8,9,0])
//        let input = try! NSMutableData(data: "10".asciiValue())
//            .andData(BEncoder.StringSizeDelimiter)
//            .andData(byteString)
//        
//        let result = try! BEncoder.decodeByteString(input)
//        
//        XCTAssertEqual(result, byteString)
//    }
//    
//    func testExceptionThrownIfNoDelimiter() {
//        let input = try! NSMutableData(data: Character("1").asciiValue())
//            .andData(NSData(byteArray: [ 5 ]))
//        
//        assertExceptionThrown(BEncoderException.InvalidBEncode) {
//            let _ = try BEncoder.decodeByteString(input)
//        }
//        
//    }
//    
//    func testExceptionThrownIfStringLengthMissing() {
//        let input = NSMutableData(data: BEncoder.StringSizeDelimiter)
//            .andData(NSData(byteArray: [ 5 ]))
//        
//        assertExceptionThrown(BEncoderException.InvalidBEncode) {
//            let _ = try BEncoder.decodeByteString(input)
//        }
//    }
//    
//    func testExceptionThrownIfStringLengthIsNaN() {
//        let input = try! NSMutableData(data: Character("x").asciiValue())
//            .andData(BEncoder.StringSizeDelimiter)
//            .andData(NSData(byteArray: [ 5 ]))
//        
//        assertExceptionThrown(BEncoderException.InvalidBEncode) {
//            let _ = try BEncoder.decodeByteString(input)
//        }
//        
//    }
//    
//    func testExceptionThrownIfStringLengthWrong() {
//        
//        let shortInput = try! NSMutableData(data: Character("5").asciiValue())
//            .andData(BEncoder.StringSizeDelimiter)
//            .andData(NSData(byteArray: [ 1, 2, 3, 255]))
//        
//        let longInput = try! NSMutableData(data: Character("5").asciiValue())
//            .andData(BEncoder.StringSizeDelimiter)
//            .andData(NSData(byteArray: [ 1, 2, 3, 255, 0, 5]))
//        
//        
//        assertExceptionThrown(BEncoderException.InvalidBEncode) {
//            let _ = try BEncoder.decodeByteString(shortInput)
//            let _ = try BEncoder.decodeByteString(longInput)
//        }
//    }
//
//}