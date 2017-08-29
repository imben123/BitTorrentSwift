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
    let length = 20
    
    func test_hasNoPendingRequestsOnInit() {
        let sut = TorrentUploadPieceRequest(data: data, index: index, length: length)
        XCTAssertFalse(sut.hasBlockRequests)
        XCTAssertNil(sut.nextUploadBlock())
    }
    
    func test_nextUploadBlockReturnsCorrectData() {
        var sut = TorrentUploadPieceRequest(data: data, index: index, length: length)
        
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
            XCTAssertEqualData(result.data, expected)
        }
    }
    
}
