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
        let result = InternetProtocol.getIPAddress(of: "localhost")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, "127.0.0.1")
    }
    
    // Bad test
//    func test_invalidHostnameReturnsNil() {
//        let result = InternetProtocol.getIPAddress(of: "asldfjhablskhdbj")
//        XCTAssertNil(result)
//    }
    
    func test_nonAsciiHostnameReturnsNil() {
        let result = InternetProtocol.getIPAddress(of: "🙁")
        XCTAssertNil(result)
    }
    
    // Bad Test
//    func test_canDecodeGoogle() {
//        let result = InternetProtocol.getIPAddress(of: "google.com")
//        XCTAssertNotNil(result)
//    }
    
    func test_canDecodeIPv4AddressFromData() {
        let data = Data(bytes: [16,2,122,105,127,0,0,1,0,0,0,0,0,0,0,0])
        let result = InternetProtocol.ipAddress(fromSockAddrData: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, "127.0.0.1")
    }
    
    func test_canDecodeSocketPortFromData() {
        let data = Data(bytes: [16,2,122,105,127,0,0,1,0,0,0,0,0,0,0,0])
        let result = InternetProtocol.port(fromSockAddrData: data)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, 27002)
    }
}
