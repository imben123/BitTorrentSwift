//
//  TorrentFileManagerTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 13/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentFileManagerTests: XCTestCase {
    
    let metaInfo: TorrentMetaInfo = {
        let path = Bundle(for: TorrentProgressManagerTests.self).path(forResource: "BigTorrentTest",
                                                                      ofType: "torrent")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        return TorrentMetaInfo(data: data)!
    }()
    
    let piece1: Data = {
        let path = Bundle(for: TorrentProgressManagerTests.self).path(forResource: "Data",
                                                                      ofType: "bin")
        return try! Data(contentsOf: URL(fileURLWithPath: path!))
    }()
    
    var fileHandle: FileHandleFake!
    var sut: TorrentFileManager!
    
    override func setUp() {
        super.setUp()
        
        fileHandle = FileHandleFake(data: Data(repeating: 0, count: metaInfo.info.length))
        sut = TorrentFileManager(metaInfo: metaInfo, rootDirectory: "/", fileHandles: [fileHandle])
    }
    
    func test_canSetPiece() {
        // Given
        let pieceLength = metaInfo.info.pieceLength
        
        // When
        sut.setPiece(at: 1, data: piece1)
        
        // Then
        XCTAssertEqual(fileHandle.data.correctingIndicies[pieceLength..<pieceLength*2], piece1)
    }
    
    func test_canGetPiece() {
        // Given
        sut.setPiece(at: 1, data: piece1)
        
        // When
        let result = sut.getPiece(at: 1)
        
        // Then
        XCTAssertEqual(result, piece1)
    }
    
    // Really slow test (takes ~3.5 seconds)
    // TODO: Need to create a smaller torrent with multiple pieces to verify against
//    func test_canGetProgressFromFile() {
//        
//        var expected = BitField(size: metaInfo.info.pieces.count)
//        expected.set(at: 1)
//        
//        sut.setPiece(at: 1, data: piece1)
//        
//        let result = sut.reCheckProgress()
//        
//        XCTAssertEqual(result, expected)
//    }
}
