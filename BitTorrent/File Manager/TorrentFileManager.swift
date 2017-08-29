//
//  TorrentFileManager.swift
//  BitTorrent
//
//  Created by Ben Davis on 23/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

enum TorrentFileManagerError: Error {
    case couldNotCreateFile
}

public class TorrentFileManager {
    
    let metaInfo: TorrentMetaInfo
    let rootDirectory: String
    
    fileprivate let fileHandle: FileHandleProtocol
    
    convenience init(metaInfo: TorrentMetaInfo, rootDirectory: String) {
        let fileHandles = TorrentFileManager.createFileHandles(for: metaInfo, in: rootDirectory)
        self.init(metaInfo: metaInfo, rootDirectory: rootDirectory, fileHandles: fileHandles)
    }
    
    init(metaInfo: TorrentMetaInfo, rootDirectory: String, fileHandles: [FileHandleProtocol]) {
        self.metaInfo = metaInfo
        self.rootDirectory = rootDirectory
        self.fileHandle = MultiFileHandle(fileHandles: fileHandles)
    }
    
    private static func createFileHandles(for metaInfo: TorrentMetaInfo, in rootDirectory: String) -> [FileHandle] {
        var result: [FileHandle] = []
        for fileInfo in metaInfo.info.files {
            let fullPath = rootDirectory + "/" + fileInfo.path
            let fileHandle = FileHandle(forUpdatingAtPath: fullPath)!
            result.append(fileHandle)
        }
        return result
    }
    
    // MARK: set and get piece
    
    func setPiece(at index: Int, data: Data) {
        let byteIndex = index * metaInfo.info.pieceLength
        fileHandle.seek(toFileOffset: UInt64(byteIndex))
        fileHandle.write(data)
    }
    
    func getPiece(at index: Int) -> Data {
        let byteIndex = index * metaInfo.info.pieceLength
        let length = metaInfo.info.lengthOfPiece(at: index)
        fileHandle.seek(toFileOffset: UInt64(byteIndex))
        return fileHandle.readData(ofLength: length)
    }
    
    // TODO: Multi-threaded check
    func reCheckProgress() -> BitField {
        var result = BitField(size: metaInfo.info.pieces.count)
        for (pieceIndex, _) in result {
            autoreleasepool {
                let correctSha1 = metaInfo.info.pieces[pieceIndex]
                let piece = getPiece(at: pieceIndex)
                let sha1 = piece.sha1()
                if sha1 == correctSha1 {
                    result.set(at: pieceIndex)
                }
            }
        }
        return result
    }
}

// MARK: - Prepare directory
extension TorrentFileManager {
    
    public static func prepareRootDirectory(_ rootDirectory: String,
                                            forTorrentMetaInfo metaInfo: TorrentMetaInfo) throws {
        
        try createDirectoryIfNeeded(directoryPath: rootDirectory)
        
        for file in metaInfo.info.files {
            let fullPath = rootDirectory + "/" + file.path
            try createSubDirectoryIfNeeded(at: fullPath)
            try createEmptyFileIfNeeded(at: fullPath, length: file.length)
        }
    }
    
    private static func createSubDirectoryIfNeeded(at path: String) throws {
        let directory = URL(fileURLWithPath: path, isDirectory: false).deletingLastPathComponent()
        try createDirectoryIfNeeded(directoryPath: directory.path)
    }
    
    private static func createDirectoryIfNeeded(directoryPath: String) throws {
        if (!FileManager.default.fileExists(atPath: directoryPath)) {
            try FileManager.default.createDirectory(atPath: directoryPath,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }
    }
    
    private static func createEmptyFileIfNeeded(at path: String, length: Int) throws {
        
        guard !FileManager.default.fileExists(atPath: path) else {
            return
        }
        
        guard FileManager.default.createFile(atPath: path, contents: nil, attributes: nil) else {
            throw TorrentFileManagerError.couldNotCreateFile
        }
        
        let fileDescriptor: CInt = open(path, O_WRONLY, 0644) // open file for writing
        lseek(fileDescriptor, off_t(length), SEEK_SET) // seek to the last byte ...
        write(fileDescriptor, UnsafeRawPointer([0]), 1) // ... and write a 0 to it
        close(fileDescriptor) // Now we have a file of the correct size we close it
    }
}

// Save/Load progress
extension TorrentFileManager {
    
    static func saveProgressBitfield(_ bitfield: BitField, infoHash: Data) {
        let fileName = String(asciiData: infoHash.base64EncodedData())!
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                .userDomainMask,
                                                                true)[0] as String
        let documentsUrl = URL(fileURLWithPath: documentsPath, isDirectory: true)
        let fileURL = documentsUrl.appendingPathComponent("torrent_progress.bin", isDirectory: false)
        try? bitfield.toData().write(to: fileURL)
    }
    
    static func loadSavedProgressBitfield(infoHash: Data) -> BitField? {
        let fileName = String(asciiData: infoHash.base64EncodedData())!
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                .userDomainMask,
                                                                true)[0] as String
        let documentsUrl = URL(fileURLWithPath: documentsPath, isDirectory: true)
        let fileURL = documentsUrl.appendingPathComponent("torrent_progress.bin", isDirectory: false)
        if let data = try? Data(contentsOf: fileURL) {
            return BitField(data: data)
        }
        return nil
    }
}
