//
//  NSDataByteStreamTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 12/03/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class NSDataByteStreamTests: XCTestCase {
    
    func testCanCreateByteStreamWithData() {
        let _ = NSDataByteStream(data: NSData())
    }
    
    func testCannotGetAnyBytesFromEmptyData() {
        let byteStream = NSDataByteStream(data: NSData())
        let byte = byteStream.nextByte()
        XCTAssertNil(byte)
    }
    
    func testCanGetFirstByte() {
        let byteStream = NSDataByteStream(data: NSData(byteArray: [5]))
        let byte = byteStream.nextByte()
        XCTAssertEqual(byte, 5)
    }
    
    func testCanGetFirstAndSecondByte() {
        let byteStream = NSDataByteStream(data: NSData(byteArray: [5, 6]))
        let byte1 = byteStream.nextByte()
        let byte2 = byteStream.nextByte()
        XCTAssertEqual(byte1, 5)
        XCTAssertEqual(byte2, 6)
    }
    
    func testCannotGetMoreBytesThanExist() {
        let byteStream = NSDataByteStream(data: NSData(byteArray: [5, 6]))
        let byte1 = byteStream.nextByte()
        let byte2 = byteStream.nextByte()
        let byte3 = byteStream.nextByte()
        XCTAssertEqual(byte1, 5)
        XCTAssertEqual(byte2, 6)
        XCTAssertNil(byte3)
    }
    
    func testCanGetMultipleBytes() {
        let byteStream = NSDataByteStream(data: NSData(byteArray: [5, 6, 7]))
        let bytes = byteStream.nextBytes(2)
        XCTAssertEqual(bytes, NSData(byteArray: [5, 6]))
    }
    
    func testCanGetAllBytes() {
        let byteStream = NSDataByteStream(data: NSData(byteArray: [5, 6, 7]))
        let bytes = byteStream.nextBytes(3)
        XCTAssertEqual(bytes, NSData(byteArray: [5, 6, 7]))
    }
    
    func testCanGet0Bytes() {
        let byteStream = NSDataByteStream(data: NSData(byteArray: [5, 6, 7]))
        let bytes = byteStream.nextBytes(0)
        XCTAssertEqual(bytes, NSData())
    }
    
    func testCannotGetTooManyBytes() {
        let byteStream = NSDataByteStream(data: NSData(byteArray: [5, 6, 7]))
        let bytes = byteStream.nextBytes(4)
        XCTAssertNil(bytes)
    }
    
    func testCanGetDataMultipleTimes() {
        let byteStream = NSDataByteStream(data: NSData(byteArray: [5, 6, 7, 8]))
        let bytes1 = byteStream.nextBytes(2)
        let bytes2 = byteStream.nextBytes(2)
        XCTAssertEqual(bytes1, NSData(byteArray: [5, 6]))
        XCTAssertEqual(bytes2, NSData(byteArray: [7, 8]))
    }
    
    func testCanGetDataAndByte() {
        let byteStream = NSDataByteStream(data: NSData(byteArray: [5, 6, 7]))
        let bytes = byteStream.nextBytes(2)
        let byte = byteStream.nextByte()
        XCTAssertEqual(bytes, NSData(byteArray: [5, 6]))
        XCTAssertEqual(byte, UInt8(7))
    }
}
