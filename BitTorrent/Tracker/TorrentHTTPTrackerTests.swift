//
//  TorrentHTTPTrackerTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 27/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentTrackerDelegateSpy: TorrentTrackerDelegate {
    
    var receivedResponseCalled = false
    var receivedResponseParameter: TorrentTrackerResponse? = nil
    
    var receivedErrorMessageCalled = false
    var receivedErrorMessageParameter: String? = nil
    
    func torrentTracker(_ sender: Any, receivedResponse response: TorrentTrackerResponse) {
        receivedResponseCalled = true
        receivedResponseParameter = response
    }
    
    func torrentTracker(_ sender: Any, receivedErrorMessage errorMessage: String) {
        receivedErrorMessageCalled = true
        receivedErrorMessageParameter = errorMessage
    }
}

class TorrentHTTPTrackerTests: XCTestCase {
    
    var connectionStub: HTTPConnectionStub!
    var sut: TorrentHTTPTracker!
    
    var delegateSpy: TorrentTrackerDelegateSpy!
    
    let expectedURLParameters: [String: String] = [
        "info_hash": "%F0%B8q%98%99S%97%3F%BF%A9M%C8%14%98%EE%8D%20%5B%B2%23",
        "peer_id" : "peerId",
        "port" : "123",
        "uploaded" : "1234",
        "downloaded" : "4321",
        "left" : "456",
        "compact" : "1",
        "event" : "started",
        "numwant" : "321",
        ]
    
    let basicResponseData = "d8:completei1e10:incompletei2e8:intervali600e5:peers0:e".data(using: .ascii)!
    
    override func setUp() {
        super.setUp()
        
        let path = Bundle(for: type(of: self)).path(forResource: "TestText", ofType: "torrent")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let metaInfo = TorrentMetaInfo(data: data)!
        
        connectionStub = HTTPConnectionStub()
        sut = TorrentHTTPTracker(metaInfo: metaInfo, connection: connectionStub)
        
        delegateSpy = TorrentTrackerDelegateSpy()
        sut.delegate = delegateSpy
    }
    
    func performAnnounce(withEvent event: TorrentTrackerEvent) {
        sut.announceClient(with: "peerId",
                           port: 123,
                           event: event,
                           infoHash: Data(bytes: [7,8,9]),
                           numberOfBytesRemaining: 456,
                           numberOfBytesUploaded: 1234,
                           numberOfBytesDownloaded: 4321,
                           numberOfPeersToFetch: 321)
    }
    
    func test_announce() {
        performAnnounce(withEvent: .started)
        let request = connectionStub.lastRequest
        XCTAssertEqual(request.url.absoluteString, "http://127.0.0.1:53420/announce")
        XCTAssertEqual(request.urlParameters!, expectedURLParameters)
    }
    
    func test_sendStoppedEvent() {
        performAnnounce(withEvent: .stopped)
        let request = connectionStub.lastRequest
        XCTAssertEqual(request.urlParameters!["event"], "stopped")
    }
    
    func test_sendCompletedEvent() {
        performAnnounce(withEvent: .completed)
        let request = connectionStub.lastRequest
        XCTAssertEqual(request.urlParameters!["event"], "completed")
    }
    
    func test_delegateNotifiedOnTrackerResponse() {
        
        performAnnounce(withEvent: .started)
        
        connectionStub.completeLastRequest(with: HTTPResponse(completed: true,
                                                              responseData: basicResponseData,
                                                              statusCode: 200))
        
        XCTAssert(delegateSpy.receivedResponseCalled)
    }
    
    func test_basicResponseParsing() {
        
        performAnnounce(withEvent: .started)
        
        connectionStub.completeLastRequest(with: HTTPResponse(completed: true,
                                                              responseData: basicResponseData,
                                                              statusCode: 200))
        
        let response = delegateSpy.receivedResponseParameter!
        
        XCTAssertEqual(response.numberOfPeersComplete, 1)
        XCTAssertEqual(response.numberOfPeersIncomplete, 2)
        XCTAssertNil(response.trackerId)
        XCTAssertEqual(response.interval, 600)
        XCTAssertEqual(response.minimumInterval, 0)
        XCTAssertNil(response.warning)
    }
    
    func test_optionalResponseFieldsParsing() {
        performAnnounce(withEvent: .started)
        
        let completeResponse = "d15:warning message7:warning10:tracker id9:trackerId12:min intervali60e8:completei1e10:incompletei2e8:intervali600e5:peers0:e".data(using: .ascii)!
        
        connectionStub.completeLastRequest(with: HTTPResponse(completed: true,
                                                              responseData: completeResponse,
                                                              statusCode: 200))
        
        let response = delegateSpy.receivedResponseParameter!
        
        XCTAssertEqual(response.trackerId, "trackerId".data(using: .ascii))
        XCTAssertEqual(response.minimumInterval, 60)
        XCTAssertEqual(response.warning, "warning")
    }
    
    func test_binaryPeersFormat() {
        performAnnounce(withEvent: .started)
        
        let peersBinary = Data(bytes: [0x7f, 0x00, 0x00, 0x01, 0x3c, 0x17, 0x7f, 0x00, 0x00, 0x01, 0x1a, 0xe1])
        
        let responseData = "d8:completei1e10:incompletei2e8:intervali600e5:peers12:".data(using: .ascii)! +
            peersBinary +
            "e".data(using: .ascii)!
        
        connectionStub.completeLastRequest(with: HTTPResponse(completed: true,
                                                              responseData: responseData,
                                                              statusCode: 200))
        
        let response = delegateSpy.receivedResponseParameter!
        
        XCTAssertEqual(response.peers.count, 2)
        XCTAssertEqual(response.peers.first!.ip, "127.0.0.1")
        XCTAssertEqual(response.peers.first!.port, 15383)
        XCTAssertEqual(response.peers.last!.ip, "127.0.0.1")
        XCTAssertEqual(response.peers.last!.port, 6881)
    }
    
    func test_dictionaryPeersFormat() {
        performAnnounce(withEvent: .started)
        
        let peer1Id = "peerId1-------------"
        let peer1IP = "127.0.0.1"
        let peer1Port = 15383
        let peer2Id = "peerId2-------------"
        let peer2IP = "127.0.0.1"
        let peer2Port = 6881
        
        let peer1 = "d7:peer id20:\(peer1Id)2:ip9:\(peer1IP)4:porti\(peer1Port)ee"
        let peer2 = "d7:peer id20:\(peer2Id)2:ip9:\(peer2IP)4:porti\(peer2Port)ee"
        
        let responseData = "d8:completei1e10:incompletei2e8:intervali600e5:peersl\(peer1)\(peer2)ee".data(using: .ascii)!
        
        connectionStub.completeLastRequest(with: HTTPResponse(completed: true,
                                                              responseData: responseData,
                                                              statusCode: 200))
        
        let response = delegateSpy.receivedResponseParameter!
        
        XCTAssertEqual(response.peers.count, 2)
        
        XCTAssertEqual(response.peers.first!.peerId!, peer1Id.data(using: .ascii))
        XCTAssertEqual(response.peers.first!.ip, peer1IP)
        XCTAssertEqual(response.peers.first!.port, peer1Port)
        
        XCTAssertEqual(response.peers.last!.peerId!, peer2Id.data(using: .ascii))
        XCTAssertEqual(response.peers.last!.ip, peer2IP)
        XCTAssertEqual(response.peers.last!.port, peer2Port)
    }
    
    func test_failResponseDoesNotCallDelegate() {
        performAnnounce(withEvent: .started)
        
        let responseData = "d14:failure reason45:invalid info_hash (not 20 chars):123length: 3e".data(using: .ascii)
        
        connectionStub.completeLastRequest(with: HTTPResponse(completed: true,
                                                              responseData: responseData,
                                                              statusCode: 200))
        
        XCTAssertFalse(delegateSpy.receivedResponseCalled)
        XCTAssert(delegateSpy.receivedErrorMessageCalled)
        XCTAssertEqual(delegateSpy.receivedErrorMessageParameter, "invalid info_hash (not 20 chars):123length: 3")
    }
    
    func test_invalidTrackerResponse() {
        performAnnounce(withEvent: .started)
        
        connectionStub.completeLastRequest(with: HTTPResponse(completed: true,
                                                              responseData: Data(),
                                                              statusCode: 500))
        
        XCTAssertFalse(delegateSpy.receivedResponseCalled)
        XCTAssertFalse(delegateSpy.receivedErrorMessageCalled)
    }
}
