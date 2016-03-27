//
//  TorrentMetaInfoTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 25/03/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent
import BEncode

class TorrentMetaInfoTests: XCTestCase {

    let filePieceLength = 16384
    let singleFilePiece = NSData(byteArray: [0x3f, 0x3f, 0x11, 0x09, 0x64, 0x07, 0x00, 0x3f, 0x42,
        0x35, 0x3f, 0x3f, 0x59, 0x2e, 0x23, 0x13, 0x3f, 0x18, 0x23, 0x3e])
    let torrentName = "Torrent Name"
    let singleFileName = "test.txt"
    let singleFileLength = 117
    let singleFileMD5 = "c23d5ddec291bf9e27cb84657144388dc352472ca89709bbda80e680c82470e1"
    let multipleFile1MD5 = "d8e624fda84296ba9e5af415faa5c2aa68960ce0578116a8507340438893bd85"
    let multipleFile2MD5 = "e2ddfed708ea34db57b4a1ef7691776db5e24dff813706e4c695a6668f8fbabf"
    let multipleFileLength1 = 116
    let multipleFileLength2 = 115
    let multipleFilePath1 = "/test/path"
    let multipleFilePath2 = "/test/path2"
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Create some example dictionaries
    
    func singleFileInfoDictionary() -> [String:AnyObject] {
        return [
            "piece length" : filePieceLength,
            "pieces" : createMultiplePieces(),
            "name" : singleFileName,
            "length" : singleFileLength,
        ]
    }
    
    func createMultiplePieces() -> NSData {
        return NSMutableData(data: singleFilePiece).andData(singleFilePiece)
    }
    
    func multiFileInfoDictionary() -> [String:AnyObject] {
        return multiFileInfoDictionary([
            testFileDictionary(multipleFileLength1, path: multipleFilePath1, md5sum: multipleFile1MD5),
            testFileDictionary(multipleFileLength2, path: multipleFilePath2, md5sum: multipleFile2MD5),
            ])
    }
    
    func multiFileInfoDictionary(files: [ [ String : AnyObject ] ]) -> [String:AnyObject] {
        return [
            "piece length" : filePieceLength,
            "pieces" : createMultiplePieces(),
            "name" : torrentName,
            "files" : files,
        ]
    }
    
    func testFileDictionary(length: Int, path: String, md5sum: String?) -> [ String : AnyObject ] {
        var result: [ String : AnyObject ] = [
            "length" : length,
            "path" : path,
        ]
        if let md5sum = md5sum {
            result.updateValue(md5sum, forKey:"md5sum")
        }
        return result
    }
    
    func exampleMetaInfoDictionary() -> NSData {
        return self.metaInfoDictionaryWithInfoDictionary(singleFileInfoDictionary())
    }
    
    func metaInfoDictionaryWithInfoDictionary(infoDictionary: [String : AnyObject]) -> NSData {
        return try! BEncode.BEncoder.encode( [ "info" : infoDictionary ] )
    }
    
    // MARK: -

    func testCanInitialiseWithDictionary() {
        let metaInfo = TorrentMetaInfo(data: self.exampleMetaInfoDictionary())!
        let _ = metaInfo.infoHash
        let _ = metaInfo.info
    }
    
    func testInfoDictionarySplitsPiecesInto20ByteChecksums() {
        let metaInfo = TorrentMetaInfo(data: self.exampleMetaInfoDictionary())!
        let info = metaInfo.info
        XCTAssertEqual(info.pieces![0], singleFilePiece)
        XCTAssertEqual(info.pieces![1], singleFilePiece)
    }
    
    func testProducesCorrectInfoHash() {
        let path = NSBundle(forClass: self.dynamicType).pathForResource("TestText", ofType: "torrent")
        let data = NSData(contentsOfFile: path!)!
        let metaInfo = TorrentMetaInfo(data: data)!

        let hash = NSData(byteArray:[ 0xf0, 0xb8, 0x71, 0x98, 0x99, 0x53, 0x97, 0x3f, 0xbf, 0xa9, 0x4d,
            0xc8, 0x14, 0x98, 0xee, 0x8d, 0x20, 0x5b, 0xb2, 0x23])
        
        XCTAssertEqual(hash, metaInfo.infoHash)
    }

    // MARK: - Test info dictionary
    
    func testProducesCorrectCommonInfoDictionaryProperties() {
        let metaInfo = TorrentMetaInfo(data: self.exampleMetaInfoDictionary())!
        let info = metaInfo.info
        
        XCTAssertEqual(info.name, singleFileName)
        
        XCTAssertEqual(info.pieceLength, filePieceLength)
        
        let piecesConcatenated = info.pieces!.reduce(NSMutableData()) {
            (result: NSMutableData, item: NSData) in
            return result.andData(item)
        }
        XCTAssertEqual(piecesConcatenated, createMultiplePieces())
    }
    
    func testIsPrivateIffPrivateKeyIsPresentAnd1() {
        var infoDictionary = singleFileInfoDictionary()
        
        infoDictionary.updateValue(1, forKey: "private")
        var metainfo = TorrentMetaInfo(data: metaInfoDictionaryWithInfoDictionary(infoDictionary))!
        XCTAssertTrue(metainfo.info.isPrivate)
        
        infoDictionary.updateValue(0, forKey: "private")
        metainfo = TorrentMetaInfo(data: metaInfoDictionaryWithInfoDictionary(infoDictionary))!
        XCTAssertFalse(metainfo.info.isPrivate)
        
        infoDictionary.removeValueForKey("private")
        metainfo = TorrentMetaInfo(data: metaInfoDictionaryWithInfoDictionary(infoDictionary))!
        XCTAssertFalse(metainfo.info.isPrivate)
    }
    
    // MARK: Single file info dictionary
    
    func testInfoDictionaryForSingleFileTorrent() {
        let metaInfo = TorrentMetaInfo(data: self.exampleMetaInfoDictionary())!
        let info = metaInfo.info

        XCTAssertEqual(info.length, singleFileLength)
        
        XCTAssertEqual(info.files.count, 1)
        
        let file = info.files[0]
        XCTAssertEqual(file.length, singleFileLength)
        XCTAssertEqual(file.path, singleFileName)

    }
    
    func testInfoDictionaryContainsMD5ChecksumIfPresentInSingleFile() {
        var infoDictionary = singleFileInfoDictionary()

        var metaInfo = TorrentMetaInfo(data: metaInfoDictionaryWithInfoDictionary(infoDictionary))!
        var file = metaInfo.info.files[0]
        XCTAssertNil(file.md5sum)
        
        
        infoDictionary.updateValue(singleFileMD5, forKey: "md5sum")
        metaInfo = TorrentMetaInfo(data: metaInfoDictionaryWithInfoDictionary(infoDictionary))!
        file = metaInfo.info.files[0]

        XCTAssertEqual(file.md5sum, singleFileMD5)

    }
    
    func testInitializerReturnsNilOnInvalidInfoDictionaryForSingleFile() {
        
        var infoDictionary = singleFileInfoDictionary()
        infoDictionary.removeValueForKey("name")
        var metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))
        
        infoDictionary = singleFileInfoDictionary()
        infoDictionary.removeValueForKey("piece length")
        metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))
        
        infoDictionary = singleFileInfoDictionary()
        infoDictionary.removeValueForKey("pieces")
        metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))
        
        infoDictionary = singleFileInfoDictionary()
        infoDictionary.updateValue(NSData(byteArray: [1,2,3]), forKey: "pieces")
        metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))
        
        infoDictionary = singleFileInfoDictionary()
        infoDictionary.updateValue(NSMutableData(length: 21)!, forKey: "pieces")
        metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))
    }
    
    // MARK: Multiple file info dictionary

    func testInfoDictionaryForMultipleFileTorrent() {
        let infoDictionary = multiFileInfoDictionary()
        let metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        let metaInfo = TorrentMetaInfo(data: metaInfoDictionary)!
        let info = metaInfo.info
        
        XCTAssertEqual(info.length, multipleFileLength1 + multipleFileLength2)
        
        XCTAssertEqual(info.files.count, 2)
        
        let file1 = info.files[0]
        XCTAssertEqual(file1.length, multipleFileLength1)
        XCTAssertEqual(file1.path, multipleFilePath1)
        
        let file2 = info.files[1]
        XCTAssertEqual(file2.length, multipleFileLength2)
        XCTAssertEqual(file2.path, multipleFilePath2)
        
    }
    
    func testInfoDictionaryContainsMD5ChecksumIfPresentInMultipleFiles() {
        
        var infoDictionary = multiFileInfoDictionary()
        var metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        var metaInfo = TorrentMetaInfo(data: metaInfoDictionary)!
        var file1 = metaInfo.info.files[0]
        var file2 = metaInfo.info.files[1]
        
        XCTAssertEqual(file1.md5sum, multipleFile1MD5)
        XCTAssertEqual(file2.md5sum, multipleFile2MD5)
        
        
        infoDictionary.updateValue(multipleFile1MD5, forKey: "md5sum")
        
        infoDictionary = multiFileInfoDictionary([
            [ "length" : multipleFileLength1, "path" : multipleFilePath1 ],
            [ "length" : multipleFileLength2, "path" : multipleFilePath2 ],
            ])
        metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        metaInfo = TorrentMetaInfo(data: metaInfoDictionary)!
        file1 = metaInfo.info.files[0]
        file2 = metaInfo.info.files[1]
        
        XCTAssertNil(file1.md5sum)
        XCTAssertNil(file2.md5sum)
        
        
    }
    
    func testInitializerReturnsNilOnInvalidInfoDictionaryForMultipleFiles() {
        
        var infoDictionary = multiFileInfoDictionary()
        infoDictionary.removeValueForKey("files")
        var metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))
        
        infoDictionary = multiFileInfoDictionary([
            [ "length" : multipleFileLength1, "path" : multipleFilePath1 ],
            [ "length" : multipleFileLength2 ],
            ])
        metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))
        
        infoDictionary = multiFileInfoDictionary([
            [ "length" : multipleFileLength1, "path" : multipleFilePath1 ],
            [ "path" : multipleFilePath2 ],
            ])
        metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))

    }
    
    
}
