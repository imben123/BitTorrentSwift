//
//  TorrentPeerManagerTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 12/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentPeerFake: TorrentPeer {
    
    var connectCalled = false
    var connectHandshakeData: (clientId: Data, bitField: BitField)?
    override func connect(withHandshakeData handshakeData: (clientId: Data, bitField: BitField)) throws {
        connectCalled = true
        connectHandshakeData = handshakeData
        try super.connect(withHandshakeData: handshakeData)
    }
    
    var downloadPieceCalled = false
    var downloadPieceParameters: (index: Int, size: Int)?
    override func downloadPiece(atIndex index: Int, size: Int) {
        downloadPieceCalled = true
        downloadPieceParameters = (index, size)
    }
}

class TorrentPeerManagerDelegateStub: TorrentPeerManagerDelegate {
    
    var downloadedPieceAtIndexCalled = false
    var downloadedPieceAtIndexParameters: (sender: TorrentPeerManager, pieceIndex: Int, piece: Data)?
    func torrentPeerManager(_ sender: TorrentPeerManager,
                            downloadedPieceAtIndex pieceIndex: Int,
                            piece: Data) {
        downloadedPieceAtIndexCalled = true
        downloadedPieceAtIndexParameters = (sender, pieceIndex, piece)
    }
    
    var failedToGetPieceAtIndexCalled = false
    var failedToGetPieceAtIndexParameters: (sender: TorrentPeerManager, index: Int)?
    func torrentPeerManager(_ sender: TorrentPeerManager, failedToGetPieceAtIndex index: Int) {
        failedToGetPieceAtIndexCalled = true
        failedToGetPieceAtIndexParameters = (sender, index)
    }
    
    var torrentPeerManagerNextPieceToDownloadCalled = false
    var torrentPeerManagerNextPieceToDownloadResult: (pieceIndex: Int, size: Int)? = nil
    func torrentPeerManagerNextPieceToDownload(_ sender: TorrentPeerManager) -> (pieceIndex: Int, size: Int)? {
        torrentPeerManagerNextPieceToDownloadCalled = true
        return torrentPeerManagerNextPieceToDownloadResult
    }
    
    var torrentPeerManagerCurrentBitfieldForHandshakeCalled = false
    var torrentPeerManagerCurrentBitfieldForHandshakeResult = BitField(size: 0)
    func torrentPeerManagerCurrentBitfieldForHandshake(_ sender: TorrentPeerManager) -> BitField {
        torrentPeerManagerCurrentBitfieldForHandshakeCalled = true
        return torrentPeerManagerCurrentBitfieldForHandshakeResult
    }
}

class TorrentPeerManagerTests: XCTestCase {
    
    let clientId = Data(repeating: 1, count: 20)
    let infoHash = Data(repeating: 2, count: 20)
    let bitFieldSize = 10
    
    var delegate: TorrentPeerManagerDelegateStub!
    var sut: TorrentPeerManager!
    
    var peers: [TorrentPeerFake] {
        return sut.peers as! [TorrentPeerFake]
    }
    
    override func setUp() {
        super.setUp()
        
        sut = TorrentPeerManager(clientId: clientId, infoHash: infoHash, bitFieldSize: bitFieldSize)
        sut.peerFactory = createFakePeer(peerInfo: infoHash: bitFieldSize: )
        
        delegate = TorrentPeerManagerDelegateStub()
        sut.delegate = delegate
    }
    
    func createFakePeer(peerInfo: TorrentPeerInfo, infoHash: Data, bitFieldSize: Int) -> TorrentPeer {
        let communicator = TorrentPeerCommunicatorStub(peerInfo: peerInfo, infoHash: infoHash)
        return TorrentPeerFake(peerInfo: peerInfo, bitFieldSize: bitFieldSize, communicator: communicator)
    }
    
    func test_addingPeerInfoCreatesPeers() {
        
        // Given
        let peerInfo = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        
        // When
        sut.addPeers(withInfo: [peerInfo])
        
        // Then
        XCTAssertEqual(sut.peers.count, 1)
        XCTAssertEqual(sut.peers.first!.peerInfo, peerInfo)
    }
    
    func test_newPeersConnect() {
        
        // Given
        let peerInfo1 = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        let peerInfo2 = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        
        var bitField = BitField(size: bitFieldSize)
        bitField.set(at: 3)
        delegate.torrentPeerManagerCurrentBitfieldForHandshakeResult = bitField
        
        // When
        sut.addPeers(withInfo: [peerInfo1, peerInfo2])
        
        // Then
        peers.forEach { peer in
            XCTAssert(peer.connectCalled)
            if let connectHandshakeData = peer.connectHandshakeData {
                XCTAssertEqual(connectHandshakeData.clientId, clientId)
                XCTAssertEqual(connectHandshakeData.bitField, bitField)
            }
        }
    }
    
    func test_doesNotConnectToMoreThanMax() {
        
        // Given
        sut.maximumNumberOfConnectedPeers = 2

        let peerInfo1 = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        let peerInfo2 = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        let peerInfo3 = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        sut.addPeers(withInfo: [peerInfo1])
        
        // When
        sut.addPeers(withInfo: [peerInfo2, peerInfo3])
        
        // Then
        XCTAssertTrue(peers[1].connectCalled)
        XCTAssertFalse(peers[2].connectCalled)
    }
    
    func test_peerRemovedIfLost() {
        
        // Given
        let peerInfo = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        sut.addPeers(withInfo: [peerInfo])
        
        // When
        sut.peerLost(peers.first!)
        
        // Then
        XCTAssertEqual(peers.count, 0)
    }
    
    func test_whenOnePeerDisconnectsAnotherPeerConnects() {
        
        // Given
        sut.maximumNumberOfConnectedPeers = 2
        
        let peerInfo1 = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        let peerInfo2 = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        let peerInfo3 = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        sut.addPeers(withInfo: [peerInfo1, peerInfo2, peerInfo3])
        
        let peer = peers[2]
        XCTAssertFalse(peer.connectCalled)
        
        // When
        sut.peerLost(peers.first!)
        
        // Then
        XCTAssertTrue(peer.connectCalled)
    }
    
    func test_peerToldToDownloadPieceAfterHandshake() {
        
        // Given
        let peerInfo = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        sut.addPeers(withInfo: [peerInfo])
        guard let peer = peers.first else { return }
        
        let pieceIndex = 123
        let size = 456
        delegate.torrentPeerManagerNextPieceToDownloadResult = (pieceIndex: pieceIndex, size: size)
        
        // When
        sut.peerCompletedHandshake(peer)
        
        // Then
        XCTAssert(peer.downloadPieceCalled)
        if let downloadPieceParameters = peer.downloadPieceParameters {
            XCTAssertEqual(downloadPieceParameters.index, pieceIndex)
            XCTAssertEqual(downloadPieceParameters.size, size)
        }
    }
    
    func test_delegateNotifiedOnGotPiece() {
        
        // Given
        let peerInfo = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        sut.addPeers(withInfo: [peerInfo])
        guard let peer = peers.first else { return }
        
        let pieceIndex = 123
        let data = Data(bytes: [7, 8, 9])
        
        // When
        sut.peer(peer, gotPieceAtIndex: pieceIndex, piece: data)
        
        // Then
        XCTAssert(delegate.downloadedPieceAtIndexCalled)
        if let downloadedPieceAtIndexParameters = delegate.downloadedPieceAtIndexParameters {
            XCTAssert(downloadedPieceAtIndexParameters.sender === sut)
            XCTAssertEqual(downloadedPieceAtIndexParameters.piece, data)
            XCTAssertEqual(downloadedPieceAtIndexParameters.pieceIndex, pieceIndex)
        }
    }
    
    func test_peerToldToDownloadNextPieceOnGotPiece() {
        
        // Given
        let peerInfo = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        sut.addPeers(withInfo: [peerInfo])
        guard let peer = peers.first else { return }
        
        let pieceIndex = 123        
        let size = 456
        delegate.torrentPeerManagerNextPieceToDownloadResult = (pieceIndex: pieceIndex, size: size)
        
        // When
        sut.peer(peer, gotPieceAtIndex: 0, piece: Data())
        
        // Then
        XCTAssert(peer.downloadPieceCalled)
        if let downloadPieceParameters = peer.downloadPieceParameters {
            XCTAssertEqual(downloadPieceParameters.index, pieceIndex)
            XCTAssertEqual(downloadPieceParameters.size, size)
        }
    }
    
    func test_delegateToldOnFailedToDownloadPiece() {
        
        // Given
        let peerInfo = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        sut.addPeers(withInfo: [peerInfo])
        guard let peer = peers.first else { return }
        
        let pieceIndex = 123
        
        // When
        sut.peer(peer, failedToGetPieceAtIndex: pieceIndex)
        
        // Then
        XCTAssert(delegate.failedToGetPieceAtIndexCalled)
        if let failedToGetPieceAtIndexParameters = delegate.failedToGetPieceAtIndexParameters {
            XCTAssert(failedToGetPieceAtIndexParameters.sender === sut)
            XCTAssertEqual(failedToGetPieceAtIndexParameters.index, pieceIndex)
        }
    }
}
