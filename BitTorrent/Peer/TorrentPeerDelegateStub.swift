//
//  TorrentPeerDelegateStub.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 16/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

@testable import BitTorrent

class TorrentPeerDelegateStub: TorrentPeerDelegate {
    
    var peerCompletedHandshakeCalled = false
    var peerCompletedHandshakeParameter: TorrentPeer?
    func peerCompletedHandshake(_ sender: TorrentPeer) {
        peerCompletedHandshakeCalled = true
        peerCompletedHandshakeParameter = sender
    }
    
    var peerLostCalled = false
    var peerLostParameter: TorrentPeer?
    func peerLost(_ sender: TorrentPeer) {
        peerLostCalled = true
        peerLostParameter = sender
    }
    
    var failedToGetPieceAtIndexCalled = false
    var failedToGetPieceAtIndexParameters: (sender: TorrentPeer, index: Int)?
    func peer(_ sender: TorrentPeer, failedToGetPieceAtIndex index: Int) {
        failedToGetPieceAtIndexCalled = true
        failedToGetPieceAtIndexParameters = (sender, index)
    }
    
    var gotPieceAtIndexCalled = false
    var gotPieceAtIndexParameters: (sender: TorrentPeer, index: Int, piece: Data)?
    func peer(_ sender: TorrentPeer, gotPieceAtIndex index: Int, piece: Data) {
        gotPieceAtIndexCalled = true
        gotPieceAtIndexParameters = (sender, index, piece)
    }
}
