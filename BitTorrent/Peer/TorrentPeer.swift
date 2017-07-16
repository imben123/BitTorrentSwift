//
//  TorrentPeer.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

protocol TorrentPeerDelegate: class {
    func peerCompletedHandshake(_ sender: TorrentPeer)
    func peerLost(_ sender: TorrentPeer)
    func peer(_ sender: TorrentPeer, gotPieceAtIndex index: Int, piece: Data)
    func peer(_ sender: TorrentPeer, failedToGetPieceAtIndex index: Int)
}

class TorrentPeer {
    
    var enableLogging = false {
        didSet {
            communicator.enableLogging = enableLogging
        }
    }
    
    static let maximumNumberOfPendingBlockRequests = 20
    
    weak var delegate: TorrentPeerDelegate?
    
    let peerInfo: TorrentPeerInfo
    private let communicator: TorrentPeerCommunicator
    
    // Peer state
    var peerChoked: Bool { return _peerChoked }
    var peerInterested: Bool { return _peerInterested }
    var amChokedToPeer: Bool { return _amChokedToPeer }
    var amInterestedInPeer: Bool { return _amInterestedInPeer }
    var currentProgress: BitField { return _currentProgress }
    
    // Private state
    private var _peerChoked: Bool = true
    private var _peerInterested: Bool = false
    private var _amChokedToPeer: Bool = true
    private var _amInterestedInPeer: Bool = false
    private var _currentProgress: BitField
    
    private var downloadPieceRequests: [Int: TorrentPieceDownloadBuffer] = [:]
    private var numberOfPendingRequests = 0
    
    init(peerInfo: TorrentPeerInfo, bitFieldSize: Int, communicator: TorrentPeerCommunicator) {
        self.peerInfo = peerInfo
        self.communicator = communicator
        self._currentProgress = BitField(size: bitFieldSize)
        communicator.delegate = self
    }
    
    convenience init(peerInfo: TorrentPeerInfo, infoHash: Data, bitFieldSize: Int) {
        let communicator = TorrentPeerCommunicator(peerInfo: peerInfo, infoHash: infoHash)
        self.init(peerInfo: peerInfo, bitFieldSize: bitFieldSize, communicator: communicator)
    }
    
    private var handshakeData: (clientId: Data, bitField: BitField)?
    
    func connect(withHandshakeData handshakeData:(clientId: Data, bitField: BitField)) throws {
        self.handshakeData = handshakeData
        try communicator.connect()
    }
    
    func downloadPiece(atIndex index: Int, size: Int) {
        
        let downloadBuffer = TorrentPieceDownloadBuffer(index: index, size: size)
        downloadPieceRequests[index] = downloadBuffer
        
        if !amInterestedInPeer {
            _amInterestedInPeer = true
            communicator.sendInterested()
        }
        
        if !peerChoked {
            requestNextBlock()
        }
    }
    
    private func requestNextBlock() {
        if numberOfPendingRequests < TorrentPeer.maximumNumberOfPendingBlockRequests {
            
            guard let pieceRequest = downloadPieceRequests.values.first else { return }
            guard let blockRequest = pieceRequest.nextDownloadBlock() else { return }
            
            numberOfPendingRequests += 1
            
            communicator.sendRequest(fromPieceAtIndex: blockRequest.piece,
                                     begin: blockRequest.begin,
                                     length: blockRequest.length)
            requestNextBlock()
        }
    }
    
    private func killAllDownloads() {
        for downloadPieceRequest in downloadPieceRequests {
            delegate?.peer(self, failedToGetPieceAtIndex: downloadPieceRequest.value.index)
        }
        downloadPieceRequests.removeAll()
    }
}

extension TorrentPeer: TorrentPeerCommunicatorDelegate {
    
    func peerConnected(_ sender: TorrentPeerCommunicator) {
        
        if enableLogging { print("Peer socket connected (\(peerInfo.ip):\(peerInfo.port)") }
        
        guard let (clientId, bitField) = handshakeData else { return }
        
        communicator.sendHandshake(for: clientId) { [weak self] in
            self?.communicator.sendBitField(bitField)
        }
    }
    
    func peerLost(_ sender: TorrentPeerCommunicator) {
        killAllDownloads()
        delegate?.peerLost(self)
    }
    
    func peerSentHandshake(_ sender: TorrentPeerCommunicator, sentHandshakeWithPeerId peerId: Data, onDHT: Bool) {
        delegate?.peerCompletedHandshake(self)
    }
    
    func peerSentKeepAlive(_ sender: TorrentPeerCommunicator) {
        
    }
    
    func peerBecameChoked(_ sender: TorrentPeerCommunicator) {
        _peerChoked = true
        killAllDownloads()
    }
    
    func peerBecameUnchoked(_ sender: TorrentPeerCommunicator) {
        _peerChoked = false
        requestNextBlock()
    }
    
    func peerBecameInterested(_ sender: TorrentPeerCommunicator) {
        _peerInterested = true
    }
    
    func peerBecameUninterested(_ sender: TorrentPeerCommunicator) {
        _peerInterested = false
    }
    
    func peer(_ sender: TorrentPeerCommunicator, hasPiece piece: Int) {
        _currentProgress.set(at: piece)
    }
    
    func peer(_ sender: TorrentPeerCommunicator, hasBitField bitField: BitField) {
        _currentProgress = bitField
    }
    
    func peer(_ sender: TorrentPeerCommunicator, requestedPiece index: Int, begin: Int, length: Int) {
        
    }
    
    func peer(_ sender: TorrentPeerCommunicator, sentPiece index: Int, begin: Int, block: Data) {
        guard let downloadPieceBuffer = downloadPieceRequests[index] else { return }
        numberOfPendingRequests -= 1
        downloadPieceBuffer.gotBlock(block, begin: begin)
        if downloadPieceBuffer.isComplete, let piece = downloadPieceBuffer.piece {
            delegate?.peer(self, gotPieceAtIndex: index, piece: piece)
        }
        requestNextBlock()
    }
    
    func peer(_ sender: TorrentPeerCommunicator, cancelledRequestedPiece index: Int, begin: Int, length: Int) {
        
    }
    
    func peer(_ sender: TorrentPeerCommunicator, onDHTPort port: Int) {
        
    }
    
    func peerSentMalformedMessage(_ sender: TorrentPeerCommunicator) {
        
    }
}
