//
//  TCPConnectionStub.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 07/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation
@testable import BitTorrent

class TCPConnectionStub: TCPConnectionProtocol {
    
    weak var delegate: TCPConnectionDelegate?
    
    var connectedHost: String?
    var connectedPort: UInt16?
    var connected: Bool = false
    
    var connectCalled = false
    var connectParameters: (host: String, port: UInt16)?
    func connect(to host: String, onPort port: UInt16) throws {
        connectCalled = true
        connectParameters = (host, port)
    }
    
    var disconnectCalled = false
    func disconnect() {
        disconnectCalled = true
    }
    
    var readDataCalled = false
    var readDataParameters: (timeout: TimeInterval, tag: Int)?
    func readData(withTimeout timeout: TimeInterval, tag: Int) {
        readDataCalled = true
        readDataParameters = (timeout, tag)
    }
    
    var writeDataCalled = false
    var writeDataParameters: (data: Data, timeout: TimeInterval, tag: Int?)?
    
    func write(_ data: Data, withTimeout timeout: TimeInterval, tag: Int) {
        writeDataCalled = true
        writeDataParameters = (data, timeout, tag)
    }
    
    func write(_ data: Data, withTimeout timeout: TimeInterval, completion: (() -> Void)?) {
        writeDataCalled = true
        writeDataParameters = (data, timeout, nil)
    }
    
}
