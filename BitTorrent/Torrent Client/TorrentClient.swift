//
//  TorrentClient.swift
//  BitTorrent
//
//  Created by Ben Davis on 16/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

public class TorrentClient {
    
    public enum Status: Equatable {
        case stopped, started, completed
        
        public var toString: String {
            switch self {
            case .stopped:
                return "Stopped"
            case .started:
                return "Started"
            case .completed:
                return "Completed"
            }
        }
        
        public static func ==(_ lhs: Status, rhs: Status) -> Bool {
            return lhs.toString == rhs.toString
        }
    }
    
    public let metaInfo: TorrentMetaInfo
    
    public private(set) var status: Status = .stopped
    public var progress: TorrentProgress { return progressManager.progress }
    public var numberOfConnectedPeers: Int { return peerManager.numberOfConnectedPeers }
    public var numberOfConnectedSeeds: Int { return peerManager.numberOfConnectedPeers }
    public var downloadSpeedTracker: NetworkSpeedTracker { return peerManager.downloadSpeedTracker }

    let progressManager: TorrentProgressManager
    let peerManager: TorrentPeerManager
    let trackerManager: TorrentTrackerManager
    
    let clientId = TorrentPeer.makePeerId()
    
    public init(metaInfo: TorrentMetaInfo, rootDirectory: String) {
        self.metaInfo = metaInfo
        self.progressManager = TorrentProgressManager(metaInfo: metaInfo, rootDirectory: rootDirectory)        
        self.peerManager = TorrentPeerManager(clientId: clientId,
                                              infoHash: metaInfo.infoHash,
                                              bitFieldSize: metaInfo.info.pieces.count)
        
        // TODO: listen on this port
        trackerManager = TorrentTrackerManager(metaInfo: metaInfo, clientId: clientId, port: 123)
        
        trackerManager.delegate = self
        peerManager.delegate = self
        peerManager.enableLogging = true
    }
    
    // For testing
    init(metaInfo: TorrentMetaInfo,
         progressManager: TorrentProgressManager,
         peerManager: TorrentPeerManager,
         trackerManager: TorrentTrackerManager) {
        self.metaInfo = metaInfo
        self.progressManager = progressManager
        self.peerManager = peerManager
        self.trackerManager = trackerManager
    }
    
    public func start() {
        trackerManager.start()
        status = .started
    }
}

extension TorrentClient: TorrentTrackerManagerDelegate {
    
    func torrentTrackerManager(_ sender: TorrentTrackerManager, gotNewPeers peers: [TorrentPeerInfo]) {
        peerManager.addPeers(withInfo: peers)
    }
    
    func torrentTrackerManagerAnnonuceInfo(_ sender: TorrentTrackerManager) -> TorrentTrackerManagerAnnonuceInfo {
        
        return TorrentTrackerManagerAnnonuceInfo(
            numberOfBytesRemaining: progress.remaining * metaInfo.info.pieceLength,
            numberOfBytesUploaded: progress.uploaded * metaInfo.info.pieceLength,
            numberOfBytesDownloaded: progress.downloaded * metaInfo.info.pieceLength,
            numberOfPeersToFetch: 20)
    }
}

extension TorrentClient: TorrentPeerManagerDelegate {
    
    func torrentPeerManager(_ sender: TorrentPeerManager, downloadedPieceAtIndex pieceIndex: Int, piece: Data) {
        progressManager.setDownloadedPiece(piece, pieceIndex: pieceIndex)
        if progressManager.progress.complete {
            print("Torrent complete!")
            status = .completed
        }
    }
    
    func torrentPeerManager(_ sender: TorrentPeerManager, failedToGetPieceAtIndex index: Int) {
        progressManager.setLostPiece(at: index)
    }
    
    func torrentPeerManagerCurrentBitfieldForHandshake(_ sender: TorrentPeerManager) -> BitField {
        return progressManager.progress.bitField
    }
    
    func torrentPeerManager(_ sender: TorrentPeerManager,
                            nextPieceFromAvailable availablePieces: BitField) -> TorrentPieceRequest? {
        return progressManager.getNextPieceToDownload(from: availablePieces)
    }
}

