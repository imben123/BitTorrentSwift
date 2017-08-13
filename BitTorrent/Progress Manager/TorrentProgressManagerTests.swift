//
//  TorrentProgressManagerTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 12/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentProgressManagerTests: XCTestCase {
    
    var fileManager: TorrentFileManager!
    var fileHandle: FileHandleFake!
    var sut: TorrentProgressManager!
    
    let metaInfo: TorrentMetaInfo = {
        let path = Bundle(for: TorrentProgressManagerTests.self).path(forResource: "TestText", ofType: "torrent")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        return TorrentMetaInfo(data: data)!
    }()
    
    let completeBitField: BitField = {
        var result = BitField(size: 1)
        result.set(at: 0)
        return result
    }()
    
    override func setUp() {
        super.setUp()
        
        let data = Data(repeating: 0, count: metaInfo.info.length)
        fileHandle = FileHandleFake(data: data)
        
        fileManager = TorrentFileManager(metaInfo: metaInfo,
                                         rootDirectory: "/",
                                         fileHandles: [fileHandle])
        
        let progress = TorrentProgress(size: metaInfo.info.pieces.count)
        
        sut = TorrentProgressManager(fileManager: fileManager, progress: progress)
    }
    
    func test_exampleMetaInfoOnlyHas1Piece() {
        XCTAssertEqual(metaInfo.info.pieces.count, 1)
    }
    
    func test_canGetNextPieceToDownload() {
        
        let resultOptional = sut.getNextPieceToDownload(from: completeBitField)
        guard let result = resultOptional else {
            XCTFail("Couldn't get a piece to download")
            return
        }
        
        XCTAssertEqual(result.pieceIndex, 0)
        XCTAssertEqual(result.size, metaInfo.info.lengthOfPiece(at: 0))
        XCTAssertEqual(result.checksum, metaInfo.info.pieces[0])
    }
    
    func test_currentlyDownloadingPieceIsNotReturned() {
        _ = sut.getNextPieceToDownload(from: completeBitField)
        let result = sut.getNextPieceToDownload(from: completeBitField)
        XCTAssertNil(result)
    }
    
    func test_downloadedPieceIsNotReturned() {
        _ = sut.getNextPieceToDownload(from: completeBitField)
        
        let data = Data(repeating: 1, count: metaInfo.info.length)
        sut.setDownloadedPiece(data, pieceIndex: 0)
        
        let result = sut.getNextPieceToDownload(from: completeBitField)
        XCTAssertNil(result)
    }
    
    func test_pieceReturnedAgainIfLost() {
        _ = sut.getNextPieceToDownload(from: completeBitField)
        sut.setLostPiece(at: 0)
        let result = sut.getNextPieceToDownload(from: completeBitField)
        XCTAssertNotNil(result)
    }
    
    func test_downloadedPieceIsSavedToFile() {
        _ = sut.getNextPieceToDownload(from: completeBitField)
        
        let data = Data(repeating: 1, count: metaInfo.info.length)
        sut.setDownloadedPiece(data, pieceIndex: 0)
        
        XCTAssertEqualData(fileHandle.data, data)
    }
    
    func test_doesNotReturnUnavailablePieces() {
        let emptyBitField = BitField(size: 1)
        let result = sut.getNextPieceToDownload(from: emptyBitField)
        XCTAssertNil(result)
    }
}
