//
//  TorrentUploadPieceRequest.swift
//  BitTorrent
//
//  Created by Ben Davis on 29/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

struct TorrentBlock {
    let piece: Int
    let begin: Int
    let length: Int
    let data: Data
}

struct TorrentUploadPieceRequest {
    
    private let data: Data
    private let index: Int
    private let length: Int
    private var blockRequests: [TorrentBlockRequest] = []
    
    var hasBlockRequests: Bool {
        return blockRequests.first != nil
    }
    
    init(data: Data, index: Int, length: Int) {
        self.data = data
        self.index = index
        self.length = length
    }
    
    mutating func addRequest(_ request: TorrentBlockRequest) {
        blockRequests.append(request)
    }
    
    func nextUploadBlock() -> TorrentBlock? {
        guard let request = self.blockRequests.first else { return nil }
        
        let begin = request.begin
        let end = begin + request.length
        let blockData = data[begin..<end]
        return TorrentBlock(piece: request.piece,
                            begin: request.begin,
                            length: request.length,
                            data: blockData)
    }
}
