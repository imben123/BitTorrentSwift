//
//  TorrentPeerManager.swift
//  BitTorrent
//
//  Created by Ben Davis on 12/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

protocol TorrentPeerManagerDelegate: class {
    
    func torrentPeerManager(_ sender: TorrentPeerManager,
                            downloadedPieceAtIndex pieceIndex: Int,
                            piece: Data)
    
    func torrentPeerManager(_ sender: TorrentPeerManager, failedToGetPieceAtIndex index: Int)
    
    func torrentPeerManagerCurrentBitfieldForHandshake(_ sender: TorrentPeerManager) -> BitField
    
    // TODO: add checksum to the request
    func torrentPeerManagerNextPieceToDownload(_ sender: TorrentPeerManager) -> (pieceIndex: Int, size: Int)?
}

class TorrentPeerManager {
    
    var enableLogging = false {
        didSet {
            
        }
    }
    
    var maximumNumberOfConnectedPeers = 20
    
    weak var delegate: TorrentPeerManagerDelegate?
    
    let clientId: Data
    let infoHash: Data
    let bitFieldSize: Int
    
    private(set) var peers: [TorrentPeer] = []
    private var numberOfConnectedPeers: Int {
        return peers.filter({ $0.connected }).count
    }
    
    init(clientId: Data, infoHash: Data, bitFieldSize: Int) {
        self.clientId = clientId
        self.infoHash = infoHash
        self.bitFieldSize = bitFieldSize
    }
    
    // Exposed for testing
    var peerFactory = TorrentPeer.init(peerInfo: infoHash: bitFieldSize:)
    
    func addPeers(withInfo peerInfos: [TorrentPeerInfo]) {
        let newPeers = peerInfos.map { peerFactory($0, infoHash, bitFieldSize) }
        peers.append(contentsOf: newPeers)
        connectToPeersIfNeeded(peers: newPeers)
    }
    
    fileprivate func connectToPeersIfNeeded(peers: [TorrentPeer]) {
        
        guard let delegate = delegate else { return }
        
        let max = maximumNumberOfConnectedPeers - numberOfConnectedPeers
        let numberToConnectTo = min(max, peers.count)
        
        let bitField = delegate.torrentPeerManagerCurrentBitfieldForHandshake(self)
        let peersToConnectTo = peers[0 ..< numberToConnectTo]
        connectToPeers(peersToConnectTo, bitField: bitField)
    }
    
    private func connectToPeers<T: Sequence>(_ peers: T, bitField: BitField) where T.Element == TorrentPeer {
        for peer in peers {
            do {
                try peer.connect(withHandshakeData: (clientId: clientId, bitField: bitField))
            } catch let error {
                print("Unable to create new TCP socket. Error: \(error)")
            }
        }
    }
}

extension TorrentPeerManager: TorrentPeerDelegate {
    
    private var disconnectedPeers: [TorrentPeer] {
        return peers.filter { !$0.connected }
    }
    
    func peerCompletedHandshake(_ sender: TorrentPeer) {
        // TODO: Do this when peer becomes interested so we aren't waiting on choked peers
        if let pieceRequest = delegate?.torrentPeerManagerNextPieceToDownload(self) {
            sender.downloadPiece(atIndex: pieceRequest.pieceIndex, size: pieceRequest.size)
        }
    }
    
    func peerLost(_ sender: TorrentPeer) {
        guard let index = peers.index(where: { $0 === sender }) else { return }
        peers.remove(at: index)
        connectToPeersIfNeeded(peers: disconnectedPeers)
    }
    
    func peer(_ sender: TorrentPeer, gotPieceAtIndex index: Int, piece: Data) {
        delegate?.torrentPeerManager(self, downloadedPieceAtIndex: index, piece: piece)
        if let pieceRequest = delegate?.torrentPeerManagerNextPieceToDownload(self) {
            sender.downloadPiece(atIndex: pieceRequest.pieceIndex, size: pieceRequest.size)
        }
    }
    
    func peer(_ sender: TorrentPeer, failedToGetPieceAtIndex index: Int) {
        delegate?.torrentPeerManager(self, failedToGetPieceAtIndex: index)
    }
}
