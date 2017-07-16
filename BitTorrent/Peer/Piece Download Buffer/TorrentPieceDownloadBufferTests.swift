//
//  TorrentPieceDownloadBufferTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 16/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentPieceDownloadBufferTests: XCTestCase {
    
    let index = 123
    let blockSize = TorrentPieceDownloadBuffer.blockSize
    
    func test_creation() {
        let size = 234
        let sut = TorrentPieceDownloadBuffer(index: index, size: size)
        XCTAssertEqual(sut.index, index)
        XCTAssertEqual(sut.size, size)
    }
    
    func test_splitsPieceIntoBlockRequests() {
        let size: Int = Int(Double(blockSize)*2.5)
        let sut = TorrentPieceDownloadBuffer(index: index, size: size)
        
        let block1 = sut.nextDownloadBlock()
        let block2 = sut.nextDownloadBlock()
        let block3 = sut.nextDownloadBlock()
        let block4 = sut.nextDownloadBlock()
        
        XCTAssertNil(block4)
        
        let sortedBlocks = [block1!, block2!, block3!].sorted(by: { $0.begin < $1.begin })
        XCTAssertEqual(sortedBlocks, [
            TorrentBlockRequest(piece: index, begin: 0, length: blockSize),
            TorrentBlockRequest(piece: index, begin: blockSize, length: blockSize),
            TorrentBlockRequest(piece: index, begin: blockSize*2, length: Int(Double(blockSize)*0.5)),
            ])
    }
    
    func test_isComplete() {
        let size: Int = Int(Double(blockSize)*2.5)
        let sut = TorrentPieceDownloadBuffer(index: index, size: size)
        
        XCTAssertFalse(sut.isComplete)
        
        _ = sut.nextDownloadBlock()
        _ = sut.nextDownloadBlock()
        _ = sut.nextDownloadBlock()
        
        XCTAssertFalse(sut.isComplete)
        
        let data1 = Data(repeating: 0, count: blockSize)
        let data2 = Data(repeating: 0, count: blockSize)
        let data3 = Data(repeating: 0, count: Int(Double(blockSize)*0.5))
        
        sut.gotBlock(data1, begin: 0)
        XCTAssertFalse(sut.isComplete)
        
        sut.gotBlock(data2, begin: blockSize)
        XCTAssertFalse(sut.isComplete)
        
        sut.gotBlock(data3, begin: blockSize*2)
        XCTAssertTrue(sut.isComplete)
    }
    
    func test_resultingData() {
        let size: Int = Int(Double(blockSize)*2.5)
        let sut = TorrentPieceDownloadBuffer(index: index, size: size)
        
        XCTAssertNil(sut.piece)
        
        _ = sut.nextDownloadBlock()
        _ = sut.nextDownloadBlock()
        _ = sut.nextDownloadBlock()
        
        XCTAssertNil(sut.piece)
        
        let data1 = Data(repeating: 1, count: blockSize)
        let data2 = Data(repeating: 2, count: blockSize)
        let data3 = Data(repeating: 3, count: Int(Double(blockSize)*0.5))
        let complete = data1 + data2 + data3
        
        sut.gotBlock(data1, begin: 0)
        XCTAssertNil(sut.piece)
        
        sut.gotBlock(data2, begin: blockSize)
        XCTAssertNil(sut.piece)
        
        sut.gotBlock(data3, begin: blockSize*2)
        XCTAssertEqual(sut.piece, complete)
    }
}
