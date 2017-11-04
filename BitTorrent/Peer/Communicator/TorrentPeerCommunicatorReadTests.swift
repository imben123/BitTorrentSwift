//
//  TorrentPeerCommunicatorReadTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

extension TorrentPeerComminicatorTests {
    
    func test_observingTCPDelegate() {
        XCTAssert(tcpConnection.delegate! === sut)
    }
    
    func test_delegateCalledOnSocketConnected() {
        // Given
        try! sut.connect()
        
        // When
        sut.tcpConnection(tcpConnection, didConnectToHost: ip, port: port)
        
        // Then
        XCTAssert(delegate.peerConnectedCalled)
        XCTAssertEqual(delegate.peerConnectedParameter, sut)
    }
    
    func test_delegateCalledOnSocketDisconnected() {
        enum MyError: Error {
            case failure
        }
        
        sut.tcpConnection(tcpConnection, disconnectedWithError: MyError.failure)
        XCTAssert(delegate.peerLostCalled)
        XCTAssertEqual(delegate.peerLostParameter, sut)
    }
    
    func test_delegateCalled_whenPeerSendsHandshake() {
        sut.tcpConnection(tcpConnection, didRead: handshakePayload, withTag: 0)
        XCTAssert(delegate.peerSentHandshakeCalled)
        XCTAssertEqual(delegate.peerSentHandshakeParameters?.sender, sut)
        XCTAssertEqual(delegate.peerSentHandshakeParameters?.peerId, peerId)
        XCTAssertEqual(delegate.peerSentHandshakeParameters?.onDHT, false)
    }
    
    func test_delegateCalled_whenPeerSendsKeepAlive() {
        sut.tcpConnection(tcpConnection, didRead: handshakePayload, withTag: 0)
        sut.tcpConnection(tcpConnection, didRead: keepAlivePayload, withTag: 0)
        XCTAssert(delegate.peerSentKeepAliveCalled)
        XCTAssertEqual(delegate.peerSentKeepAliveParamter, sut)
    }
    
    func test_delegateCalledOnReceiveHandshake_andAnotherMessage() {
        sut.tcpConnection(tcpConnection, didRead: handshakePayload + keepAlivePayload, withTag: 0)
        XCTAssert(delegate.peerSentHandshakeCalled)
        XCTAssert(delegate.peerSentKeepAliveCalled)
    }
    
    func test_delegateCalled_whenPeerSendsChoke() {
        sut.tcpConnection(tcpConnection, didRead: handshakePayload, withTag: 0)
        sut.tcpConnection(tcpConnection, didRead: chokePayload, withTag: 0)
        XCTAssert(delegate.peerBecameChokedCalled)
        XCTAssertEqual(delegate.peerBecameChokedParameter, sut)
    }
    
    func test_delegateCalled_whenPeerSendsUnchoke() {
        sut.tcpConnection(tcpConnection, didRead: handshakePayload, withTag: 0)
        sut.tcpConnection(tcpConnection, didRead: unchokePayload, withTag: 0)
        XCTAssert(delegate.peerBecameUnchokedCalled)
        XCTAssertEqual(delegate.peerBecameUnchokedParameter, sut)
    }
    
    func test_delegateCalled_whenPeerSendsInterested() {
        sut.tcpConnection(tcpConnection, didRead: handshakePayload, withTag: 0)
        sut.tcpConnection(tcpConnection, didRead: interestedPayload, withTag: 0)
        XCTAssert(delegate.peerBecameInterestedCalled)
        XCTAssertEqual(delegate.peerBecameInterestedParameter, sut)
    }
    
    func test_delegateCalled_whenPeerSendsNotInterested() {
        sut.tcpConnection(tcpConnection, didRead: handshakePayload, withTag: 0)
        sut.tcpConnection(tcpConnection, didRead: notInterestedPayload, withTag: 0)
        XCTAssert(delegate.peerBecameUninterestedCalled)
        XCTAssertEqual(delegate.peerBecameUninterestedParameter, sut)
    }
    
    func test_delegateCalled_whenPeerSendsHave() {
        let pieceIndex = 345
        sut.tcpConnection(tcpConnection, didRead: handshakePayload, withTag: 0)
        sut.tcpConnection(tcpConnection, didRead: havePayload(pieceIndex: pieceIndex), withTag: 0)
        XCTAssert(delegate.peerHasPieceCalled)
        XCTAssertEqual(delegate.peerHasPieceParameters?.sender, sut)
        XCTAssertEqual(delegate.peerHasPieceParameters?.piece, pieceIndex)
    }
    
    func test_delegateCalled_whenPeerSendsBitfield() {
        
        var bitField = BitField(size: 16)
        bitField.set(at: 2)
        bitField.set(at: 5)
        bitField.set(at: 9)
        
        sut.tcpConnection(tcpConnection, didRead: handshakePayload, withTag: 0)
        sut.tcpConnection(tcpConnection, didRead: bitFieldPayload(bitField: bitField), withTag: 0)
        
        XCTAssert(delegate.peerHasBitFieldCalled)
        XCTAssertEqual(delegate.peerHasBitFieldParameters?.sender, sut)
        XCTAssertEqual(delegate.peerHasBitFieldParameters?.bitField, bitField)
    }
    
    func test_delegateCalled_whenPeerSendsRequest() {
        
        let index = 123
        let begin = 345
        let length = 567
        let payload = requestPayload(index: index, begin: begin, length: length)
        
        sut.tcpConnection(tcpConnection, didRead: handshakePayload, withTag: 0)
        sut.tcpConnection(tcpConnection, didRead: payload, withTag: 0)
        
        XCTAssert(delegate.peerRequestedPieceCalled)
        XCTAssertEqual(delegate.peerRequestedPieceParameters?.sender, sut)
        XCTAssertEqual(delegate.peerRequestedPieceParameters?.index, index)
        XCTAssertEqual(delegate.peerRequestedPieceParameters?.begin, begin)
        XCTAssertEqual(delegate.peerRequestedPieceParameters?.length, length)
    }
    
    func test_delegateCalled_whenPeerSendsPiece() {
        let index = 123
        let begin = 345
        let block = Data(bytes: [1,2,3])
        let payload = piecePayload(index: index, begin: begin, block: block)
        
        sut.tcpConnection(tcpConnection, didRead: handshakePayload, withTag: 0)
        sut.tcpConnection(tcpConnection, didRead: payload, withTag: 0)
        
        XCTAssert(delegate.peerSentPieceCalled)
        XCTAssertEqual(delegate.peerSentPieceParameters?.sender, sut)
        XCTAssertEqual(delegate.peerSentPieceParameters?.index, index)
        XCTAssertEqual(delegate.peerSentPieceParameters?.begin, begin)
        XCTAssertEqual(delegate.peerSentPieceParameters?.block, block)
    }
    
    func test_delegateCalled_whenPeerSendsCancel() {
        let index = 123
        let begin = 345
        let length = 567
        let payload = cancelPayload(index: index, begin: begin, length: length)
        
        sut.tcpConnection(tcpConnection, didRead: handshakePayload, withTag: 0)
        sut.tcpConnection(tcpConnection, didRead: payload, withTag: 0)
        
        XCTAssert(delegate.peerCancelledRequestedPieceCalled)
        XCTAssertEqual(delegate.peerCancelledRequestedPieceParameters?.sender, sut)
        XCTAssertEqual(delegate.peerCancelledRequestedPieceParameters?.index, index)
        XCTAssertEqual(delegate.peerCancelledRequestedPieceParameters?.begin, begin)
        XCTAssertEqual(delegate.peerCancelledRequestedPieceParameters?.length, length)
    }
    
    func test_delegateCalled_whenPeerSendDHTPort() {
        // TODO: implement with DHT peer discovery
    }
    
    func test_delegateCalled_onBadHandshake() {
        sut.tcpConnection(tcpConnection, didRead: Data(bytes: [1,2,3,4,99]), withTag: 0)
        
        XCTAssert(delegate.peerSentMalformedMessageCalled)
        XCTAssertEqual(delegate.peerSentMalformedMessageParameter, sut)
    }
    
    func test_delegateCalled_onBadMessage() {
        sut.tcpConnection(tcpConnection, didRead: handshakePayload, withTag: 0)
        sut.tcpConnection(tcpConnection, didRead: Data(bytes: [0,0,0,1,99,6,7,8,9,10]), withTag: 0)
        
        XCTAssert(delegate.peerSentMalformedMessageCalled)
        XCTAssertEqual(delegate.peerSentMalformedMessageParameter, sut)
    }
}
