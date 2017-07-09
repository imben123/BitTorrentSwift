//
//  TorrentPeerHandshakeMessageBuffer.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

enum TorrentPeerHandshakeMessageBufferError: Error {
    case protocolMismatch
    case infoHashMismatch
    case peerIdMismatch
}

protocol TorrentPeerHandshakeDelegate: class {
    func peerHandshakeMessageBuffer(_ sender: TorrentPeerHandshakeMessageBuffer,
                                    gotBadHandshake error: TorrentPeerHandshakeMessageBufferError)
    func peerHandshakeMessageBuffer(_ sender: TorrentPeerHandshakeMessageBuffer,
                                    gotHandshakeWithPeerId peerId: Data,
                                    remainingBuffer: Data,
                                    onDHT: Bool)
}

class TorrentPeerHandshakeMessageBuffer {
    
    weak var delegate: TorrentPeerHandshakeDelegate?
    
    let expectedInfoHash: Data
    let expectedPeerId: Data?
    private var buffer = Data()
    
    init(infoHash: Data, peerId: Data?) {
        self.expectedInfoHash = infoHash
        self.expectedPeerId = peerId
    }
    
    func appendData(_ data: Data) {
        
        buffer = buffer + data
        
        guard buffer.count > 0 else {
            return
        }
        
        let pstrLen = buffer[0]
        
        guard pstrLen == 19 else {
            delegate?.peerHandshakeMessageBuffer(self, gotBadHandshake: .protocolMismatch)
            return
        }
        
        guard buffer.count >= 20 else {
            return
        }
        
        let protocolStringBytes = Data(buffer[1..<20])
        let protocolString = String(data: protocolStringBytes, encoding: .ascii)
        guard protocolString == "BitTorrent protocol" else {
            delegate?.peerHandshakeMessageBuffer(self, gotBadHandshake: .protocolMismatch)
            return
        }
        
        guard buffer.count >= 48 else {
            return
        }
        
        let infoHash = Data(buffer[28..<48])
        
        guard infoHash == expectedInfoHash else {
            delegate?.peerHandshakeMessageBuffer(self, gotBadHandshake: .infoHashMismatch)
            return
        }
        
        guard buffer.count >= 68 else {
            return
        }
        
        let peerId = Data(buffer[48..<68])
        
        guard expectedPeerId == nil || peerId == expectedPeerId else {
            delegate?.peerHandshakeMessageBuffer(self, gotBadHandshake: .peerIdMismatch)
            return
        }
        
        let reservedBytes = buffer[20..<28]
        let onDHT = (reservedBytes[7] & UInt8(1)) == 1
        let remainingBytes = Data(buffer[68..<buffer.count])
        
        delegate?.peerHandshakeMessageBuffer(self,
                                             gotHandshakeWithPeerId: peerId,
                                             remainingBuffer: remainingBytes,
                                             onDHT: onDHT)
    }
}
