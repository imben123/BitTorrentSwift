//
//  TorrentProgressManager.swift
//  BitTorrent
//
//  Created by Ben Davis on 12/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

class TorrentProgressManager {
    
    let fileManager: TorrentFileManager
    var progress: TorrentProgress
    
    var metaInfo: TorrentMetaInfo {
        return fileManager.metaInfo
    }
    
    convenience init(metaInfo: TorrentMetaInfo, rootDirectory: String) {
        let fileManager = TorrentFileManager(metaInfo: metaInfo, rootDirectory: rootDirectory)
        let progress = TorrentProgress(size: metaInfo.info.pieces.count)
        self.init(fileManager: fileManager, progress: progress)
    }
    
    init(fileManager: TorrentFileManager, progress: TorrentProgress) {
        self.fileManager = fileManager
        self.progress = progress
    }
    
    func getNextPieceToDownload() -> (pieceIndex: Int, size: Int, checksum: Data)? {
        for i in 0 ..< progress.bitField.size {
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
    }
    
    func setLostPiece(at index: Int) {
        progress.setLostPiece(index)
    }
}
