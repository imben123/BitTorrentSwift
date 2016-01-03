//
//  BencodeTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class BencodeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEncodeInteger() {
        doTestEncodeInteger(0)
        doTestEncodeInteger(1)
        doTestEncodeInteger(05)
        doTestEncodeInteger(123)
        doTestEncodeInteger(9999)
    }
    
    func doTestEncodeInteger(integer: Int) {
        let data = Bencode.encodeInteger(integer)
        let string = NSString(data: data, encoding: NSASCIIStringEncoding)
        XCTAssertEqual(string, "i\(integer)e")
    }
    
    func testEncodeBytes() {
        let byteString = NSData(byteArray: [ 1, 2, 3, 255, 0])
        let data = Bencode.encodeByteString(byteString)
        let expectedResult = try! NSMutableData(data: Character("5").asciiValue())
            .andData(Bencode.StringSizeDelimiter)
            .andData(byteString)
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeString() {
        let data = Bencode.encodeString("foobar")
        let expectedResult = NSData(byteArray: [54, 58, 102, 111, 111, 98, 97, 114])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeEmptyString() {
        let data = Bencode.encodeString("")
        let expectedResult = NSData(byteArray: [48, 58])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEmptyList() {
        let data = Bencode.encodeList([])
        let expectedResult = NSData(byteArray: [108, 101])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testListWithBencodedObject() {
        let bencodedInteger = Bencode.encodeInteger(123)
        let data = Bencode.encodeList([bencodedInteger])
        let expectedResult = NSData(byteArray: [108, 105, 49, 50, 51, 101, 101])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testListWithMultipleBencodedObjects() {
        
        let exampleData = self.exampleListAndExpectedValues()
        let bencodedData = Bencode.encodeList(exampleData.list)
        let expectedResult = NSData(byteArray: exampleData.expectedValues)

        XCTAssertEqual(bencodedData, expectedResult)
    }
    
    private func exampleListAndExpectedValues() -> (list: [NSData], expectedValues: [Byte]) {
        
        let bencodedDataArray = [
            Bencode.encodeInteger(123),
            Bencode.encodeInteger(0),
            Bencode.encodeInteger(999),
            Bencode.encodeString("foobar"),
            Bencode.encodeString("999"),
            Bencode.encodeByteString(NSData(byteArray: [0, 1, 2, 3, 255]))
        ]
        
        let expectedResultArray: [Byte] = [
            108,                                // l
            105, 49, 50, 51, 101,               // i123e
            105, 48, 101,                       // i0e
            105, 57, 57, 57, 101,               // i999e
            54, 58, 102, 111, 111, 98, 97, 114, // 6:foobar
            51, 58, 57, 57, 57,                 // 3:999
            53, 58, 0, 1, 2, 3, 255,            // 5:\0x00\0x01\0x02\0x03\0xFF
            101                                 // e
        ]
        
        return (bencodedDataArray, expectedResultArray)
    }
    
    func testEncodeEmptyDictionary() {
        let data = Bencode.encodeDictionary([:])
        let expectedResult = NSData(byteArray: [100, 101]) // de
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeDictionaryWithOneValue() {
        let data = Bencode.encodeDictionary([
            NSData(byteArray: [1]) : Bencode.encodeInteger(1)
            ])
        let expectedResult = NSData(byteArray:
            [
                100,            // d
                49, 58, 1,      // 1:\0x1
                105, 49, 101,   // i1e
                101             // e
            ])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testSimpleDictionary() {
        let exampleDictionary = exampleDictionaryAndExpectedValues()
        let bencodedData = Bencode.encodeDictionary(exampleDictionary.dictionary)
        let expectedResult = NSData(byteArray: exampleDictionary.expectedValues)
        XCTAssertEqual(bencodedData, expectedResult)
    }
    
    func exampleDictionaryAndExpectedValues() -> (dictionary: [NSData:NSData], expectedValues: [Byte]) {
        
        // Order is not maintained by dictionary so this test can fail due to order change
        
        let bencodedDataDictionary = [
            NSData(byteArray: [1])                  : Bencode.encodeInteger(1),
            "foo".asciiValue()                      : Bencode.encodeString("bar"),
            "baz".asciiValue()                      : Bencode.encodeByteString(NSData(byteArray: [0,7,255])),
        ]
        
        let expectedResultArray: [Byte] = [
            100, // d
            
            51, 58, 98,  97,  122,  // 3:baz
            51, 58, 0,   7,   255,  // 3:\0x00\0x07\0xFF
            
            49, 58, 1,      // 1:\0x1
            105, 49, 101,   // i1e
            
            51, 58, 102, 111, 111,      // 3:foo
            51, 58, 98,  97,  114,   // 3:bar
            
            101             // e
        ]
        
        return (bencodedDataDictionary, expectedResultArray)
    }
    
    func testEncodeDictionaryWithAllTypes() {
        
        let exampleList = self.exampleListAndExpectedValues()
        let exampleDictionary = self.exampleDictionaryAndExpectedValues()

        let bencodedDataDictionary = [
            NSData(byteArray: [1])                  : Bencode.encodeInteger(1),
            "foo".asciiValue()                      : Bencode.encodeString("bar"),
            "baz".asciiValue()                      : Bencode.encodeByteString(NSData(byteArray: [0,7,255])),
            NSData(byteArray: [0])                  : Bencode.encodeList(exampleList.list),
            NSData(byteArray: [255, 255, 255, 255]) : Bencode.encodeDictionary(exampleDictionary.dictionary)
        ]
        
        var expectedResultArray: [Byte] = [100]                                 // d
        
        expectedResultArray.appendContentsOf([51, 58, 98,  97,  122])           // 3:baz
        expectedResultArray.appendContentsOf([51, 58, 0,   7,   255])           // 3:\0x00\0x07\0xFF

        expectedResultArray.appendContentsOf([52, 58, 255, 255, 255, 255])      // 4:\0xFF\0xFF\0xFF\0xFF
        expectedResultArray.appendContentsOf(exampleDictionary.expectedValues)  // <bencoded values>

        expectedResultArray.appendContentsOf([49, 58, 0])                       // 1:\0x0
        expectedResultArray.appendContentsOf(exampleList.expectedValues)        // <bencoded values>

        expectedResultArray.appendContentsOf([49, 58, 1])                       // 1:\0x1
        expectedResultArray.appendContentsOf([105, 49, 101])                    // i1e
        
        expectedResultArray.appendContentsOf([51, 58, 102, 111, 111])           // 3:foo
        expectedResultArray.appendContentsOf([51, 58, 98,  97,  114])           // 3:bar
        
        expectedResultArray.append(101)                                         // e
        
        let bencodedData = Bencode.encodeDictionary(bencodedDataDictionary)
        let expectedResult = NSData(byteArray: expectedResultArray)
        XCTAssertEqual(bencodedData, expectedResult)
        
    }
}