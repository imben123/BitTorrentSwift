//
//  PieceDownloadBuffer.swift
//  BitTorrent
//
//  Created by Ben Davis on 16/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

struct TorrentBlockRequest: Equatable {
    var piece: Int
    var begin: Int
    var length: Int
    
    static func ==(_ lhs: TorrentBlockRequest, _ rhs: TorrentBlockRequest) -> Bool {
        return (lhs.piece == rhs.piece && lhs.begin == rhs.begin && lhs.length == rhs.length)
    }
}

class TorrentPieceDownloadBuffer {
    
    static let blockSize = 16_384
    
    let index: Int
    let size: Int
    
    var isComplete: Bool {
        return unusedBlockRequests.count == 0 && pendingRequests.count == 0
    }
    
    var piece: Data? {
        return isComplete ? data : nil
    }
    
    private var data: Data
    private var unusedBlockRequests: [TorrentBlockRequest]
    private var pendingRequests: [TorrentBlockRequest] = []
    
    init(index: Int, size: Int) {
        self.index = index
        self.size = size
        self.data = Data(repeating: 0, count: size)
        
        let blockSize = TorrentPieceDownloadBuffer.blockSize
        
        var blockRequests: [TorrentBlockRequest] = []
        for i in 0..<size where i % blockSize == 0 {
            
            // Last block should be the remaining bytes
            let length: Int = ((i + blockSize) <= size) ? blockSize : (size - i)
            
            blockRequests.append(TorrentBlockRequest(piece: index, begin: i, length: length))
        }
        
        self.unusedBlockRequests = blockRequests
    }
    
    func nextDownloadBlock() -> TorrentBlockRequest? {
        guard unusedBlockRequests.count > 0 else { return nil }
        let result = unusedBlockRequests.removeLast()
        pendingRequests.append(result)
        return result
    }
    
    func gotBlock(_ blockData: Data, begin: Int) {
        
        let request = TorrentBlockRequest(piece: index, begin: begin, length: blockData.count)
        guard let pendingIndex = pendingRequests.index(of: request) else { return }
        
        let range = begin ..< (begin+blockData.count)
        data.replaceSubrange(range, with: blockData)
        
        pendingRequests.remove(at: pendingIndex)
    }
    
    
}
