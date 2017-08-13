//
//  TorrentProgressTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 23/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentProgressTests: XCTestCase {
    
    func test_torrentProgressIsInitialisedAsNoneDownloaded() {
        let result = TorrentProgress(size: 10)
        XCTAssertEqual(result.downloaded, 0)
        XCTAssertEqual(result.uploaded, 0)
    }
    
    func test_canMarkPieceAsDownloading() {
        var result = TorrentProgress(size: 10)
        XCTAssertFalse(result.isCurrentlyDownloading(piece: 3))
        result.setCurrentlyDownloading(piece: 3)
        XCTAssertTrue(result.isCurrentlyDownloading(piece: 3))
    }
    
    func test_canMarkPieceAsLost() {
        var result = TorrentProgress(size: 10)
        result.setCurrentlyDownloading(piece: 3)
        result.setLostPiece(3)
        XCTAssertFalse(result.isCurrentlyDownloading(piece: 3))
    }
    
    func test_canMarkPieceAsDownloaded() {
        var result = TorrentProgress(size: 10)
        result.setCurrentlyDownloading(piece: 3)
        XCTAssertFalse(result.hasPiece(3))
        result.finishedDownloading(piece: 3)
        XCTAssertFalse(result.isCurrentlyDownloading(piece: 3))
        XCTAssertTrue(result.hasPiece(3))
        XCTAssertEqual(result.downloaded, 1)
    }
    
    func test_canGetBitfield() {
        var result = TorrentProgress(size: 5)
        
        result.setCurrentlyDownloading(piece: 3)
        result.finishedDownloading(piece: 3)
        
        result.setCurrentlyDownloading(piece: 0)
        result.finishedDownloading(piece: 0)
        
        var expected = BitField(size: 5)
        expected.set(at: 0)
        expected.set(at: 3)
        
        XCTAssertEqual(result.bitField, expected)
    }
    
    func test_completeFlag() {
        var result = TorrentProgress(size: 2)
        
        XCTAssertFalse(result.complete)
        
        result.setCurrentlyDownloading(piece: 0)
        result.finishedDownloading(piece: 0)
        
        result.setCurrentlyDownloading(piece: 1)
        result.finishedDownloading(piece: 1)
        
        XCTAssertTrue(result.complete)
    }
    
    func test_percentageComplete() {
        var progress = TorrentProgress(size: 5)
        
        XCTAssertEqual(progress.percentageComplete, 0)
        
        progress.setCurrentlyDownloading(piece: 0)
        progress.finishedDownloading(piece: 0)
        XCTAssertEqual(Int(progress.percentageComplete * 100), 20)
        
        progress.setCurrentlyDownloading(piece: 1)
        progress.finishedDownloading(piece: 1)
        XCTAssertEqual(Int(progress.percentageComplete * 100), 40)
    }
}
