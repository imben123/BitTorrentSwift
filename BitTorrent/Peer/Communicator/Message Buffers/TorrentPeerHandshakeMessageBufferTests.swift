//
//  TorrentPeerHandshakeMessageBufferTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 09/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentPeerHandshakeDelegateStub: TorrentPeerHandshakeDelegate {
    
    var gotBadHandshakeCalled = false
    var gotBadHandshakeError: TorrentPeerHandshakeMessageBufferError?
    func peerHandshakeMessageBuffer(_ sender: TorrentPeerHandshakeMessageBuffer,
                                    gotBadHandshake error: TorrentPeerHandshakeMessageBufferError) {
        gotBadHandshakeCalled = true
        gotBadHandshakeError = error
    }
    
    var gotHandshakeCalled = false
    var gotHandshakeParameters: (sender: TorrentPeerHandshakeMessageBuffer, peerId: Data, remainingBuffer: Data, onDHT: Bool)?
    func peerHandshakeMessageBuffer(_ sender: TorrentPeerHandshakeMessageBuffer,
                                    gotHandshakeWithPeerId peerId: Data,
                                    remainingBuffer: Data,
                                    onDHT: Bool) {
        gotHandshakeCalled = true
        gotHandshakeParameters = (sender, peerId, remainingBuffer, onDHT)
    }
}

class TorrentPeerHandshakeMessageBufferTests: XCTestCase {
    
    var delegate: TorrentPeerHandshakeDelegateStub!
    var sut: TorrentPeerHandshakeMessageBuffer!
    
    let infoHash = Data(repeating: 1, count: 20)
    let peerId = Data(repeating: 2, count: 20)
    
    override func setUp() {
        super.setUp()
        
        delegate = TorrentPeerHandshakeDelegateStub()
        sut = TorrentPeerHandshakeMessageBuffer(infoHash: infoHash, peerId: peerId)
        sut.delegate = delegate
    }
    
    func test_canParseHandshake() {
        var data = UInt8(19).toData() // protocol length
        data = data + "BitTorrent protocol".data(using: .ascii)! // protocol
        data = data + Data(bytes: [0,0,0,0,0,0,0,0]) // 8 reserved bits
        data = data + infoHash // info_hash
        data = data + peerId // peer_id
        
        sut.appendData(data)
        
        XCTAssert(delegate.gotHandshakeCalled)
        XCTAssert(delegate.gotHandshakeParameters?.sender === sut)
        XCTAssertEqualData(delegate.gotHandshakeParameters?.peerId, peerId)
        XCTAssertEqualData(delegate.gotHandshakeParameters?.remainingBuffer, Data())
        XCTAssertEqual(delegate.gotHandshakeParameters?.onDHT, false)
    }
    
    func test_handshakeReceivedInChunks() {
        var data = UInt8(19).toData() // protocol length
        data = data + "BitTorrent protocol".data(using: .ascii)! // protocol
        data = data + Data(bytes: [0,0,0,0,0,0,0,0]) // 8 reserved bits
        data = data + infoHash // info_hash
        data = data + peerId // peer_id
        
        let data1 = data.correctingIndicies[0..<30]
        let data2 = data.correctingIndicies[30..<data.count]
        
        sut.appendData(data1)
        XCTAssertFalse(delegate.gotHandshakeCalled)
        
        sut.appendData(data2)
        XCTAssert(delegate.gotHandshakeCalled)
    }
    
    func test_remainingData() {
        
        let extraBytes = Data(bytes: [1,2,3])
        
        var data = UInt8(19).toData() // protocol length
        data = data + "BitTorrent protocol".data(using: .ascii)! // protocol
        data = data + Data(bytes: [0,0,0,0,0,0,0,0]) // 8 reserved bits
        data = data + infoHash // info_hash
        data = data + peerId // peer_id
        data = data + extraBytes
        
        sut.appendData(data)
        
        XCTAssert(delegate.gotHandshakeCalled)
        XCTAssertEqualData(delegate.gotHandshakeParameters?.remainingBuffer, extraBytes)
    }
    
    func test_canParseOnDHTPeerDiscoveryNetwork() {
        
        var data = UInt8(19).toData() // protocol length
        data = data + "BitTorrent protocol".data(using: .ascii)! // protocol
        data = data + Data(bytes: [0,0,0,0,0,0,0,1]) // 8 reserved bits
        data = data + infoHash // info_hash
        data = data + peerId // peer_id
        
        sut.appendData(data)
        
        XCTAssertEqual(delegate.gotHandshakeParameters?.onDHT, true)
    }
    
    func test_errorCalledIfProtocolIsNot19Characters() {
        let data = UInt8(18).toData() // protocol length
        sut.appendData(data)
        XCTAssert(delegate.gotBadHandshakeCalled)
        assertError(delegate.gotBadHandshakeError, isError: .protocolMismatch)
    }
    
    func test_errorCalledIfProtocolIsDifferent() {
        var data = UInt8(19).toData() // protocol length
        data = data + "BitTorrent protocoz".data(using: .ascii)! // protocol
        sut.appendData(data)
        XCTAssert(delegate.gotBadHandshakeCalled)
        assertError(delegate.gotBadHandshakeError, isError: .protocolMismatch)
    }
    
    func test_errorCalledIfInfoHashDoesNotMatch() {
        var data = UInt8(19).toData() // protocol length
        data = data + "BitTorrent protocol".data(using: .ascii)! // protocol
        data = data + Data(bytes: [0,0,0,0,0,0,0,0]) // 8 reserved bits
        data = data + Data(repeating: 3, count: 20) // info_hash
        sut.appendData(data)
        XCTAssert(delegate.gotBadHandshakeCalled)
        assertError(delegate.gotBadHandshakeError, isError: .infoHashMismatch)
    }
    
    func test_errorCalledIfPeerIdDoesNotMatch() {
        var data = UInt8(19).toData() // protocol length
        data = data + "BitTorrent protocol".data(using: .ascii)! // protocol
        data = data + Data(bytes: [0,0,0,0,0,0,0,0]) // 8 reserved bits
        data = data + infoHash // info_hash
        data = data + Data(repeating: 3, count: 20) // peer_id
        
        sut.appendData(data)
        
        XCTAssert(delegate.gotBadHandshakeCalled)
        assertError(delegate.gotBadHandshakeError, isError: .peerIdMismatch)
    }
    
    func test_nilPeerIdIsAlwaysAccepted() {
        
        let sut = TorrentPeerHandshakeMessageBuffer(infoHash: infoHash, peerId: nil)
        sut.delegate = delegate
        
        var data = UInt8(19).toData() // protocol length
        data = data + "BitTorrent protocol".data(using: .ascii)! // protocol
        data = data + Data(bytes: [0,0,0,0,0,0,0,0]) // 8 reserved bits
        data = data + infoHash // info_hash
        data = data + Data(repeating: 3, count: 20) // peer_id
        
        sut.appendData(data)
        
        XCTAssert(delegate.gotHandshakeCalled)
    }
    
    // MARK: -
    
    func assertError(_ error: TorrentPeerHandshakeMessageBufferError?,
                     isError expected: TorrentPeerHandshakeMessageBufferError,
                     file: StaticString = #file,
                     line: UInt = #line) {
        
        guard let error = error else {
            XCTFail("Error is nil", file: file, line: line)
            return
        }
        
        switch error {
        case expected:
            return
        default:
            XCTFail("Error doesn't match", file: file, line: line)
        }
    }
}
