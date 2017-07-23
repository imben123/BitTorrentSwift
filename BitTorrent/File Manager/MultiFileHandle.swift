//
//  MultiFileHandle.swift
//  BitTorrent
//
//  Created by Ben Davis on 23/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

protocol FileHandleProtocol {
    
    var offsetInFile: UInt64 { get }
    
    func readData(ofLength length: Int) -> Data
    func write(_ data: Data)
    func seek(toFileOffset offset: UInt64)
    func seekToEndOfFile() -> UInt64
    func synchronizeFile()
}

extension FileHandle: FileHandleProtocol {}

class MultiFileHandle: FileHandleProtocol {
    
    private typealias File = (handle: FileHandleProtocol, offset: UInt64, length: UInt64)
    private let files: [File]
    private var fileIndex: Int = 0
    
    var offsetInFile: UInt64 {
        return currentFile.offset + currentFile.handle.offsetInFile
    }
    
    private var currentFile: File { return files[fileIndex] }
    private var remainingInCurrentFile: UInt64 { return currentFile.offset + currentFile.length - offsetInFile }
    
    private init(fileHandles: [FileHandleProtocol], fileLengths: [UInt64]) {
        self.files = MultiFileHandle.createFiles(fileHandles: fileHandles, fileLengths: fileLengths)
    }
    
    convenience init(fileHandles: [FileHandleProtocol]) {
        var fileLengths: [UInt64] = []
        for handle in fileHandles {
            let length = handle.seekToEndOfFile()
            handle.seek(toFileOffset: 0)
            fileLengths.append(length)
        }
        self.init(fileHandles: fileHandles, fileLengths: fileLengths)
    }
    
    private static func createFiles(fileHandles: [FileHandleProtocol], fileLengths: [UInt64]) -> [File] {
        var result: [File] = []
        var offset: UInt64 = 0
        for i in 0 ..< fileHandles.count {
            let handle = fileHandles[i]
            let length = fileLengths[i]
            let element = File(handle: handle, offset: offset, length: length)
            offset += length
            result.append(element)
        }
        return result
    }
    
    func readData(ofLength length: Int) -> Data {
        let finalOffset = offsetInFile + UInt64(length)
        var result = Data()
        while offsetInFile != finalOffset {
            result += readData(until: finalOffset)
        }
        return result
    }
    
    private func readData(until offset: UInt64) -> Data {
        let length = min(remainingInCurrentFile, offset - offsetInFile)
        let result = currentFile.handle.readData(ofLength: Int(length))
        if currentFile.handle.offsetInFile == currentFile.length {
            incrementCurrentFile()
        }
        return result
    }
    
    func write(_ data: Data) {
        var remaining: Data? = data
        while let r = remaining {
            remaining = writeDataToEndOfCurrentFile(r)
        }
    }
    
    private func writeDataToEndOfCurrentFile(_ data: Data) -> Data? {
        guard remainingInCurrentFile >= data.count else {
            let dataToWrite = data[0 ..< Int(remainingInCurrentFile)]
            let remaining = data[Int(remainingInCurrentFile) ..< data.count]
            currentFile.handle.write(dataToWrite)
            incrementCurrentFile()
            return remaining
        }
        currentFile.handle.write(data)
        return nil
    }
    
    private func incrementCurrentFile() {
        fileIndex += 1
        currentFile.handle.seek(toFileOffset: 0)
    }
    
    func seek(toFileOffset offset: UInt64) {
        for i in 0 ..< files.count {
            fileIndex = i
            if (currentFile.offset + currentFile.length) > offset {
                let fileOffset = offset - currentFile.offset
                currentFile.handle.seek(toFileOffset: fileOffset)
                break
            }
        }
    }
    
    func seekToEndOfFile() -> UInt64 {
        fileIndex = files.count - 1
        _ = currentFile.handle.seekToEndOfFile()
        return offsetInFile
    }
    
    func synchronizeFile() {
        for file in files {
            file.handle.synchronizeFile()
        }
    }
}
