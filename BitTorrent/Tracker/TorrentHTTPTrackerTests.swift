//
//  TorrentHTTPTrackerTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 27/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentHTTPTrackerTests: XCTestCase {
    
    var connectionStub: HTTPConnectionStub!
    var sut: TorrentHTTPTracker!
    
    override func setUp() {
        super.setUp()
        
        let path = Bundle(for: type(of: self)).path(forResource: "TestText", ofType: "torrent")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let metaInfo = TorrentMetaInfo(data: data)!
        
        connectionStub = HTTPConnectionStub()
        sut = TorrentHTTPTracker(metaInfo: metaInfo, connection: connectionStub)
    }
    
    func test_announce() {
        
        sut.announceClient(with: "peerId",
                           port: 123,
                           numberOfBytesRemaining: 456,
                           infoHash: Data(bytes: [7,8,9]),
                           numberOfPeersToFetch: 321,
                           peerKey: "key")
        
        let request = connectionStub.lastRequest
        
        let expectedURLParameters = [
            "info_hash": "%F0%B8q%98%99S%97%3F%BF%A9M%C8%14%98%EE%8D%20%5B%B2%23",
            "peer_id" : "peerId",
            "port" : "123",
            "uploaded" : "0",
            "downloaded" : "0",
            "left" : "456",
            "compact" : "1",
            "event" : "started",
            "numwant" : "321",
            "key" : "key",
        ]
        
        XCTAssertEqual(request.url.absoluteString, "http://127.0.0.1:53420/announce")
        XCTAssertEqual(request.urlParameters!, expectedURLParameters)
    }
    
}
