//
//  BEncoderTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class BEncoderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Integers
    
    func testEncodeInteger() {
        doTestEncodeInteger(0)
        doTestEncodeInteger(1)
        doTestEncodeInteger(5)
        doTestEncodeInteger(123)
        doTestEncodeInteger(9999)
    }
    
    func doTestEncodeInteger(integer: Int) {
        let data = try! BEncoder.encode(integer)
        let string = NSString(data: data, encoding: NSASCIIStringEncoding)
        XCTAssertEqual(string, "i\(integer)e")
    }
    
    // MARK: - Byte Strings
    
    func testEncodeEmptyByteString() {
        let data = try! BEncoder.encode(NSData())
        let expectedResult = NSData(byteArray: [48, 58])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeByteString() {
        let byteString = NSData(byteArray: [ 1, 2, 3, 255, 0])
        let data = try! BEncoder.encode(byteString)
        let expectedResult = try! NSMutableData(data: Character("5").asciiValue())
            .andData(BEncoder.StringSizeDelimiterToken)
            .andData(byteString)
        XCTAssertEqual(data, expectedResult)
    }
    
    // MARK: - Strings
    
    func testEncodeEmptyString() {
        let data = try! BEncoder.encode("")
        let expectedResult = NSData(byteArray: [48, 58])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeString() {
        let data = try! BEncoder.encode("foobar")
        let expectedResult = NSData(byteArray: [54, 58, 102, 111, 111, 98, 97, 114])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeNonAsciiStringThrows() {
        assertExceptionThrown(BEncoderException.InvalidAscii) {
            let _ = try BEncoder.encode("🙂")
        }
    }
    
    // MARK: - Lists
    
    func testEncodeEmptyList() {
        let data = try! BEncoder.encode([])
        let expectedResult = NSData(byteArray: [108, 101])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeListWithOneObject() {
        let integer = 123
        let data = try! BEncoder.encode([integer])
        let expectedResult = NSData(byteArray: [108, 105, 49, 50, 51, 101, 101])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeSimpleList() {
        let exampleData = self.exampleListAndExpectedValues()
        let bEncodedData = try! BEncoder.encode(exampleData.list)
        let expectedResult = NSData(byteArray: exampleData.expectedValues)
        
        XCTAssertEqual(bEncodedData, expectedResult)
    }
    
    func testEncodeListWithNestedDictionary() {
        
        let input = [
            123,
            [ "foo": "bar" ],
            "baz"
        ]
        
        let expectedResultArray: [Byte] = [
            108,                    // l
            
            105, 49, 50, 51, 101,   // i123e
            
            100,                    // d
            51, 58, 102, 111, 111,  // 3:foo
            51, 58, 98,  97,  114,  // 3:bar
            101,                    // e
            
            51, 58, 98,  97,  122,  // 3:baz
            
            101                     // e
        ]
        
        let result = try! BEncoder.encode(input)
        let expectedResult = NSData(byteArray: expectedResultArray)
        XCTAssertEqual(result, expectedResult)
    }
    
    // MARK: - Dictionaries
    
    func testEncodeEmptyDictionary() {
        let data = try! BEncoder.encode(Dictionary<NSData, NSData>())
        let expectedResult = NSData(byteArray: [100, 101]) // de
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeDictionaryWithOneValue() {
        let data = try! BEncoder.encode([
            NSData(byteArray: [1]) : 1
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
    
    func testEncodeSimpleDictionary() {
        let exampleDictionary = exampleDictionaryAndExpectedValues()
        let bEncodedData = try! BEncoder.encode(exampleDictionary.dictionary)
        let expectedResult = NSData(byteArray: exampleDictionary.expectedValues)
        XCTAssertEqual(bEncodedData, expectedResult)
    }
    
    func testEncodeDictionaryWithStringKeys() {
        let bEncodedDataDictionary = [
            "foo" : "bar",
            "baz" : NSData(byteArray: [0,7,255]),
        ]
        
        var expectedResultArray: [Byte] = [100]                                 // d
        
        expectedResultArray.appendContentsOf([51, 58, 102, 111, 111])           // 3:foo
        expectedResultArray.appendContentsOf([51, 58, 98,  97,  114])           // 3:bar
        
        expectedResultArray.appendContentsOf([51, 58, 98,  97,  122])           // 3:baz
        expectedResultArray.appendContentsOf([51, 58, 0,   7,   255])           // 3:\0x00\0x07\0xFF
        
        expectedResultArray.append(101)                                         // e
        
        let bEncodedData = try! BEncoder.encode(bEncodedDataDictionary)
        let expectedResult = NSData(byteArray: expectedResultArray)
        XCTAssertEqual(bEncodedData, expectedResult)
    }
    
    func testEncodeDictionaryWithNonAsciiStringKeysThrows() {
        
        let bEncodedDataDictionary = [
            "🙂"  : try! BEncoder.encode("bar"),
            "baz" : try! BEncoder.encode(NSData(byteArray: [0,7,255])),
        ]
        
        assertExceptionThrown(BEncoderException.InvalidAscii) {
            try BEncoder.encodeDictionary(bEncodedDataDictionary)
        }

    }
    
    func testEncodeDictionaryWithList() {
        
        // Order is not maintained by dictionary so this test can fail due to order change
        
        let exampleList = self.exampleListAndExpectedValues()
        let exampleDictionary = self.exampleDictionaryAndExpectedValues()
        
        let bEncodedDataDictionary = [
            NSData(byteArray: [1])                  : 1,
            try! "foo".asciiValue()                 : "bar",
            try! "baz".asciiValue()                 : NSData(byteArray: [0,7,255]),
            NSData(byteArray: [0])                  : exampleList.list,
            NSData(byteArray: [255, 255, 255, 255]) : exampleDictionary.dictionary
        ]
        
        var expectedResultArray: [Byte] = [100]                                 // d
        
        expectedResultArray.appendContentsOf([51, 58, 98,  97,  122])           // 3:baz
        expectedResultArray.appendContentsOf([51, 58, 0,   7,   255])           // 3:\0x00\0x07\0xFF
        
        expectedResultArray.appendContentsOf([52, 58, 255, 255, 255, 255])      // 4:\0xFF\0xFF\0xFF\0xFF
        expectedResultArray.appendContentsOf(exampleDictionary.expectedValues)  // <bEncoded values>
        
        expectedResultArray.appendContentsOf([49, 58, 0])                       // 1:\0x0
        expectedResultArray.appendContentsOf(exampleList.expectedValues)        // <bEncoded values>
        
        expectedResultArray.appendContentsOf([49, 58, 1])                       // 1:\0x1
        expectedResultArray.appendContentsOf([105, 49, 101])                    // i1e
        
        expectedResultArray.appendContentsOf([51, 58, 102, 111, 111])           // 3:foo
        expectedResultArray.appendContentsOf([51, 58, 98,  97,  114])           // 3:bar
        
        expectedResultArray.append(101)                                         // e
        
        let bEncodedData = try! BEncoder.encode(bEncodedDataDictionary)
        let expectedResult = NSData(byteArray: expectedResultArray)
        XCTAssertEqual(bEncodedData, expectedResult)
    }
    
    func testEncodeDictionaryWithListAndStringKeys() {
        let input = [
            "hello": ["world", 123],
            "foo": "bar",
            "baz": 123,
        ]
        
        
        let expectedResultArray: [Byte] = [
            100,                              // d
            
            53, 58, 104, 101, 108, 108, 111,  // 5:hello
            108,                              // l
            53, 58, 119, 111, 114, 108, 100,  // 5:world
            105, 49, 50, 51, 101,             // i123e
            101,                              // e
            
            51, 58, 102, 111, 111,            // 3:foo
            51, 58, 98,  97,  114,            // 3:bar
            
            51, 58, 98,  97,  122,            // 3:baz
            105, 49, 50, 51, 101,             // i123e
            
            101                               // e
        ]
        
        let result = try! BEncoder.encode(input)
        let expectedData = NSData(byteArray: expectedResultArray)
        XCTAssertEqual(result, expectedData)
    }

    // MARK: - Example inputs
    
    private func exampleListAndExpectedValues() -> (list: [AnyObject], expectedValues: [Byte]) {
        
        let bEncodedDataArray = [
            123,
            0,
            999,
            "foobar",
            "999",
            NSData(byteArray: [0, 1, 2, 3, 255])
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
        
        return (bEncodedDataArray, expectedResultArray)
    }
    
    private func exampleDictionaryAndExpectedValues() -> (dictionary: [NSData:AnyObject], expectedValues: [Byte]) {
        
        // Order is not maintained by dictionary so this test can fail due to order change
        
        let bEncodedDataDictionary = [
            NSData(byteArray: [1])                  : 1,
            try! "baz".asciiValue()                 : NSData(byteArray: [0,7,255]),
            try! "foo".asciiValue()                 : "bar",
        ]
        
        let expectedResultArray: [Byte] = [
            100,                    // d
            
            51, 58, 98,  97,  122,  // 3:baz
            51, 58, 0,   7,   255,  // 3:\0x00\0x07\0xFF
            
            49, 58, 1,              // 1:\0x1
            105, 49, 101,           // i1e
            
            51, 58, 102, 111, 111,  // 3:foo
            51, 58, 98,  97,  114,  // 3:bar
            
            101                     // e
        ]
        
        return (bEncodedDataDictionary, expectedResultArray)
    }
    
    // MARK: - 
    
    func testExceptionThrownIfTryToEncodeObjectNotRepresentableInBEncode() {
        assertExceptionThrown(BEncoderException.UnrepresentableObject) {
            let _ = try BEncoder.encode(UIView())
        }
    }
    
}