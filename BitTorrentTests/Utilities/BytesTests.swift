//
//  BytesTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class BytesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEncode8BitInteger() {
        let integer: UInt8 = 123
        let data = integer.toData()
        
        let pointer = UnsafePointer<Byte>(data.bytes)
        let value: Byte = pointer.memory
        XCTAssertEqual(value, integer)
    }
    
    func testIntegerFromData() {
        doTestForIntegerFromData(0)
        doTestForIntegerFromData(5)
        doTestForIntegerFromData(UInt8.max)
    }
    
    func doTestForIntegerFromData(integer: UInt8) {
        let data = integer.toData()
        let result = UInt8.fromData(data)
        XCTAssertEqual(result, integer)
    }
    
    func testGetByteAtIndex() {
        let data = NSData(byteArray: [0,1,2,3,4,5])
        for i: Byte in 0...5 {
            XCTAssertEqual(data[Int(i)], i)
        }
    }
    
    func testOutOfBoundsExceptionOnInvalidIndex() {
        let data = NSData(byteArray: [0,1,2,3,4,5])
        
        let error1 = data[999]
        XCTAssertNil(error1)
        
        let error2 = data[6]
        XCTAssertNil(error2)
        
        let error3 = data[-1]
        XCTAssertNil(error3)
    }
}