//
//  TorrentPeerMessageBuffer.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

protocol TorrentPeerMessageBufferDelegate: class {
    func peerMessageBuffer(_ sender: TorrentPeerMessageBuffer, gotMessage data: Data)
}

class TorrentPeerMessageBuffer {
    
    weak var delegate: TorrentPeerMessageBufferDelegate?
    
    private var buffer = Data()
    
    func appendData(_ data: Data) {
        buffer = buffer + data
                
        testIfBufferContainsCompletedMessage()
    }
    
    func testIfBufferContainsCompletedMessage() {
        guard buffer.count >= 4 else {
            return
        }
        
        let lengthPrefix = buffer.correctingIndicies[0..<4]
        let expectedLength = Int(UInt32(data: lengthPrefix)) + 4
        
        if buffer.count >= expectedLength {
            let message = buffer.correctingIndicies[0..<expectedLength]
            delegate?.peerMessageBuffer(self, gotMessage: message)
            buffer = buffer.correctingIndicies[expectedLength..<buffer.count]
            testIfBufferContainsCompletedMessage()
        }
    }
}
