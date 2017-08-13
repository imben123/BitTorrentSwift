//
//  TorrentTrackerManagerTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 12/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentTrackerStub: TorrentTracker {
    
    weak var delegate: TorrentTrackerDelegate?
    
    var announceClientCalled = false
    var announceClientParameters: (peerId: String,
    port: Int,
    event: TorrentTrackerEvent,
    infoHash: Data,
    numberOfBytesRemaining: Int,
    numberOfBytesUploaded: Int,
    numberOfBytesDownloaded: Int,
    numberOfPeersToFetch: Int)?
    
    func announceClient(with peerId: String,
                        port: Int,
                        event: TorrentTrackerEvent,
                        infoHash: Data,
                        numberOfBytesRemaining: Int,
                        numberOfBytesUploaded: Int,
                        numberOfBytesDownloaded: Int,
                        numberOfPeersToFetch: Int) {
        announceClientCalled = true
        announceClientParameters = (peerId,
                                    port,
                                    event,
                                    infoHash,
                                    numberOfBytesRemaining,
                                    numberOfBytesUploaded,
                                    numberOfBytesDownloaded,
                                    numberOfPeersToFetch)
    }
}

class TorrentTrackerManagerDelegateStub: TorrentTrackerManagerDelegate {
    
    func torrentTrackerManager(_ sender: TorrentTrackerManager, gotNewPeers peers: [TorrentPeerInfo]) {
        
    }
    
    var torrentTrackerManagerAnnonuceInfoResult = TorrentTrackerManagerAnnonuceInfo(numberOfBytesRemaining: 0,
                                                                                    numberOfBytesUploaded: 0,
                                                                                    numberOfBytesDownloaded: 0,
                                                                                    numberOfPeersToFetch: 0)
    func torrentTrackerManagerAnnonuceInfo(_ sender: TorrentTrackerManager) -> TorrentTrackerManagerAnnonuceInfo {
        return torrentTrackerManagerAnnonuceInfoResult
    }
    
    
}

class TorrentTrackerManagerTests: XCTestCase {
    
    let metaInfo: TorrentMetaInfo = {
        let path = Bundle(for: TorrentProgressManagerTests.self).path(forResource: "TrackerManagerTests",
                                                                      ofType: "torrent")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        return TorrentMetaInfo(data: data)!
    }()
    
    let clientId = "-BD0000-bxa]N#IRKqv`"
    let clientIdData = "-BD0000-bxa]N#IRKqv`".data(using: .ascii)!
    let listeningPort = 123
    
    func test_createsTrackers() {
        
        let sut = TorrentTrackerManager(metaInfo: metaInfo, clientId: clientIdData, port: listeningPort)
        
        XCTAssertEqual(sut.trackers.count, 2)
        
        guard let httpTracker = sut.trackers.first as? TorrentHTTPTracker else {
            XCTFail("Didn't parse HTTP tracker")
            return
        }
        
        guard let udpTracker = sut.trackers.last as? TorrentUDPTracker else {
            XCTFail("Didn't parse UDP tracker")
            return
        }
        
        XCTAssertEqual(httpTracker.announceURL, metaInfo.announceList![0][0])
        XCTAssertEqual(udpTracker.announceURL, metaInfo.announceList![0][1])
        
        XCTAssert(httpTracker.delegate === sut)
        XCTAssert(udpTracker.delegate === sut)
    }
    
    func test_startWillAnnounceToTrackers() {
        
        // Given
        let tracker = TorrentTrackerStub()
        let delegate = TorrentTrackerManagerDelegateStub()
        let announceInfo = TorrentTrackerManagerAnnonuceInfo(numberOfBytesRemaining: 1,
                                                             numberOfBytesUploaded: 2,
                                                             numberOfBytesDownloaded: 3,
                                                             numberOfPeersToFetch: 4)
        
        let sut = TorrentTrackerManager(metaInfo: metaInfo,
                                        clientId: clientIdData,
                                        port: listeningPort,
                                        trackers: [tracker])
        sut.delegate = delegate
        
        delegate.torrentTrackerManagerAnnonuceInfoResult = announceInfo
        
        // When
        sut.start()
        
        // Then
        XCTAssert(tracker.announceClientCalled)
        
        guard let announceClientParameters = tracker.announceClientParameters else {
            XCTFail()
            return
        }
        XCTAssertEqual(announceClientParameters.peerId, clientId)
        XCTAssertEqual(announceClientParameters.port, listeningPort)
        XCTAssertEqual(announceClientParameters.event, .started)
        XCTAssertEqual(announceClientParameters.infoHash, metaInfo.infoHash)
        XCTAssertEqual(announceClientParameters.numberOfBytesRemaining, announceInfo.numberOfBytesRemaining)
        XCTAssertEqual(announceClientParameters.numberOfBytesUploaded, announceInfo.numberOfBytesUploaded)
        XCTAssertEqual(announceClientParameters.numberOfBytesDownloaded, announceInfo.numberOfBytesDownloaded)
        XCTAssertEqual(announceClientParameters.numberOfPeersToFetch, announceInfo.numberOfPeersToFetch)
    }
}
