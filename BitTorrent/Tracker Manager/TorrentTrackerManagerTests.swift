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
    port: UInt16,
    event: TorrentTrackerEvent,
    infoHash: Data,
    numberOfBytesRemaining: Int,
    numberOfBytesUploaded: Int,
    numberOfBytesDownloaded: Int,
    numberOfPeersToFetch: Int)?
    
    var onAnnounceClient: (()->Void)?
    func announceClient(with peerId: String,
                        port: UInt16,
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
        onAnnounceClient?()
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
    let listeningPort: UInt16 = 123
    
    
    let announceInfo = TorrentTrackerManagerAnnonuceInfo(numberOfBytesRemaining: 1,
                                                         numberOfBytesUploaded: 2,
                                                         numberOfBytesDownloaded: 3,
                                                         numberOfPeersToFetch: 4)
    
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
        
        let httpsScheme = metaInfo.announceList![0][0].bySettingScheme(to: "https")
        XCTAssertEqual(httpTracker.announceURL, httpsScheme)
        XCTAssertEqual(udpTracker.announceURL, metaInfo.announceList![0][1])
        
        XCTAssert(httpTracker.delegate === sut)
        XCTAssert(udpTracker.delegate === sut)
    }
    
    func test_startWillAnnounceToTrackers() {
        
        // Given
        let tracker = TorrentTrackerStub()
        let delegate = TorrentTrackerManagerDelegateStub()
        
        let sut = TorrentTrackerManager(metaInfo: metaInfo,
                                        clientId: clientIdData,
                                        port: listeningPort,
                                        trackers: [tracker])
        
        delegate.torrentTrackerManagerAnnonuceInfoResult = announceInfo
        sut.delegate = delegate
        
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
    
    func test_announceRepeats() {
        
        // Given
        let tracker = TorrentTrackerStub()
        let delegate = TorrentTrackerManagerDelegateStub()
        
        let sut = TorrentTrackerManager(metaInfo: metaInfo,
                                        clientId: clientIdData,
                                        port: listeningPort,
                                        trackers: [tracker])
        
        sut.delegate = delegate
        sut.announceTimeInterval = 0
        
        // When
        sut.start()
        
        // Then
        let expectation = self.expectation(description: "Announce is repeatedly called")
        tracker.onAnnounceClient = {
            tracker.onAnnounceClient = nil
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }
    
    func test_canForceReAnnounce_resetsAnnounceTimer() {
        
        // Given
        let tracker = TorrentTrackerStub()
        let delegate = TorrentTrackerManagerDelegateStub()
        let sut = TorrentTrackerManager(metaInfo: metaInfo,
                                        clientId: clientIdData,
                                        port: listeningPort,
                                        trackers: [tracker])
        
        sut.delegate = delegate
        sut.announceTimeInterval = 600
        sut.start()
        
        // Then
        let expectation = self.expectation(description: "Announce is repeatedly called")
        tracker.onAnnounceClient = {
            tracker.onAnnounceClient = nil
            expectation.fulfill()
        }
        
        // When
        sut.forceRestart()
        waitForExpectations(timeout: 0.1)
    }
}
