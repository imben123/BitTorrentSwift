//
//  MultFileHandleTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 23/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class MultFileHandleTests: XCTestCase {
    
    var fileHandles: [FileHandleFake]!
    var sut: MultiFileHandle!
    
    override func setUp() {
        super.setUp()
        
        fileHandles = [
            FileHandleFake(data: Data(bytes: [1,2,3])),
            FileHandleFake(data: Data(bytes: [4,5,6,7,8])),
            FileHandleFake(data: Data(bytes: [9,10])),
        ]
        
        sut = MultiFileHandle(fileHandles: fileHandles)
    }
    
    func test_startsAtOffset0() {
        XCTAssertEqual(sut.offsetInFile, 0)
    }
    
    func test_seekInFile() {
        sut.seek(toFileOffset: 4)
        XCTAssertEqual(sut.offsetInFile, 4)
    }
    
    func test_seekToEndOfFile() {
        let result = sut.seekToEndOfFile()
        XCTAssertEqual(result, 10)
        XCTAssertEqual(sut.offsetInFile, 10)
    }
    
    func test_readDataFromFirstFile() {
        let data = sut.readData(ofLength: 2)
        XCTAssertEqual(data, Data(bytes: [1,2]))
    }
    
    func test_scanAndReadData() {
        sut.seek(toFileOffset: 4)
        let data = sut.readData(ofLength: 3)
        XCTAssertEqual(data, Data(bytes: [5,6,7]))
    }
    
    func test_readDataOverMultipleFiles() {
        let data = sut.readData(ofLength: 5)
        XCTAssertEqual(data, Data(bytes: [1,2,3,4,5]))
    }
    
    func test_writeDataFromFirstFile() {
        sut.write(Data(bytes: [11, 12]))
        let fileHandle = fileHandles[0]
        XCTAssertEqual(fileHandle.data, Data(bytes: [11,12,3]))
    }
    
    func test_scanAndWriteData() {
        sut.seek(toFileOffset: 4)
        sut.write(Data(bytes: [15, 16, 17]))
        let fileHandle = fileHandles[1]
        XCTAssertEqual(fileHandle.data, Data(bytes: [4, 15, 16, 17, 8]))
    }
    
    func test_writeDataOverMultipleFiles() {
        sut.write(Data(bytes: [11, 12, 13, 14, 15]))
        XCTAssertEqual(fileHandles[0].data, Data(bytes: [11, 12, 13]))
        XCTAssertEqual(fileHandles[1].data, Data(bytes: [14, 15, 6, 7, 8]))
    }
    
    func test_synchroniseFileAppliesToAllFiles() {
        sut.synchronizeFile()
        for fileHandle in fileHandles {
            XCTAssert(fileHandle.synchronizeFileCalled)
        }
    }
    
    func test_canReadLastBytes() {
        sut.seek(toFileOffset: 8)
        let data = sut.readData(ofLength: 2)
        XCTAssertEqual(data, Data(bytes: [9,10]))
    }
}
