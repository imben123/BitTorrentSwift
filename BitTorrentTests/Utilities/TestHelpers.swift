//
//  TestHelpers.swift
//  BitTorrent
//
//  Created by Ben Davis on 28/02/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest

func assertExceptionThrown(_ exception: Error?, dangerCode: ()throws->()) {
    var exceptionThrown = false
    do {
        try dangerCode()
    } catch let e {
        if let exception = exception,
            type(of: e) != type(of: exception) {
                XCTFail("Expected an exception of type \(exception) but got exception of type \(e)")
        }
        exceptionThrown = true
    }
    XCTAssert(exceptionThrown, "Exception not thrown")
}
