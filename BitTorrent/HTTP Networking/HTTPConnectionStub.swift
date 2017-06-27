//
//  HTTPConnectionStub.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 27/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation
@testable import BitTorrent

struct HTTPConnectionStubRequest {
    let url: URL
    let urlParameters: [String: String]?
    let completion: (HTTPResponse)->Void
}

class HTTPConnectionStub: BasicHTTPConnection {
    
    var previousRequests: [HTTPConnectionStubRequest] = []
    
    var lastRequest: HTTPConnectionStubRequest {
        return previousRequests.last!
    }
    
    func makeRequest(url: URL, urlParameters: [String: String]? = nil, completion: @escaping (HTTPResponse)->Void) {
        previousRequests.append(HTTPConnectionStubRequest(url: url,
                                                          urlParameters: urlParameters,
                                                          completion: completion))
    }
    
    // MARK: -
    
    func completeLastRequest(with response: HTTPResponse) {
        previousRequests.last!.completion(response)
    }
    
}
