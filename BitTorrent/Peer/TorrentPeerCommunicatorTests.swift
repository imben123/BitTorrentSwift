//
//  TorrentPeerCommunicatorTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 07/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentPeerComminicatorTests: XCTestCase {
    
    var tcpConnection: TCPConnectionStub!
    var sut: TorrentPeerCommunicator!
    
    let ip = "127.0.0.1"
    let port: UInt16 = 123
    let peerId = "-BD0000-bxa]N#IRKqv`".data(using: .ascii)!
    
    let expectedTimeout: TimeInterval = 10
    
    override func setUp() {
        super.setUp()
        
        let peer = TorrentPeerInfo(ip: ip, port: port, peerId: peerId)
        
        tcpConnection = TCPConnectionStub()
        sut = TorrentPeerCommunicator(peerInfo: peer, tcpConnection: tcpConnection)
    }
    
    func test_canConnect() {
        try! sut.connect()
        
        XCTAssert(tcpConnection.connectCalled)
        XCTAssertEqual(tcpConnection.connectParameters?.host, ip)
        XCTAssertEqual(tcpConnection.connectParameters?.port, port)
    }
    
    func test_sendHandshake() {
        
        let infoHash = Data(bytes: [1, 2, 3])
        let clientId = Data(bytes: [4, 5, 6])
        
        sut.sendHandshake(for: infoHash, clientId: clientId)
        
        let expectedPayload =
            Data(bytes: [19]) +                             // pstrlen (Protocol string length)
            "BitTorrent protocol".data(using: .ascii)! +    // pstr (Protocol string)
            Data(bytes: [0,0,0,0,0,0,0,0]) +                // reserved (8 reserved bytes)
            infoHash +                                      // info_hash
            clientId                                        // peer_id of the current user
        
        assertDataSent(expectedPayload)
    }
    
    func test_sendKeepAlive() {
        
        sut.sendKeepAlive()
        
        let expectedPayload = Data(bytes: [0, 0, 0, 0]) // Length prefix of 0
        
        assertDataSent(expectedPayload)
    }
    
    func test_sendChoke() {
        sut.sendChoke()
        let expectedPayload = Data(bytes: [
            0, 0, 0, 1, // Length 1
            0  // Id 0
            ])
        
        assertDataSent(expectedPayload)
    }
    
    func test_sendUnchoke() {
        sut.sendUnchoke()
        let expectedPayload = Data(bytes: [
            0, 0, 0, 1, // Length 1
            1           // Id 1
            ])
        
        assertDataSent(expectedPayload)
    }
    
    func testSendInterested() {
        sut.sendInterested()
        let expectedPayload = Data(bytes: [
            0, 0, 0, 1, // Length 1
            2           // Id 2
            ])
        
        assertDataSent(expectedPayload)
    }
    
    func testSendNotInterested() {
        sut.sendNotInterested()
        let expectedPayload = Data(bytes: [
            0, 0, 0, 1, // Length 1
            3           // Id 3
            ])
        
        assertDataSent(expectedPayload)
    }
    
    func test_sendHave() {
        let pieceIndex = 456
        sut.sendHavePiece(at: pieceIndex)
        let expectedPayload = Data(bytes: [0, 0, 0, 5, // Length 5
                                           4           // Id 4
            ]) + UInt32(pieceIndex).toData()           // Piece index
        
        assertDataSent(expectedPayload)
    }
    
    func test_sendBitField() {
        
        // Given
        var bitField = BitField(size: 10)
        bitField.set(at: 2)
        bitField.set(at: 5)
        bitField.set(at: 9)
        
        // When
        sut.sendBitField(bitField)
        
        // Then
        let expectedPayload = Data(bytes: [0, 0, 0, 3,  // Length 3
                                           5            // Id 5
            ]) + bitField.toData()                      // Piece index
        
        assertDataSent(expectedPayload)
    }
    
    func test_sendRequest() {
        
        let index = 123
        let begin = 456
        let length = 789
        sut.sendRequest(fromPieceAtIndex: index, begin: begin, length: length)
        
        let expectedPayload = Data(bytes: [0, 0, 0, 13, // Length 13
                                           6            // Id 6
            ]) + UInt32(index).toData() +               // index
            UInt32(begin).toData() +                    // begin
            UInt32(length).toData()                     // length
            
        assertDataSent(expectedPayload)
    }
    
    func test_sendPiece() {
        let index = 123
        let begin = 456
        let block = Data(bytes: [1,2,3])
        
        sut.sendPiece(fromPieceAtIndex: index, begin: begin, block: block)
        
        let expectedPayload = Data(bytes: [0, 0, 0, 12, // Length 12
                                           7            // Id 7
            ]) + UInt32(index).toData() +               // index
            UInt32(begin).toData() +                    // begin
            block                                       // block
        
        assertDataSent(expectedPayload)
    }
    
    func test_sendCancel() {
        
        let index = 123
        let begin = 456
        let length = 789
        sut.sendCancel(forPieceAtIndex: index, begin: begin, length: length)
        
        let expectedPayload = Data(bytes: [0, 0, 0, 13, // Length 13
                                           8            // Id 8
            ]) + UInt32(index).toData() +               // index
            UInt32(begin).toData() +                    // begin
            UInt32(length).toData()                     // length
        
        assertDataSent(expectedPayload)
    }
    
    func test_sendPort() {
        // TODO: implement with DHT peer discovery
    }
    
    // MARK: -
    
    func assertDataSent(_ data: Data) {
        XCTAssert(tcpConnection.writeDataCalled)
        XCTAssertEqual(tcpConnection.writeDataParameters?.timeout, expectedTimeout)
        XCTAssertEqual(tcpConnection.writeDataParameters?.data, data)
    }
}
