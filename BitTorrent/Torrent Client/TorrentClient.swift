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
    public var downloadSpeedTracker: NetworkSpeedTrackable { return peerManager.downloadSpeedTracker }

    let progressManager: TorrentProgressManager
    let peerManager: TorrentPeerManager
    let trackerManager: TorrentTrackerManager
    let torrentServer: TorrentServer
    
    let clientId = TorrentPeer.makePeerId()
    
    public init(metaInfo: TorrentMetaInfo, rootDirectory: String) {
        
        let downloadDirectory = rootDirectory + "/" + metaInfo.sensibleDownloadDirectoryName()
        try! TorrentFileManager.prepareRootDirectory(downloadDirectory, forTorrentMetaInfo: metaInfo)

        self.metaInfo = metaInfo
        self.torrentServer = TorrentServer(infoHash: metaInfo.infoHash, clientId: clientId)
        self.progressManager = TorrentProgressManager(metaInfo: metaInfo, rootDirectory: rootDirectory)        
        self.peerManager = TorrentPeerManager(clientId: clientId,
                                              infoHash: metaInfo.infoHash,
                                              bitFieldSize: metaInfo.info.pieces.count)
        
        trackerManager = TorrentTrackerManager(metaInfo: metaInfo, clientId: clientId, port: torrentServer.port)
        
        trackerManager.delegate = self
        peerManager.delegate = self
        torrentServer.delegate = self
    }
    
    // For testing
    init(metaInfo: TorrentMetaInfo,
         torrentServer: TorrentServer,
         progressManager: TorrentProgressManager,
         peerManager: TorrentPeerManager,
         trackerManager: TorrentTrackerManager) {
        
        self.metaInfo = metaInfo
        self.torrentServer = torrentServer
        self.progressManager = progressManager
        self.peerManager = peerManager
        self.trackerManager = trackerManager
        
        trackerManager.delegate = self
        peerManager.delegate = self
        torrentServer.delegate = self
    }
    
    public func forceReCheck() {
        progressManager.forceReCheck()
    }
    
    public func start() {
        torrentServer.startListening()
        trackerManager.start()
        status = .started
        if progressManager.progress.complete { status = .completed }
    }
}

extension TorrentClient: TorrentTrackerManagerDelegate {
    
    func torrentTrackerManager(_ sender: TorrentTrackerManager, gotNewPeers peers: [TorrentPeerInfo]) {
        if !progress.complete {
            peerManager.addPeers(withInfo: peers)
        }
    }
    
    func torrentTrackerManagerAnnonuceInfo(_ sender: TorrentTrackerManager) -> TorrentTrackerManagerAnnonuceInfo {
        
        return TorrentTrackerManagerAnnonuceInfo(
            numberOfBytesRemaining: progress.remaining * metaInfo.info.pieceLength,
            numberOfBytesUploaded: 0,
            numberOfBytesDownloaded: progress.downloaded * metaInfo.info.pieceLength,
            numberOfPeersToFetch: 50)
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
    
    func torrentPeerManagerNeedsMorePeers(_ sender: TorrentPeerManager) {
        trackerManager.forceRestart()
    }
    
    func torrentPeerManagerCurrentBitfieldForHandshake(_ sender: TorrentPeerManager) -> BitField {
        return progressManager.progress.bitField
    }
    
    func torrentPeerManager(_ sender: TorrentPeerManager,
                            nextPieceFromAvailable availablePieces: BitField) -> TorrentPieceRequest? {
        return progressManager.getNextPieceToDownload(from: availablePieces)
    }
    
    func torrentPeerManager(_ sender: TorrentPeerManager, peerRequiresPieceAtIndex index: Int) -> Data? {
        return progressManager.fileManager.getPiece(at: index)
    }
}

extension TorrentClient: TorrentServerDelegate {
    func torrentServer(_ torrentServer: TorrentServer, connectedToPeer peer: TorrentPeer) {
        peerManager.addPeer(peer)
    }
    
    func currentProgress(for torrentServer: TorrentServer) -> BitField {
        return progress.bitField
    }
}
