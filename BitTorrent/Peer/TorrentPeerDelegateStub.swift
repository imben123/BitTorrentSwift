//
//  TorrentPeerDelegateStub.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 16/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

@testable import BitTorrent

class TorrentPeerDelegateStub: TorrentPeerDelegate {
    
    var peerHasNewAvailablePiecesCallCount = 0
    var peerHasNewAvailablePiecesParameter: TorrentPeer?
    func peerHasNewAvailablePieces(_ sender: TorrentPeer) {
        peerHasNewAvailablePiecesCallCount += 1
        peerHasNewAvailablePiecesParameter = sender
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
    
    var requestedPieceAtIndexCalled = false
    var requestedPieceAtIndexParameters: (sender: TorrentPeer, index: Int)?
    var requestedPieceAtIndexResult: Data?
    func peer(_ sender: TorrentPeer, requestedPieceAtIndex index: Int) -> Data? {
        requestedPieceAtIndexCalled = true
        requestedPieceAtIndexParameters = (sender, index)
        return requestedPieceAtIndexResult
    }
}
