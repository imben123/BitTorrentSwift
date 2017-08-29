//
//  TorrentClientTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 13/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentClientTests: XCTestCase {
    
    let pathRoot = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                       .userDomainMask, true)[0] as String
    let metaInfo: TorrentMetaInfo = {
        let path = Bundle(for: TorrentProgressManagerTests.self).path(forResource: "TestText",
                                                                      ofType: "torrent")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        return TorrentMetaInfo(data: data)!
    }()
    
    let finalData: Data = {
        let path = Bundle(for: TorrentProgressManagerTests.self).path(forResource: "text", ofType: "txt")
        return try! Data(contentsOf: URL(fileURLWithPath: path!))
    }()
    
    var torrentServer: TorrentServerStub!
    var progressManager: TorrentProgressManagerStub!
    var peerManager: TorrentPeerManagerStub!
    var trackerManager: TorrentTrackerManagerStub!
    var sut: TorrentClient!
    
    override func setUp() {
        super.setUp()
        try! TorrentFileManager.prepareRootDirectory(pathRoot + "/text/", forTorrentMetaInfo: metaInfo)
        
        torrentServer = TorrentServerStub(metaInfo: metaInfo)
        progressManager = TorrentProgressManagerStub(metaInfo: metaInfo)
        peerManager = TorrentPeerManagerStub(metaInfo: metaInfo)
        trackerManager = TorrentTrackerManagerStub(metaInfo: metaInfo)
        
        sut = TorrentClient(metaInfo: metaInfo,
                            torrentServer: torrentServer,
                            progressManager: progressManager,
                            peerManager: peerManager,
                            trackerManager: trackerManager)
    }
    
    func test_dependanciesCreated() {
        let sut = TorrentClient(metaInfo: metaInfo, rootDirectory: pathRoot)
        
        XCTAssertEqual(sut.metaInfo.infoHash, metaInfo.infoHash)
        XCTAssert(sut.torrentServer.delegate === sut)
        XCTAssert(sut.trackerManager.delegate === sut)
        XCTAssert(sut.peerManager.delegate === sut)
    }
    
    func test_torrentServerStartsListeningOnTorrentStart() {
        sut.start()
        XCTAssert(torrentServer.startListeningCalled)
    }
    
    func test_trackerAnnounceOnTorrentStart() {
        sut.start()
        XCTAssert(trackerManager.startCalled)
    }
    
    func test_status() {
        
        XCTAssertEqual(sut.status, .stopped)
        
        sut.start()
        XCTAssertEqual(sut.status, .started)
        
        progressManager.testProgress.setCurrentlyDownloading(piece: 0)
        progressManager.testProgress.finishedDownloading(piece: 0)
        sut.torrentPeerManager(peerManager, downloadedPieceAtIndex: 0, piece: finalData)
        XCTAssertEqual(sut.status, .completed)
    }
    
    func test_newPeersFromTrackerAreGivenToPeersManager() {
        
        // Given
        let peers = [TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)]
        
        // When
        sut.torrentTrackerManager(trackerManager, gotNewPeers: peers)
        
        // Then
        XCTAssert(peerManager.addPeersCalled)
        if let addPeersParameter = peerManager.addPeersParameter {
            XCTAssertEqual(addPeersParameter, peers)
        }
    }
    
    func test_announceInfoComesFromProgress() {
        
        // Given
        let pieceLength = metaInfo.info.pieceLength
        
        var progress = TorrentProgress(size: 5)
        
        progress.setCurrentlyDownloading(piece: 0)
        progress.finishedDownloading(piece: 0)
        
        progress.setCurrentlyDownloading(piece: 1)
        progress.finishedDownloading(piece: 1)
        
        progressManager.testProgress = progress
        
        // When
        let result = sut.torrentTrackerManagerAnnonuceInfo(trackerManager)
        
        // Then
        XCTAssertEqual(result.numberOfBytesDownloaded, pieceLength*2)
        XCTAssertEqual(result.numberOfBytesRemaining, pieceLength*3)
        XCTAssertEqual(result.numberOfBytesUploaded, 0)
    }
    
    func test_bitFieldForHandshakeComesFromProgress() {
        
        // Given
        var progress = TorrentProgress(size: 5)
        
        progress.setCurrentlyDownloading(piece: 0)
        progress.finishedDownloading(piece: 0)
        
        progress.setCurrentlyDownloading(piece: 1)
        progress.finishedDownloading(piece: 1)
        
        progressManager.testProgress = progress
        
        // When
        let result = sut.torrentPeerManagerCurrentBitfieldForHandshake(peerManager)
        
        // Then
        XCTAssertEqual(result, progress.bitField)
    }
    
    func test_progressNotifiedOnDownloadedPiece() {
        
        sut.torrentPeerManager(peerManager, downloadedPieceAtIndex: 123, piece: finalData)
        
        XCTAssert(progressManager.setDownloadedPieceCalled)
        if let setDownloadedPieceParameters = progressManager.setDownloadedPieceParameters {
            XCTAssertEqualData(setDownloadedPieceParameters.piece, finalData)
            XCTAssertEqual(setDownloadedPieceParameters.pieceIndex, 123)
        }
    }
    
    func test_progressNotifiedOnLostPiece() {
        
        sut.torrentPeerManager(peerManager, failedToGetPieceAtIndex: 123)
        
        XCTAssert(progressManager.setLostPieceCalled)
        XCTAssertEqual(progressManager.setLostPieceIndex, 123)
    }
    
    func test_nextPieceAvailableComesFromProgress() {
        
        var bitField = BitField(size: 5)
        bitField.set(at: 3)
        
        let expected = TorrentPieceRequest(pieceIndex: 1, size: 2, checksum: Data(bytes: [2]))
        progressManager.getNextPieceToDownloadResult = expected
        
        guard let result = sut.torrentPeerManager(peerManager, nextPieceFromAvailable: bitField) else {
            XCTFail()
            return
        }
        
        XCTAssert(progressManager.getNextPieceToDownloadCalled)
        XCTAssertEqual(progressManager.getNextPieceToDownloadParameter!, bitField)
        XCTAssertEqual(result.pieceIndex, expected.pieceIndex)
        XCTAssertEqual(result.size, expected.size)
        XCTAssertEqualData(result.checksum, expected.checksum)
    }
    
    func test_pieceForUploadComesFromFileManager() {
        
        progressManager.fileHandle.seek(toFileOffset: 0)
        progressManager.fileHandle.write(finalData)
        let result = sut.torrentPeerManager(peerManager, peerRequiresPieceAtIndex: 0)
        XCTAssertEqualData(result, finalData)
    }
    
    func test_peersConnectingFromServerAreAddedToPeerManager() {
        
        // Given
        let peer = createFakePeer()
        
        // When
        sut.torrentServer(torrentServer, connectedToPeer: peer)
        
        // Then
        XCTAssert(peerManager.addPeerCalled)
        if let addPeerParameter = peerManager.addPeerParameter {
            XCTAssert(addPeerParameter === peer)
        }
    }
    
    func createFakePeer() -> TorrentPeer {
        let peerInfo = TorrentPeerInfo(ip: "127.0.0.1", port: 123, peerId: nil)
        let communicator = TorrentPeerCommunicatorStub(peerInfo: peerInfo, infoHash: metaInfo.infoHash)
        return TorrentPeerFake(peerInfo: peerInfo,
                               bitFieldSize: metaInfo.info.pieces.count,
                               communicator: communicator)
    }
    
    func test_currentProgressForTorrentServer() {
        
        // Given
        var progress = TorrentProgress(size: 5)
        
        progress.setCurrentlyDownloading(piece: 0)
        progress.finishedDownloading(piece: 0)
        
        progress.setCurrentlyDownloading(piece: 1)
        progress.finishedDownloading(piece: 1)
        
        progressManager.testProgress = progress
        
        // When
        let result = sut.currentProgress(for: torrentServer)
        
        // Then
        XCTAssertEqual(result, progress.bitField)
    }
}
