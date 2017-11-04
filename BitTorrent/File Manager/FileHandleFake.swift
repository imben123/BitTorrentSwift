//
//  FileHandleFake.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 23/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation
@testable import BitTorrent

class FileHandleFake: FileHandleProtocol {
    
    var data: Data
    private var currentOffset: Int = 0
    var offsetInFile: UInt64 {
        return UInt64(currentOffset)
    }
    
    init(data: Data) {
        self.data = data
    }
    
    func readData(ofLength length: Int) -> Data {
        let beginOffset = currentOffset
        currentOffset += length
        return data.correctingIndicies[beginOffset ..< currentOffset]
    }
    
    func write(_ data: Data) {
        let beginOffset = currentOffset
        currentOffset += data.count
        self.data[beginOffset ..< currentOffset] = data
    }
    
    func seek(toFileOffset offset: UInt64) {
        currentOffset = Int(offset)
    }
    
    func seekToEndOfFile() -> UInt64 {
        currentOffset = data.count
        return offsetInFile
    }
    
    var synchronizeFileCalled = false
    func synchronizeFile() {
        synchronizeFileCalled = true
    }
}
