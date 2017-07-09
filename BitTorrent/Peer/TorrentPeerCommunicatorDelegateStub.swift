//
//  TorrentPeerCommunicatorDelegateStub.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 09/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

func XCTAssertEqual(_ lhs: TorrentPeerCommunicator?, _ rhs: TorrentPeerCommunicator?) {
    XCTAssert(lhs === rhs)
}

class TorrentPeerCommunicatorDelegateStub: TorrentPeerCommunicatorDelegate {
    
    var peerConnectedCalled = false
    var peerConnectedParameter: TorrentPeerCommunicator?
    func peerConnected(_ sender: TorrentPeerCommunicator) {
        peerConnectedCalled = true
        peerConnectedParameter = sender
    }
    
    var peerLostCalled = false
    var peerLostParameter: TorrentPeerCommunicator?
    func peerLost(_ sender: TorrentPeerCommunicator) {
        peerLostCalled = true
        peerLostParameter = sender
    }
    
    var peerSentHandshakeCalled = false
    var peerSentHandshakeParameters: (sender: TorrentPeerCommunicator, peerId: Data, onDHT: Bool)?
    func peerSentHandshake(_ sender: TorrentPeerCommunicator, sentHandshakeWithPeerId peerId: Data, onDHT: Bool) {
        peerSentHandshakeCalled = true
        peerSentHandshakeParameters = (sender, peerId, onDHT)
    }
    
    var peerSentKeepAliveCalled = false
    var peerSentKeepAliveParamter: TorrentPeerCommunicator?
    func peerSentKeepAlive(_ sender: TorrentPeerCommunicator) {
        peerSentKeepAliveCalled = true
        peerSentKeepAliveParamter = sender
    }
    
    var peerBecameChokedCalled = false
    var peerBecameChokedParameter: TorrentPeerCommunicator?
    func peerBecameChoked(_ sender: TorrentPeerCommunicator) {
        peerBecameChokedCalled = true
        peerBecameChokedParameter = sender
    }
    
    var peerBecameUnchokedCalled = false
    var peerBecameUnchokedParameter: TorrentPeerCommunicator?
    func peerBecameUnchoked(_ sender: TorrentPeerCommunicator) {
        peerBecameUnchokedCalled = true
        peerBecameUnchokedParameter = sender
    }
    
    var peerBecameInterestedCalled = false
    var peerBecameInterestedParameter: TorrentPeerCommunicator?
    func peerBecameInterested(_ sender: TorrentPeerCommunicator) {
        peerBecameInterestedCalled = true
        peerBecameInterestedParameter = sender
    }
    
    var peerBecameUninterestedCalled = false
    var peerBecameUninterestedParameter: TorrentPeerCommunicator?
    func peerBecameUninterested(_ sender: TorrentPeerCommunicator) {
        peerBecameUninterestedCalled = true
        peerBecameUninterestedParameter = sender
    }
    
    var peerHasPieceCalled = false
    var peerHasPieceParameters: (sender: TorrentPeerCommunicator, piece: Int)?
    func peer(_ sender: TorrentPeerCommunicator, hasPiece piece: Int) {
        peerHasPieceCalled = true
        peerHasPieceParameters = (sender, piece)
    }
    
    var peerHasBitFieldCalled = false
    var peerHasBitFieldParameters: (sender: TorrentPeerCommunicator, bitField: BitField)?
    func peer(_ sender: TorrentPeerCommunicator, hasBitField bitField: BitField) {
        peerHasBitFieldCalled = true
        peerHasBitFieldParameters = (sender, bitField)
    }
    
    var peerRequestedPieceCalled = false
    var peerRequestedPieceParameters: (sender: TorrentPeerCommunicator, index: Int, begin: Int, length: Int)?
    func peer(_ sender: TorrentPeerCommunicator, requestedPiece index: Int, begin: Int, length: Int) {
        peerRequestedPieceCalled = true
        peerRequestedPieceParameters = (sender, index, begin, length)
    }
    
    var peerSentPieceCalled = false
    var peerSentPieceParameters: (sender: TorrentPeerCommunicator, index: Int, begin: Int, block: Data)?
    func peer(_ sender: TorrentPeerCommunicator, sentPiece index: Int, begin: Int, block: Data) {
        peerSentPieceCalled = true
        peerSentPieceParameters = (sender, index, begin, block)
    }
    
    var peerCancelledRequestedPieceCalled = false
    var peerCancelledRequestedPieceParameters: (sender: TorrentPeerCommunicator, index: Int, begin: Int, length: Int)?
    func peer(_ sender: TorrentPeerCommunicator, cancelledRequestedPiece index: Int, begin: Int, length: Int) {
        peerCancelledRequestedPieceCalled = true
        peerCancelledRequestedPieceParameters = (sender, index, begin, length)
    }
    
    var peerOnDHTPortCalled = false
    var peerOnDHTPortParameters: (sender: TorrentPeerCommunicator, port: Int)?
    func peer(_ sender: TorrentPeerCommunicator, onDHTPort port: Int) {
        peerOnDHTPortCalled = true
        peerOnDHTPortParameters = (sender, port)
    }
    
    var peerSentMalformedMessageCalled = false
    var peerSentMalformedMessageParameter: TorrentPeerCommunicator?
    func peerSentMalformedMessage(_ sender: TorrentPeerCommunicator) {
        peerSentMalformedMessageCalled = true
        peerSentMalformedMessageParameter = sender
    }
}
