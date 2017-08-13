//
//  NetworkSpeedTrackerTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 13/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class NetworkSpeedTrackerTests: XCTestCase {
    
    func test_increaseBytes() {
        var sut = NetworkSpeedTracker()
        sut.increase(by: 10)
        XCTAssertEqual(sut.totalNumberOfBytes, 10)
    }
    
    func test_canGetBytesDownloadedSinceDate() {
        var sut = NetworkSpeedTracker()
        sut.increase(by: 2)
        let date = Date()
        sut.increase(by: 10)
        sut.increase(by: 5)
        XCTAssertEqual(sut.numberOfBytesDownloaded(since: date), 15)
    }
    
    func test_0BytesIfNoDataRecrodedSince() {
        var sut = NetworkSpeedTracker()
        sut.increase(by: 2)
        let date = Date()
        XCTAssertEqual(sut.numberOfBytesDownloaded(since: date), 0)
    }
    
    func test_canGetBytesOverAllTime() {
        let date = Date()
        var sut = NetworkSpeedTracker()
        sut.increase(by: 10)
        sut.increase(by: 5)
        XCTAssertEqual(sut.numberOfBytesDownloaded(since: date), 15)
    }
    
    func test_canGetBytesDownloadedOverTimePeriod() {
        var sut = NetworkSpeedTracker()
        sut.increase(by: 2)
        usleep(2000)
        sut.increase(by: 10)
        sut.increase(by: 5)
        let timePeriod: TimeInterval = 0.002
        XCTAssertEqual(sut.numberOfBytesDownloaded(over: timePeriod), 15)
    }
}
