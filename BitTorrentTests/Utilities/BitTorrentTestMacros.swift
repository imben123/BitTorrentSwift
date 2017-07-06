//
//  BEncodeTestMacros.swift
//  BEncode
//
//  Created by Ben Davis on 22/08/2016.
//  Copyright © 2016 bendavisapps. All rights reserved.
//

import XCTest

enum BEncoderTestError: Error {
    case InvalidType
}

public func XCTAssertEqual<T>(_ expression1: @autoclosure () throws -> [[T]],
                              _ expression2: @autoclosure () throws -> [[T]],
                              _ message: @autoclosure () -> String = "",
                              file: StaticString = #file,
                              line: UInt = #line) {
    let array1: [[T]] = try! expression1()
    let array2: [[T]] = try! expression2()
    XCTAssertEqual(array1.count, array2.count)
    for i in 0..<array1.count {
        let element1 = array1[i]
        let element2 = array2[i]
        
        XCTAssertEqual(element1, element2)
    }
}

public func XCTAssertEqual<T>(_ expression1: @autoclosure () throws -> [T],
                              _ expression2: @autoclosure () throws -> [T],
                              _ message: @autoclosure () -> String = "",
                              file: StaticString = #file,
                              line: UInt = #line) {
    let array1: [T] = try! expression1()
    let array2: [T] = try! expression2()
    XCTAssertEqual(array1.count, array2.count)
    for i in 0..<array1.count {
        let element1 = array1[i]
        let element2 = array2[i]
        
        if let element1 = element1 as? Int, let element2 = element2 as? Int {
            XCTAssertEqual(element1, element2)
        } else if let element1 = element1 as? String, let element2 = element2 as? String {
            XCTAssertEqual(element1, element2)
        } else if let element1 = element1 as? Data, let element2 = element2 as? Data {
            XCTAssertEqual(element1, element2)
        } else if let element1 = element1 as? [T], let element2 = element2 as? [T] {
            XCTAssertEqual(element1, element2)
        } else if let element1 = element1 as? [String:T], let element2 = element2 as? [String:T] {
            XCTAssertEqual(element1, element2)
        } else if let element1 = element1 as? [Data:T], let element2 = element2 as? [Data:T] {
            XCTAssertEqual(element1, element2)
        }
    }
}

public func XCTAssertEqual<T, E>(_ expression1: @autoclosure () throws -> [E: T],
                                 _ expression2: @autoclosure () throws -> [E: T],
                                 _ message: @autoclosure () -> String = "",
                                 file: StaticString = #file,
                                 line: UInt = #line) {
    let dictionary1: [E: T] = try! expression1()
    let dictionary2: [E: T] = try! expression2()
    XCTAssertEqual(dictionary1.count, dictionary2.count)
    
    let keys1 = [E](dictionary1.keys)
    let keys2 = [E](dictionary2.keys)
    XCTAssertEqual(keys1, keys2)
    
    for key in keys1 {
        let element1 = dictionary1[key]
        let element2 = dictionary2[key]
        
        if let element1 = element1 as? Int, let element2 = element2 as? Int {
            XCTAssertEqual(element1, element2)
        } else if let element1 = element1 as? String, let element2 = element2 as? String {
            XCTAssertEqual(element1, element2)
        } else if let element1 = element1 as? Data, let element2 = element2 as? Data {
            XCTAssertEqual(element1, element2)
        } else if let element1 = element1 as? [T], let element2 = element2 as? [T] {
            XCTAssertEqual(element1, element2)
        } else if let element1 = element1 as? [String:T], let element2 = element2 as? [String:T] {
            XCTAssertEqual(element1, element2)
        } else if let element1 = element1 as? [Data:T], let element2 = element2 as? [Data:T] {
            XCTAssertEqual(element1, element2)
        }
    }
}

fileprivate func XCTAssertEqual(_ element1: Any, element2: Any) throws {
    if let element1 = element1 as? Int, let element2 = element2 as? Int {
        XCTAssertEqual(element1, element2)
    } else if let element1 = element1 as? String, let element2 = element2 as? String {
        XCTAssertEqual(element1, element2)
    } else if let element1 = element1 as? Data, let element2 = element2 as? Data {
        XCTAssertEqual(element1, element2)
    } else if let element1 = element1 as? [Any], let element2 = element2 as? [Any] {
        XCTAssertEqual(element1, element2)
    } else if let element1 = element1 as? [String:Any], let element2 = element2 as? [String:Any] {
        XCTAssertEqual(element1, element2)
    } else if let element1 = element1 as? [Data:Any], let element2 = element2 as? [Data:Any] {
        XCTAssertEqual(element1, element2)
    } else {
        throw BEncoderTestError.InvalidType
    }
}
