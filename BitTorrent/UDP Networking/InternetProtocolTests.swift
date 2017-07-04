//
//  InternetProtocolTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 03/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class InternetProtocolTests: XCTestCase {
    
    func test_canDecodeLocalhost() {
        let result = getIPAddress(of: "localhost")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, "127.0.0.1")
    }
    
    func test_invalidHostnameReturnsNil() {
        let result = getIPAddress(of: "asldfjhablskhdbj")
        XCTAssertNil(result)
    }
    
    func test_nonAsciiHostnameReturnsNil() {
        let result = getIPAddress(of: "🙁")
        XCTAssertNil(result)
    }
    
    func test_canDecodeGoogle() {
        let result = getIPAddress(of: "google.com")
        XCTAssertNotNil(result)
    }
    
    func test_canDecodeIPv4AddressFromData() {
        let data = Data(bytes: [16,2,122,105,127,0,0,1,0,0,0,0,0,0,0,0])
        let result = ipAddress(fromSockAddrData: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "127.0.0.1")
    }
    
    func test_canDecodeSocketPortFromData() {
        let data = Data(bytes: [16,2,122,105,127,0,0,1,0,0,0,0,0,0,0,0])
        let result = port(fromSockAddrData: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, 27002)
    }
}
