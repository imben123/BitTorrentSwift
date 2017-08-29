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
        
        let progress: TorrentProgress
        if let bitField = TorrentFileManager.loadSavedProgressBitfield(infoHash: metaInfo.infoHash) {
            progress = TorrentProgress(bitField: bitField)
        } else {
            progress = TorrentProgress(size: metaInfo.info.pieces.count)
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
    }
    
    func getNextPieceToDownload(from availablePieces: BitField) -> TorrentPieceRequest? {
        for (i, isSet) in availablePieces where isSet {
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
