//
//  HTTPConnectionTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 27/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import BitTorrent

class HTTPConnectionTests: XCTestCase {
    
    let host = "test.com"
    let url = URL(string: "https://test.com")!
    let urlParameters = ["foo": "bar", "hello": "world!"]
    let statusCode: Int32 = 123
    let responseData = Data(bytes: [1,2,3,4])
    
    var connection: HTTPConnection!
    
    override func setUp() {
        super.setUp()
        
        OHHTTPStubs.stubRequests(passingTest: { [weak self] request -> Bool in
            
            guard let host = self?.host, let urlParameters = self?.urlParameters else {
                return false
            }
            
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            let urlParametersInRequest: [String: String]
                
            if let queryItems = components.queryItems {
                let elements = queryItems.map({ ($0.name, $0.value) })
                urlParametersInRequest = Dictionary(uniqueKeysWithValues: elements) as! [String : String]
            } else {
                urlParametersInRequest = [:]
            }
            
            return (components.host == host && urlParametersInRequest == urlParameters)
            
        }, withStubResponse: { [weak self] request -> OHHTTPStubsResponse in
            
            OHHTTPStubsResponse(data: self!.responseData,
                                statusCode: self!.statusCode,
                                headers: nil)
        })
        
        connection = HTTPConnection()
    }
    
    func test_failedRequest() {
        
        let expectation = self.expectation(description: "Completion closure invoked")
        
        connection.makeRequest(url: URL(string: "other.com")!) { response in
            XCTAssertFalse(response.completed)
            XCTAssertNil(response.responseData)
            XCTAssertEqual(response.statusCode , 0)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_canMakeRequest() {
        
        let expectation = self.expectation(description: "Completion closure invoked")
        
        connection.makeRequest(url: url, urlParameters: urlParameters) { response in
            XCTAssert(response.completed)
            XCTAssertEqual(response.responseData, self.responseData)
            XCTAssertEqual(response.statusCode, Int(self.statusCode))
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
}
