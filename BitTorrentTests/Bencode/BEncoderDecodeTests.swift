//
//  BEncoderDecodeTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class BEncoderDecodeTests: XCTestCase {
    
    func testCanDecodeInteger() {
        encodeIntegerAndTestDecode(0)
//        encodeIntegerAndTestDecode(1)
//        encodeIntegerAndTestDecode(255)
//        encodeIntegerAndTestDecode(99999)
    }
    
    func encodeIntegerAndTestDecode(integer: Int) {
        let encodedInteger = BEncoder.encodeInteger(integer)
        decodeIntegerAndCompare(encodedInteger, expectedResult: integer)
    }
    
    func decodeIntegerAndCompare(bEncodedInteger: NSData, expectedResult: Int) {
        let result = BEncoder.decodeInteger(bEncodedInteger)
        XCTAssertEqual(result, expectedResult)
    }

}