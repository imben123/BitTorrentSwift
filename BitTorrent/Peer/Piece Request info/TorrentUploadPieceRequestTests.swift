//
//  TorrentUploadPieceRequestTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 29/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TorrentUploadPieceRequestTests: XCTestCase {
    
    let data = Data(repeating: 1, count: 10) + Data(repeating: 2, count: 10)
    let index = 123
    
    func test_hasNoPendingRequestsOnInit() {
        let sut = TorrentUploadPieceRequest(data: data, index: index)
        XCTAssertFalse(sut.hasBlockRequests)
        XCTAssertNil(sut.nextUploadBlock())
    }
    
    func test_nextUploadBlockReturnsCorrectData() {
        let sut = TorrentUploadPieceRequest(data: data, index: index)
        
        let request = TorrentBlockRequest(piece: index, begin: 5, length: 10)
        sut.addRequest(request)
        
        let result = sut.nextUploadBlock()
        XCTAssertNotNil(result, "Result shouldn't be nil")
        if let result = result {
            XCTAssertEqual(result.begin, 5)
            XCTAssertEqual(result.length, 10)
            XCTAssertEqual(result.piece, index)
            
            let expected = Data(bytes: [ 1, 1, 1, 1, 1,
                                         2, 2, 2, 2, 2])
            XCTAssertEqual(result.data, expected)
        }
    }
    
    func test_cannotGetUploadBlockTwice() {
        let sut = TorrentUploadPieceRequest(data: data, index: index)
        
        let request = TorrentBlockRequest(piece: index, begin: 5, length: 10)
        sut.addRequest(request)
        
        _ = sut.nextUploadBlock()
        let result = sut.nextUploadBlock()
        
        XCTAssertNil(result)
    }
    
    func test_canRemoveBlockRequest() {
        let sut = TorrentUploadPieceRequest(data: data, index: index)
        
        let request = TorrentBlockRequest(piece: index, begin: 5, length: 10)
        sut.addRequest(request)
        sut.removeRequest(request)
        
        let result = sut.nextUploadBlock()
        XCTAssertNil(result, "Result should be nil")
    }
}
