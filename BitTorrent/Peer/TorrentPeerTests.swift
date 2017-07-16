//
//  TorrentPeerTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 09/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentPeerTests: XCTestCase {
    
    let ip = "127.0.0.1"
    let port: UInt16 = 123
    let peerId = Data(repeating: 1, count: 20)
    let clientId = Data(repeating: 2, count: 20)
    let infoHash = Data(repeating: 3, count: 20)
    
    let pieceSize = Int(Double(TorrentPieceDownloadBuffer.blockSize)*2.5)
    let pieceIndex = 123
    
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
    
    func test_creation() {
        XCTAssertEqual(sut.peerInfo, peerInfo)
        XCTAssertTrue(sut.peerChoked)
        XCTAssertFalse(sut.peerInterested)
        XCTAssertTrue(sut.amChokedToPeer)
        XCTAssertFalse(sut.amInterestedInPeer)
    }
    
    // MARK: - Connection + handshake
    
    func test_canConnectToPeer() {
        try! sut.connect(withHandshakeData: (clientId, bitField))
        XCTAssert(communicator.connectCalled)
    }
    
    func test_handshakeSentOnConnect() {
        try! sut.connect(withHandshakeData: (clientId, bitField))
        
        communicator.delegate?.peerConnected(communicator)
        
        XCTAssert(communicator.sendHandshakeCalled)
        XCTAssertEqual(communicator.sendHandshakeParameters?.clientId, clientId)
    }
    
    func test_bitFieldSentAfterHandshake() {
        
        // Given
        try! sut.connect(withHandshakeData: (clientId, bitField))
        communicator.delegate?.peerConnected(communicator)
        guard let handshakeCompletion = communicator.sendHandshakeParameters?.completion else {
            XCTFail("Cannot notify sut of handshake completion")
            return
        }
        
        // When
        handshakeCompletion()
        
        // Then
        XCTAssert(communicator.sendBitFieldCalled)
        XCTAssertEqual(communicator.sendBitFieldParameters?.bitField, bitField)
    }
    
    func test_delegateNotifiedAfterHandshakeMade() {
        try! sut.connect(withHandshakeData: (clientId, bitField))
        communicator.delegate?.peerConnected(communicator)
        communicator.delegate?.peerSentHandshake(communicator, sentHandshakeWithPeerId: peerId, onDHT: false)
        
        XCTAssert(delegate.peerCompletedHandshakeCalled)
        XCTAssert(delegate.peerCompletedHandshakeParameter === sut)
    }
    
    // MARK: - Tracking peer status
    
    func test_bitFieldRecorded() {
        var bitField = BitField(size: 10)
        bitField.set(at: 0)
        communicator.delegate?.peer(communicator, hasBitField: bitField)
        XCTAssertEqual(sut.currentProgress, bitField)
    }
    
    func test_bitFieldUpdatedOnHave() {
        var bitField = BitField(size: 10)
        bitField.set(at: 0)
        bitField.set(at: 3)
        
        communicator.delegate?.peer(communicator, hasPiece: 0)
        communicator.delegate?.peer(communicator, hasPiece: 3)
        XCTAssertEqual(sut.currentProgress, bitField)
    }
    
    func test_stateUpdatedOnPeerUnchoked() {
        communicator.delegate?.peerBecameUnchoked(communicator)
        XCTAssertFalse(sut.peerChoked)
    }
    
    func test_stateUpdatedOnPeerChoked() {
        communicator.delegate?.peerBecameUnchoked(communicator)
        communicator.delegate?.peerBecameChoked(communicator)
        XCTAssertTrue(sut.peerChoked)
    }
    
    func test_stateUpdatedOnPeerInterested() {
        communicator.delegate?.peerBecameInterested(communicator)
        XCTAssertTrue(sut.peerInterested)
    }
    
    func test_stateUpdatedOnPeerUninterested() {
        communicator.delegate?.peerBecameInterested(communicator)
        communicator.delegate?.peerBecameUninterested(communicator)
        XCTAssertFalse(sut.peerInterested)
    }
    
    func test_interestedSentOnDownloadPieceRequest() {
        sut.downloadPiece(atIndex: pieceIndex, size: pieceSize)
        XCTAssert(communicator.sendInterestedCalled)
        XCTAssertTrue(sut.amInterestedInPeer)
    }
    
    func test_interestedNotSentIfAlreadyIntereseted() {
        // Given
        sut.downloadPiece(atIndex: pieceIndex, size: pieceSize)
        communicator.sendInterestedCalled = false
        
        // When
        sut.downloadPiece(atIndex: pieceIndex, size: pieceSize)
        
        // Then
        XCTAssertFalse(communicator.sendInterestedCalled)
    }
    
    // MARK: - Piece download requests
    
    func test_requestNotMadeIfPeerIsChoked() {
        sut.downloadPiece(atIndex: pieceIndex, size: pieceSize)
        XCTAssertFalse(communicator.sendRequestCalled)
    }
    
    func test_requestsMadeImmediatelyIfPeerIsUnchoked() {
        communicator.delegate?.peerBecameUnchoked(communicator)
        sut.downloadPiece(atIndex: pieceIndex, size: pieceSize)
        XCTAssertTrue(communicator.sendRequestCalled)
    }
    
    func test_sendPieceRequestOnUnchoke() {
        sut.downloadPiece(atIndex: pieceIndex, size: pieceSize)
        communicator.delegate?.peerBecameUnchoked(communicator)
        XCTAssertTrue(communicator.sendRequestCalled)
    }
    
    func test_correctBlockRequestsSent() {
        sut.downloadPiece(atIndex: pieceIndex, size: pieceSize)
        communicator.delegate?.peerBecameUnchoked(communicator)
        
        let blockSize = TorrentPieceDownloadBuffer.blockSize
        
        let requests = communicator.sendRequestParameters.sorted(by: { $0.begin < $1.begin }).map {
            TorrentBlockRequest(piece: $0.index, begin: $0.begin, length: $0.length)
        }
        
        let expected = [
            TorrentBlockRequest(piece: pieceIndex, begin: 0, length: blockSize),
            TorrentBlockRequest(piece: pieceIndex, begin: blockSize, length: blockSize),
            TorrentBlockRequest(piece: pieceIndex, begin: blockSize*2, length: Int(Double(blockSize)*0.5)),
        ]
        
        XCTAssertEqual(requests, expected)
    }
    
    func test_doesNotDownloadMoreThanMaximumNumberOfRequests() {
        
        let largePieceSize = TorrentPieceDownloadBuffer.blockSize * (TorrentPeer.maximumNumberOfPendingBlockRequests + 1)
        
        sut.downloadPiece(atIndex: pieceIndex, size: largePieceSize)
        communicator.delegate?.peerBecameUnchoked(communicator)
        
        XCTAssertEqual(communicator.sendRequestParameters.count, TorrentPeer.maximumNumberOfPendingBlockRequests)
    }
    
    func test_nextRequestMadeOnRecievingBlock() {
        let largePieceSize = TorrentPieceDownloadBuffer.blockSize * (TorrentPeer.maximumNumberOfPendingBlockRequests + 1)
        
        sut.downloadPiece(atIndex: pieceIndex, size: largePieceSize)
        communicator.delegate?.peerBecameUnchoked(communicator)
        
        guard let request = communicator.sendRequestParameters.first else { return }
        communicator.sendRequestParameters = []
        communicator.delegate?.peer(communicator,
                                    sentPiece: request.index,
                                    begin: request.begin,
                                    block: Data(repeating: 0, count: request.length))
        
        XCTAssertEqual(communicator.sendRequestParameters.count, 1)
    }
    
    func test_delegateNotifiedFailedToGetPiece_whenPeerChokes() {
        communicator.delegate?.peerBecameUnchoked(communicator)
        sut.downloadPiece(atIndex: pieceIndex, size: pieceSize)
        communicator.delegate?.peerBecameChoked(communicator)
        
        XCTAssert(delegate.failedToGetPieceAtIndexCalled)
        XCTAssert(delegate.failedToGetPieceAtIndexParameters?.sender === sut)
        XCTAssertEqual(delegate.failedToGetPieceAtIndexParameters?.index, pieceIndex)
    }
    
    func test_delegateNotifiedOnSuccessfulPieceDownload() {
        communicator.delegate?.peerBecameUnchoked(communicator)
        sut.downloadPiece(atIndex: pieceIndex, size: pieceSize)
        
        let requests = communicator.sendRequestParameters.sorted(by: { $0.begin < $1.begin })
        var expectedResult: Data = Data()
        
        var i: UInt8 = 1
        for request in requests {
            let block = Data(repeating: i, count: request.length)
            communicator.delegate?.peer(communicator,
                                        sentPiece: request.index,
                                        begin: request.begin,
                                        block: block)
            i += 1
            expectedResult += block
        }
        
        XCTAssert(delegate.gotPieceAtIndexCalled)
        XCTAssert(delegate.gotPieceAtIndexParameters?.sender === sut)
        XCTAssertEqual(delegate.gotPieceAtIndexParameters?.index, pieceIndex)
        XCTAssertEqual(delegate.gotPieceAtIndexParameters?.piece, expectedResult)
    }
    
    // MARK: - Peer connection lost
    
    func test_delegateNotifiedOnPeerLost() {
        communicator.delegate?.peerLost(communicator)
        
        XCTAssert(delegate.peerLostCalled)
        XCTAssert(delegate.peerLostParameter === sut)
    }
    
    func test_delegateNotifiedFailedToGetPiece_whenPeerLost() {
        communicator.delegate?.peerBecameUnchoked(communicator)
        sut.downloadPiece(atIndex: pieceIndex, size: pieceSize)
        communicator.delegate?.peerLost(communicator)
        
        XCTAssert(delegate.failedToGetPieceAtIndexCalled)
        XCTAssert(delegate.failedToGetPieceAtIndexParameters?.sender === sut)
        XCTAssertEqual(delegate.failedToGetPieceAtIndexParameters?.index, pieceIndex)
    }
    
    // MARK: -
}
