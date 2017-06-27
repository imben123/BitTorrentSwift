//
//  URLEncodeTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 27/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class URLEncodeTests: XCTestCase {
    
    func test_canEncodeBinaryAsURLEncodedString() {
        
        let data = Data(bytes: [0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf1, 0x23, 0x45,
                                0x67, 0x89, 0xab, 0xcd, 0xef, 0x12, 0x34, 0x56, 0x78, 0x9a])
        
        let expected = "%124Vx%9A%BC%DE%F1%23Eg%89%AB%CD%EF%124Vx%9A"
        
        let result = String(urlEncodingData: data)
        
        XCTAssertEqual(result, expected)
    }
    
}
