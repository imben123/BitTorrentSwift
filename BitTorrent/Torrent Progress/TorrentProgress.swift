//
//  TorrentProgress.swift
//  BitTorrent
//
//  Created by Ben Davis on 23/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

struct TorrentProgress {
    
    private(set) var bitField: BitField
    private var piecesBeingDownloaded: [Int] = []
    
    private(set) var uploaded: Int = 0
    private(set) var downloaded: Int = 0
    
    init(size: Int) {
        self.bitField = BitField(size: size)
    }
    
    func isCurrentlyDownloading(piece: Int) -> Bool {
        return piecesBeingDownloaded.contains(piece)
    }
    
    func hasPiece(_ index: Int) -> Bool {
        return bitField.isSet(at: index)
    }
    
    mutating func setCurrentlyDownloading(piece: Int) {
        piecesBeingDownloaded.append(piece)
    }
    
    mutating func setLostPiece(_ piece: Int) {
        if let index = piecesBeingDownloaded.index(of: piece) {
            piecesBeingDownloaded.remove(at: index)
        }
    }
    
    mutating func finishedDownloading(piece: Int) {
        if let index = piecesBeingDownloaded.index(of: piece) {
            piecesBeingDownloaded.remove(at: index)
            downloaded += 1
            bitField.set(at: piece)
        }
    }
}
