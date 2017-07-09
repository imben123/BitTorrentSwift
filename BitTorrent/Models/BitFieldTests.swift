//
//  BitFieldTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 08/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class BitFieldTests: XCTestCase {
    
    func test_create() {
        let sut = BitField(size: 5)
        XCTAssertEqual(sut.size, 5)
        XCTAssertEqual(sut.value, [false, false, false, false, false])
    }
    
    func test_canSetValueAtIndex() {
        var sut = BitField(size: 5)
        sut.set(at: 0)
        sut.set(at: 2)
        sut.set(at: 4)
        XCTAssertEqual(sut.value, [true, false, true, false, true])
    }
    
    func test_canUnsetValueAtIndex() {
        var sut = BitField(size: 5)
        sut.set(at: 0)
        sut.set(at: 2)
        sut.set(at: 4)
        sut.unset(at: 4)
        XCTAssertEqual(sut.value, [true, false, true, false, false])
    }
    
    func test_canConvertToData_bitsAlignToBytes() {
        var sut = BitField(size: 16)
        sut.set(at: 7)
        sut.set(at: 15)
        sut.set(at: 14)
        let result = sut.toData()
        XCTAssertEqual(result, Data(bytes:[1, 3]))
    }
    
    func test_canConvertToData_bitsDoNotAlignToBytes() {
        var sut = BitField(size: 13)
        sut.set(at: 7)
        sut.set(at: 12)
        let result = sut.toData()
        XCTAssertEqual(result, Data(bytes:[1, 8]))
    }
    
    func test_canConvertToData_lessThan8Bits() {
        var sut = BitField(size: 5)
        sut.set(at: 3)
        let result = sut.toData()
        XCTAssertEqual(result, Data(bytes:[16]))
    }
    
    func test_canInitWithData() {
        var example = BitField(size: 16)
        example.set(at: 7)
        example.set(at: 15)
        example.set(at: 14)
        
        let data = example.toData()
        let result = BitField(data: data)
        XCTAssertEqual(result, example)
    }
}
