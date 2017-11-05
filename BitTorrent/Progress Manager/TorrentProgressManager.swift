//
//  TorrentProgressManager.swift
//  BitTorrent
//
//  Created by Ben Davis on 12/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

typealias TorrentPieceRequest = (pieceIndex: Int, size: Int, checksum: Data)

class TorrentProgressManager {
    
    let fileManager: TorrentFileManager
    private(set) var progress: TorrentProgress
    
    var metaInfo: TorrentMetaInfo {
        return fileManager.metaInfo
    }
    
    convenience init(metaInfo: TorrentMetaInfo, rootDirectory: String) {
        let downloadDirectory = rootDirectory + "/" + metaInfo.sensibleDownloadDirectoryName()
        let fileManager = TorrentFileManager(metaInfo: metaInfo, rootDirectory: downloadDirectory)
        
        let bitFieldSize = metaInfo.info.pieces.count
        let progress: TorrentProgress
        if let bitField = TorrentFileManager.loadSavedProgressBitfield(infoHash: metaInfo.infoHash,
                                                                       size: bitFieldSize) {
            progress = TorrentProgress(bitField: bitField)
        } else {
            progress = TorrentProgress(size: bitFieldSize)
        }
        self.init(fileManager: fileManager, progress: progress)
    }
    
    init(fileManager: TorrentFileManager, progress: TorrentProgress) {
        self.fileManager = fileManager
        self.progress = progress
    }
    
    public func forceReCheck() {
        let bitField = fileManager.reCheckProgress()
        progress = TorrentProgress(bitField: bitField)
        TorrentFileManager.saveProgressBitfield(progress.bitField, infoHash: metaInfo.infoHash)
    }
    
    func getNextPieceToDownload(from availablePieces: BitField) -> TorrentPieceRequest? {
        
        guard !progress.complete else { return nil }
        
        for (i, isSet) in availablePieces.lazy.pseudoRandomized where isSet {
            if !progress.hasPiece(i) && !progress.isCurrentlyDownloading(piece: i) {
                progress.setCurrentlyDownloading(piece: i)
                return (i, metaInfo.info.lengthOfPiece(at: i), metaInfo.info.pieces[i])
            }
        }
        return nil
    }
    
    func setDownloadedPiece(_ piece: Data, pieceIndex: Int) {
        progress.finishedDownloading(piece: pieceIndex)
        fileManager.setPiece(at: pieceIndex, data: piece)
        TorrentFileManager.saveProgressBitfield(progress.bitField, infoHash: metaInfo.infoHash)
    }
    
    func setLostPiece(at index: Int) {
        progress.setLostPiece(index)
    }
}
