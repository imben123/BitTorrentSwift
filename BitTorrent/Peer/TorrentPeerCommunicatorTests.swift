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
    var delegate: TorrentPeerCommunicatorDelegateStub!
    var sut: TorrentPeerCommunicator!
    
    let ip = "127.0.0.1"
    let port: UInt16 = 123
    let peerId = "-BD0000-bxa]N#IRKqv`".data(using: .ascii)!
    let expectedTimeout: TimeInterval = 10
    
    let infoHash = Data(repeating: 1, count: 20)
    
    let handshakePayload: Data = {
        var result = Data(bytes: [19])                         // pstrlen (Protocol string length)
        result += "BitTorrent protocol".data(using: .ascii)!   // pstr (Protocol string)
        result += Data(bytes: [0,0,0,0,0,0,0,0])               // reserved (8 reserved bytes)
        result += Data(repeating: 1, count: 20)                // info_hash
        result += "-BD0000-bxa]N#IRKqv`".data(using: .ascii)!  // peer_id of the current user
        return result
    }()
    
    let keepAlivePayload = Data(bytes: [0, 0, 0, 0])    // Length prefix of 0
    
    let chokePayload = Data(bytes: [
        0, 0, 0, 1, // Length 1
        0  // Id 0
        ])
    
    let unchokePayload = Data(bytes: [
        0, 0, 0, 1, // Length 1
        1  // Id 1
        ])
    
    let interestedPayload = Data(bytes: [
        0, 0, 0, 1, // Length 1
        2  // Id 2
        ])
    
    let notInterestedPayload = Data(bytes: [
        0, 0, 0, 1, // Length 1
        3           // Id 3
        ])
    
    func havePayload(pieceIndex: Int) -> Data {
        return Data(bytes:
            [0, 0, 0, 5,                  // Length 5
             4]) +                        // Id 4
            UInt32(pieceIndex).toData()   // Piece index
    }
    
    func bitFieldPayload(bitField: BitField) -> Data {
        return Data(bytes:
            [0, 0, 0, 3,        // Length 3
             5]) +              // Id 5
            bitField.toData()   // Piece index
    }
    
    func requestPayload(index: Int, begin: Int, length: Int) -> Data {
        return Data(bytes:
            [0, 0, 0, 13,                   // Length 13
            6                               // Id 6
            ]) + UInt32(index).toData() +   // index
            UInt32(begin).toData() +        // begin
            UInt32(length).toData()         // length
    }
    
    func piecePayload(index: Int, begin: Int, block: Data) -> Data {
        return Data(bytes:
            [0, 0, 0, 12,                   // Length 12
            7                               // Id 7
            ]) + UInt32(index).toData() +   // index
            UInt32(begin).toData() +        // begin
            block                           // block
    }
    
    func cancelPayload(index: Int, begin: Int, length: Int) -> Data {
        return Data(bytes:
            [0, 0, 0, 13,                   // Length 13
            8                               // Id 8
            ]) + UInt32(index).toData() +   // index
            UInt32(begin).toData() +        // begin
            UInt32(length).toData()         // length
    }
    
    override func setUp() {
        super.setUp()
        
        let peer = TorrentPeerInfo(ip: ip, port: port, peerId: peerId)
        
        tcpConnection = TCPConnectionStub()
        delegate = TorrentPeerCommunicatorDelegateStub()
        sut = TorrentPeerCommunicator(peerInfo: peer,
                                      infoHash: infoHash,
                                      tcpConnection: tcpConnection)
        sut.delegate = delegate
    }
    
    func test_canConnect() {
        try! sut.connect()
        
        XCTAssert(tcpConnection.connectCalled)
        XCTAssertEqual(tcpConnection.connectParameters?.host, ip)
        XCTAssertEqual(tcpConnection.connectParameters?.port, port)
    }
    
    func test_sendHandshake() {
        sut.sendHandshake(for: infoHash, clientId: peerId)
        assertDataSent(handshakePayload)
    }
    
    func test_sendKeepAlive() {        
        sut.sendKeepAlive()
        assertDataSent(keepAlivePayload)
    }
    
    func test_sendChoke() {
        sut.sendChoke()
        assertDataSent(chokePayload)
    }
    
    func test_sendUnchoke() {
        sut.sendUnchoke()
        assertDataSent(unchokePayload)
    }
    
    func testSendInterested() {
        sut.sendInterested()
        assertDataSent(interestedPayload)
    }
    
    func testSendNotInterested() {
        sut.sendNotInterested()
        assertDataSent(notInterestedPayload)
    }
    
    func test_sendHave() {
        let pieceIndex = 456
        sut.sendHavePiece(at: pieceIndex)
        let expectedPayload = havePayload(pieceIndex: pieceIndex)
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
        let expectedPayload = bitFieldPayload(bitField: bitField)
        assertDataSent(expectedPayload)
    }
    
    func test_sendRequest() {
        let index = 123
        let begin = 456
        let length = 789
        
        sut.sendRequest(fromPieceAtIndex: index, begin: begin, length: length)
        
        let expectedPayload = requestPayload(index: index, begin: begin, length: length)
        assertDataSent(expectedPayload)
    }
    
    func test_sendPiece() {
        let index = 123
        let begin = 456
        let block = Data(bytes: [1,2,3])
        
        sut.sendPiece(fromPieceAtIndex: index, begin: begin, block: block)
        
        let expectedPayload = piecePayload(index: index, begin: begin, block: block)
        assertDataSent(expectedPayload)
    }
    
    func test_sendCancel() {
        let index = 123
        let begin = 456
        let length = 789
        
        sut.sendCancel(forPieceAtIndex: index, begin: begin, length: length)
        
        let expectedPayload = cancelPayload(index: index, begin: begin, length: length)
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
