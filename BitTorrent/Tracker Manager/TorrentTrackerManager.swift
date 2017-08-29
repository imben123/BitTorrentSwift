//
//  TorrentTrackerManager.swift
//  BitTorrent
//
//  Created by Ben Davis on 12/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

struct TorrentTrackerManagerAnnonuceInfo {
    let numberOfBytesRemaining: Int
    let numberOfBytesUploaded: Int
    let numberOfBytesDownloaded: Int
    let numberOfPeersToFetch: Int
}

protocol TorrentTrackerManagerDelegate: class {
    func torrentTrackerManager(_ sender: TorrentTrackerManager, gotNewPeers peers: [TorrentPeerInfo])
    func torrentTrackerManagerAnnonuceInfo(_ sender: TorrentTrackerManager) -> TorrentTrackerManagerAnnonuceInfo
}

class TorrentTrackerManager {
    
    weak var delegate: TorrentTrackerManagerDelegate?
    
    let trackers: [TorrentTracker]
    
    let metaInfo: TorrentMetaInfo
    let clientId: String
    let port: UInt16
    
    var announceTimeInterval: TimeInterval = 600
    private lazy var announceTimer: Timer = {
        return Timer.scheduledTimer(timeInterval: self.announceTimeInterval,
                                    target: self,
                                    selector: #selector(announce),
                                    userInfo: nil,
                                    repeats: true)
    }()
    
    init(metaInfo: TorrentMetaInfo, clientId: Data, port: UInt16) {
        self.metaInfo = metaInfo
        self.clientId = String(data: clientId, encoding: .utf8)!
        self.port = port
        self.trackers = TorrentTrackerManager.createTrackers(from: metaInfo)
        
        for tracker in trackers {
            tracker.delegate = self
        }
    }
    
    // For testing
    init(metaInfo: TorrentMetaInfo, clientId: Data, port: UInt16, trackers: [TorrentTracker]) {
        self.metaInfo = metaInfo
        self.clientId = String(data: clientId, encoding: .utf8)!
        self.port = port
        self.trackers = trackers
    }
    
    private static func createTrackers(from metaInfo: TorrentMetaInfo) -> [TorrentTracker] {
        
        let announceList = metaInfo.announceList ?? [[metaInfo.announce]]
        let flatAnnounceList = announceList.flatMap { return $0 }
        
        var lastPortNumberUsed: UInt16 = 3475
        var result: [TorrentTracker] = []
        
        for url in flatAnnounceList {
            
            if url.scheme == "http" || url.scheme == "https" {
                
                let tracker = TorrentHTTPTracker(announceURL: url.bySettingScheme(to: "https"))
                result.append(tracker)
                
            } else if url.scheme == "udp" {
                
                let tracker = TorrentUDPTracker(announceURL: url, port: lastPortNumberUsed)
                result.append(tracker)
                
                // TODO: Support sharing the listening port for all udp trackers
                lastPortNumberUsed += 1
            }
        }
        return result
    }
    
    func start() {
        forceRestart()
    }
    
    func forceRestart() {
        announceTimer.fire()
    }
    
    @objc private func announce() {
        
        guard let delegate = delegate else { return }
        
        let announceInfo = delegate.torrentTrackerManagerAnnonuceInfo(self)
        
        for tracker in trackers {
            tracker.announceClient(with: clientId,
                                   port: port,
                                   event: .started,
                                   infoHash: metaInfo.infoHash,
                                   numberOfBytesRemaining: announceInfo.numberOfBytesRemaining,
                                   numberOfBytesUploaded: announceInfo.numberOfBytesUploaded,
                                   numberOfBytesDownloaded: announceInfo.numberOfBytesDownloaded,
                                   numberOfPeersToFetch: announceInfo.numberOfPeersToFetch)
        }
    }
}

extension TorrentTrackerManager: TorrentTrackerDelegate {
    
    func torrentTracker(_ sender: Any, receivedResponse response: TorrentTrackerResponse) {
        delegate?.torrentTrackerManager(self, gotNewPeers: response.peers)
    }
    
    func torrentTracker(_ sender: Any, receivedErrorMessage errorMessage: String) {
        print("Tracker error occurred: \(errorMessage)")
    }
    
}
