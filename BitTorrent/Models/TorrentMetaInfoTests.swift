//
//  TorrentMetaInfoTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 25/03/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent
@testable import BEncode

extension Array where Element: Equatable {
    
    static func ==(lhs: Array<Element>, rhs: Array<Element>) -> Bool {
        for i in [0..<lhs.count] {
            if lhs[i] != rhs[i] {
                return false
            }
        }
        return true
    }
}

class TorrentMetaInfoTests: XCTestCase {

    let filePieceLength = 16384
    let singleFilePiece = Data(bytes: [0x3f, 0x3f, 0x11, 0x09, 0x64, 0x07, 0x00, 0x3f, 0x42,
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
    let announceString = "annouce string"
    let announceList: [[String]] =  [ [ "tracker1", "tracker2" ], ["backup1"] ]
    let creationDateInt: Int = 123456789
    let creationDate = Date(timeIntervalSince1970: 123456789)
    let comment = "Comment"
    let createdBy = "Created By"
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Create some example dictionaries
    
    func singleFileInfoDictionary() -> [String:AnyObject] {
        return [
            "piece length" : filePieceLength as AnyObject,
            "pieces" : createMultiplePieces() as AnyObject,
            "name" : singleFileName as AnyObject,
            "length" : singleFileLength as AnyObject,
        ]
    }
    
    func createMultiplePieces() -> Data {
        return singleFilePiece.andData(singleFilePiece)
    }
    
    func multiFileInfoDictionary() -> [String:AnyObject] {
        return multiFileInfoDictionary([
            testFileDictionary(multipleFileLength1, path: multipleFilePath1, md5sum: multipleFile1MD5),
            testFileDictionary(multipleFileLength2, path: multipleFilePath2, md5sum: multipleFile2MD5),
            ])
    }
    
    func multiFileInfoDictionary(_ files: [ [ String : AnyObject ] ]) -> [String:AnyObject] {
        return [
            "piece length" : filePieceLength as AnyObject,
            "pieces" : createMultiplePieces() as AnyObject,
            "name" : torrentName as AnyObject,
            "files" : files as AnyObject,
        ]
    }
    
    func testFileDictionary(_ length: Int, path: String, md5sum: String?) -> [ String : AnyObject ] {
        var result: [ String : AnyObject ] = [
            "length" : length as AnyObject,
            "path" : path as AnyObject,
        ]
        if let md5sum = md5sum {
            result.updateValue(md5sum as AnyObject, forKey:"md5sum")
        }
        return result
    }
    
    func exampleMetaInfoDictionary() -> Data {
        return self.metaInfoDictionaryWithInfoDictionary(singleFileInfoDictionary())
    }
    
    func metaInfoDictionaryWithInfoDictionary(_ infoDictionary: [String : AnyObject]) -> Data {
        return metaInfoDictionaryWithDictionary( unEncodedMetaInfoWithInfoDictionary(infoDictionary) )
    }
    
    func metaInfoDictionaryWithDictionary(_ dictionary: [String : AnyObject]) -> Data {
        return try! BEncode.BEncoder.encode( dictionary )
    }
    
    func unEncodedMetaInfoWithInfoDictionary(_ infoDictionary: [String : AnyObject]) -> [String : AnyObject] {
        return [
            "info" : infoDictionary as AnyObject,
            "announce" : announceString as AnyObject,
            "announce-list": announceList as AnyObject,
            "creation date": creationDateInt as AnyObject,
            "comment": comment as AnyObject,
            "created by": createdBy as AnyObject,
        ]
    }
    
    // MARK: -

    func testCanInitialiseWithDictionary() {
        let metaInfo = TorrentMetaInfo(data: self.exampleMetaInfoDictionary())!
        XCTAssertEqual(metaInfo.announce, announceString)
        XCTAssertEqual(metaInfo.announceList! as NSArray, announceList as NSArray)
        XCTAssertEqual(metaInfo.creationDate!, creationDate)
        XCTAssertEqual(metaInfo.comment!, comment)
        XCTAssertEqual(metaInfo.createdBy!, createdBy)
    }
    
    func testInfoDictionarySplitsPiecesInto20ByteChecksums() {
        let metaInfo = TorrentMetaInfo(data: self.exampleMetaInfoDictionary())!
        let info = metaInfo.info
        XCTAssertEqual(info.pieces![0], singleFilePiece)
        XCTAssertEqual(info.pieces![1], singleFilePiece)
    }
    
    func testProducesCorrectInfoHash() {
        let path = Bundle(for: type(of: self)).path(forResource: "TestText", ofType: "torrent")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let metaInfo = TorrentMetaInfo(data: data)!

        let hash = Data(bytes:[ 0xf0, 0xb8, 0x71, 0x98, 0x99, 0x53, 0x97, 0x3f, 0xbf, 0xa9, 0x4d,
            0xc8, 0x14, 0x98, 0xee, 0x8d, 0x20, 0x5b, 0xb2, 0x23])
        
        XCTAssertEqual(hash, metaInfo.infoHash)
    }
    
    func testInitializerReturnsNilOnInvalidFields() {
        var metainfoDictionary = self.unEncodedMetaInfoWithInfoDictionary(singleFileInfoDictionary())
        metainfoDictionary.removeValue(forKey: "announce")
        var metaInfo = TorrentMetaInfo(data: metaInfoDictionaryWithDictionary(metainfoDictionary))
        XCTAssertNil(metaInfo)
        
        metainfoDictionary = self.unEncodedMetaInfoWithInfoDictionary(singleFileInfoDictionary())
        metainfoDictionary.removeValue(forKey: "info")
        metaInfo = TorrentMetaInfo(data: metaInfoDictionaryWithDictionary(metainfoDictionary))
        XCTAssertNil(metaInfo)
        
        metainfoDictionary = self.unEncodedMetaInfoWithInfoDictionary(singleFileInfoDictionary())
        let exampleInvalidField = [[Data(bytes: [255])]]
        metainfoDictionary.updateValue(exampleInvalidField as AnyObject, forKey: "announce-list")
        metaInfo = TorrentMetaInfo(data: metaInfoDictionaryWithDictionary(metainfoDictionary))
        XCTAssertNil(metaInfo)
    }
    
    // MARK: - Test info dictionary
    
    func testProducesCorrectCommonInfoDictionaryProperties() {
        let metaInfo = TorrentMetaInfo(data: self.exampleMetaInfoDictionary())!
        let info = metaInfo.info
        
        XCTAssertEqual(info.name, singleFileName)
        
        XCTAssertEqual(info.pieceLength, filePieceLength)
        
        let piecesConcatenated = info.pieces!.reduce(Data()) {
            (result: Data, item: Data) in
            return result.andData(item)
        }
        XCTAssertEqual(piecesConcatenated, createMultiplePieces())
    }
    
    func testIsPrivateIffPrivateKeyIsPresentAnd1() {
        var infoDictionary = singleFileInfoDictionary()
        
        infoDictionary.updateValue(1 as AnyObject, forKey: "private")
        var metainfo = TorrentMetaInfo(data: metaInfoDictionaryWithInfoDictionary(infoDictionary))!
        XCTAssertTrue(metainfo.info.isPrivate)
        
        infoDictionary.updateValue(0 as AnyObject, forKey: "private")
        metainfo = TorrentMetaInfo(data: metaInfoDictionaryWithInfoDictionary(infoDictionary))!
        XCTAssertFalse(metainfo.info.isPrivate)
        
        infoDictionary.removeValue(forKey: "private")
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
        
        
        infoDictionary.updateValue(singleFileMD5 as AnyObject, forKey: "md5sum")
        metaInfo = TorrentMetaInfo(data: metaInfoDictionaryWithInfoDictionary(infoDictionary))!
        file = metaInfo.info.files[0]

        XCTAssertEqual(file.md5sum, singleFileMD5)

    }
    
    func testInitializerReturnsNilOnInvalidInfoDictionaryForSingleFile() {
        
        var infoDictionary = singleFileInfoDictionary()
        infoDictionary.removeValue(forKey: "name")
        var metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))
        
        infoDictionary = singleFileInfoDictionary()
        infoDictionary.removeValue(forKey: "piece length")
        metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))
        
        infoDictionary = singleFileInfoDictionary()
        infoDictionary.removeValue(forKey: "pieces")
        metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))
        
        infoDictionary = singleFileInfoDictionary()
        let exampleData = Data(bytes: [1,2,3])
        infoDictionary.updateValue(exampleData as AnyObject, forKey: "pieces")
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
        
        
        infoDictionary.updateValue(multipleFile1MD5 as AnyObject, forKey: "md5sum")
        
        infoDictionary = multiFileInfoDictionary([
            [ "length" : multipleFileLength1 as AnyObject, "path" : multipleFilePath1 as AnyObject ],
            [ "length" : multipleFileLength2 as AnyObject, "path" : multipleFilePath2 as AnyObject ],
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
        infoDictionary.removeValue(forKey: "files")
        var metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))
        
        infoDictionary = multiFileInfoDictionary([
            [ "length" : multipleFileLength1 as AnyObject, "path" : multipleFilePath1 as AnyObject ],
            [ "length" : multipleFileLength2 as AnyObject ],
            ])
        metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))
        
        infoDictionary = multiFileInfoDictionary([
            [ "length" : multipleFileLength1 as AnyObject, "path" : multipleFilePath1 as AnyObject ],
            [ "path" : multipleFilePath2 as AnyObject ],
            ])
        metaInfoDictionary = metaInfoDictionaryWithInfoDictionary(infoDictionary)
        XCTAssertNil(TorrentMetaInfo(data: metaInfoDictionary))

    }
    
    
}
