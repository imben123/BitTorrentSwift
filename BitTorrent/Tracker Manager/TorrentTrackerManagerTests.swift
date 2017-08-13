//
//  TorrentTrackerManagerTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 12/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentTrackerManagerTests: XCTestCase {
    
    var sut: TorrentTrackerManager!
    
    let metaInfo: TorrentMetaInfo = {
        let path = Bundle(for: TorrentProgressManagerTests.self).path(forResource: "TestText", ofType: "torrent")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        return TorrentMetaInfo(data: data)!
    }()
    
    override func setUp() {
        super.setUp()        
        sut = TorrentTrackerManager(metaInfo: metaInfo, clientId: Data(), port: 123)
    }
    
    func test_foo() {
        print("")
    }
    
}
