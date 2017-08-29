//
//  TorrentPeerUploadingTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 29/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentPeerUploadingTests: XCTestCase {
    
    let ip = "127.0.0.1"
    let port: UInt16 = 123
    let peerId = Data(repeating: 1, count: 20)
    let clientId = Data(repeating: 2, count: 20)
    let infoHash = Data(repeating: 3, count: 20)
    
    let bitField: BitField = {
        var bitField = BitField(size: 10)
        bitField.set(at: 2)
        bitField.set(at: 5)
        bitField.set(at: 9)
        return bitField
    }()
    
    var delegate: TorrentPeerDelegateStub!
    var communicator: TorrentPeerCommunicatorStub!
    var peerInfo: TorrentPeerInfo!
    var sut: TorrentPeer!
    
    override func setUp() {
        super.setUp()
        
        peerInfo = TorrentPeerInfo(ip: ip, port: port, peerId: peerId)
        communicator = TorrentPeerCommunicatorStub(peerInfo: peerInfo,
                                                   infoHash: infoHash,
                                                   tcpConnection: TCPConnectionStub())
        delegate = TorrentPeerDelegateStub()
        sut = TorrentPeer(peerInfo: peerInfo, bitFieldSize: 10, communicator: communicator)
        sut.delegate = delegate
    }
    
    func test_pieceSentOnRequest() {
        
        // Given
        let pieceIndex = 123
        let begin = 0
        let data = Data(repeating: 4, count: 10)
        delegate.requestedPieceAtIndexResult = data
        
        // When
        sut.peer(communicator, requestedPiece: pieceIndex, begin: begin, length: 10)
        
        // Then
        XCTAssert(delegate.requestedPieceAtIndexCalled)
        XCTAssertEqual(communicator.sendPieceCallCount, 1)
        if let sendPieceParameters = communicator.sendPieceParameters {
            XCTAssertEqual(sendPieceParameters.index, pieceIndex)
            XCTAssertEqual(sendPieceParameters.begin, begin)
            XCTAssertEqualData(sendPieceParameters.block, data)
        }
    }
    
    func test_blocksSentOneByOne() {
        
        // Given
        let pieceIndex = 123
        let begin1 = 0
        let begin2 = 10
        let data = Data(repeating: 4, count: 10)
        delegate.requestedPieceAtIndexResult = data
        
        // When
        sut.peer(communicator, requestedPiece: pieceIndex, begin: begin1, length: 10)
        sut.peer(communicator, requestedPiece: pieceIndex, begin: begin2, length: 10)
        
        // Then
        XCTAssertEqual(communicator.sendPieceCallCount, 1)
        
        // And When
        guard let sendPieceParameters = communicator.sendPieceParameters else { return }
        sendPieceParameters.completion?()
        
        // Then
        XCTAssertEqual(communicator.sendPieceCallCount, 2)
        if let sendPieceParameters2 = communicator.sendPieceParameters {
            XCTAssertEqual(sendPieceParameters2.begin, begin2)
        }
    }
    
    func test_canRequestMultiplePieces() {
        
        // Given
        let pieceIndex1 = 1
        let pieceIndex2 = 2
        let data = Data(repeating: 0, count: 10)
        delegate.requestedPieceAtIndexResult = data
        
        // When
        sut.peer(communicator, requestedPiece: pieceIndex1, begin: 0, length: 10)
        sut.peer(communicator, requestedPiece: pieceIndex1, begin: 10, length: 10)
        sut.peer(communicator, requestedPiece: pieceIndex2, begin: 0, length: 10)
        
        communicator.sendPieceParameters?.completion?()
        communicator.sendPieceParameters?.completion?()
        communicator.sendPieceParameters?.completion?()
        
        // Then
        XCTAssertEqual(communicator.sendPieceCallCount, 3)
    }
    
    func test_peerCanCancelUnsentBlock() {
        
        // Given
        let pieceIndex = 123
        let begin1 = 0
        let begin2 = 10
        let data = Data(repeating: 4, count: 10)
        delegate.requestedPieceAtIndexResult = data
        
        // When
        sut.peer(communicator, requestedPiece: pieceIndex, begin: begin1, length: 10)
        sut.peer(communicator, requestedPiece: pieceIndex, begin: begin2, length: 10)
        sut.peer(communicator, cancelledRequestedPiece: pieceIndex, begin: begin2, length: 10)
        
        // And When
        communicator.sendPieceParameters?.completion?()
        
        // Then
        XCTAssertEqual(communicator.sendPieceCallCount, 1)
    }
    
    func test_onLostPeerUploadStops() {
        
        // Given
        let pieceIndex = 123
        let begin1 = 0
        let begin2 = 10
        let data = Data(repeating: 4, count: 10)
        delegate.requestedPieceAtIndexResult = data
        
        // When
        sut.peer(communicator, requestedPiece: pieceIndex, begin: begin1, length: 10)
        sut.peer(communicator, requestedPiece: pieceIndex, begin: begin2, length: 10)
        sut.peerLost(communicator)
        
        // And When
        communicator.sendPieceParameters?.completion?()
        
        // Then
        XCTAssertEqual(communicator.sendPieceCallCount, 1)
    }
    
    func test_onPeerChokedUploadsCancelled() {
        
        // Given
        let pieceIndex = 123
        let begin1 = 0
        let begin2 = 10
        let data = Data(repeating: 4, count: 10)
        delegate.requestedPieceAtIndexResult = data
        
        // When
        sut.peer(communicator, requestedPiece: pieceIndex, begin: begin1, length: 10)
        sut.peer(communicator, requestedPiece: pieceIndex, begin: begin2, length: 10)
        sut.peerBecameChoked(communicator)
        
        // Even if
        sut.peerBecameUnchoked(communicator)
        
        // Then When
        communicator.sendPieceParameters?.completion?()
        
        // Then
        XCTAssertEqual(communicator.sendPieceCallCount, 1)
    }
    
    func test_onPeerUninterestedUploadsCancelled() {
        
        // Given
        let pieceIndex = 123
        let begin1 = 0
        let begin2 = 10
        let data = Data(repeating: 4, count: 10)
        delegate.requestedPieceAtIndexResult = data
        
        // When
        sut.peer(communicator, requestedPiece: pieceIndex, begin: begin1, length: 10)
        sut.peer(communicator, requestedPiece: pieceIndex, begin: begin2, length: 10)
        sut.peerBecameUninterested(communicator)
        
        // Even if
        sut.peerBecameUnchoked(communicator)
        
        // Then When
        communicator.sendPieceParameters?.completion?()
        
        // Then
        XCTAssertEqual(communicator.sendPieceCallCount, 1)
    }
}
