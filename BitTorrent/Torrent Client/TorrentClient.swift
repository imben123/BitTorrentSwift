//
//  TorrentClient.swift
//  BitTorrent
//
//  Created by Ben Davis on 16/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

public class TorrentClient {
    
    let metaInfo: TorrentMetaInfo
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
    
    public func start() {
        trackerManager.start()
    }
}

extension TorrentClient: TorrentTrackerManagerDelegate {
    
    func torrentTrackerManager(_ sender: TorrentTrackerManager, gotNewPeers peers: [TorrentPeerInfo]) {
        let filteredPeers = peers.filter { (peer) -> Bool in
            return peer.port == 15383
        }
        peerManager.addPeers(withInfo: filteredPeers)
    }
    
    func torrentTrackerManagerAnnonuceInfo(_ sender: TorrentTrackerManager) -> TorrentTrackerManagerAnnonuceInfo {
        
        // Fix this
        return TorrentTrackerManagerAnnonuceInfo(numberOfBytesRemaining: progressManager.progress.bitField.size,
                                                 numberOfBytesUploaded: 0,
                                                 numberOfBytesDownloaded: 0,
                                                 numberOfPeersToFetch: 20)
    }
}

extension TorrentClient: TorrentPeerManagerDelegate {
    
    func torrentPeerManager(_ sender: TorrentPeerManager, downloadedPieceAtIndex pieceIndex: Int, piece: Data) {
        progressManager.setDownloadedPiece(piece, pieceIndex: pieceIndex)
        if progressManager.progress.complete {
            print("Torrent complete!")
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

