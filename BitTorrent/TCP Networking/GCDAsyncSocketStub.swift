//
//  GCDAsyncSocketStub.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 07/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class GCDAsyncSocketStub: GCDAsyncSocket {
    
    var connectToHostCalled = false
    var connectToHostParameters: (host: String, port: UInt16, timeout: TimeInterval)?
    override func connect(toHost host: String, onPort port: UInt16, withTimeout timeout: TimeInterval) throws {
        connectToHostCalled = true
        connectToHostParameters = (host, port, timeout)
    }
    
    var readDataCalled = false
    var readDataParameters: (timeout: TimeInterval, tag: Int)?
    override func readData(withTimeout timeout: TimeInterval, tag: Int) {
        readDataCalled = true
        readDataParameters = (timeout, tag)
    }
    
    var disconnectCalled = false
    override func disconnect() {
        disconnectCalled = true
    }
    
    var writeCalled = false
    var writeParameters: (data: Data, timeout: TimeInterval, tag: Int)?
    override func write(_ data: Data, withTimeout timeout: TimeInterval, tag: Int) {
        writeCalled = true
        writeParameters = (data, timeout, tag)
    }
}
