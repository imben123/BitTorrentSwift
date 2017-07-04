//
//  GCDAsyncUdpSocketProtocol.swift
//  BitTorrent
//
//  Created by Ben Davis on 04/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class GCDAsyncUdpSocketStub: GCDAsyncUdpSocket {
    
    weak var _delegate: GCDAsyncUdpSocketDelegate?
    
    override func delegate() -> GCDAsyncUdpSocketDelegate? {
        return _delegate
    }
    
    override func setDelegate(_ delegate: GCDAsyncUdpSocketDelegate?) {
        _delegate = delegate
    }
    
    var bindToPortCalled = false
    var bindToPortParameter: UInt16?
    override func bind(toPort port: UInt16) throws {
        bindToPortCalled = true
        bindToPortParameter = port
    }
    
    var beginReceivingCalled = false
    override func beginReceiving() throws {
        beginReceivingCalled = true
    }
    
    var _delegateQueue: DispatchQueue?
    
    override func delegateQueue() -> DispatchQueue? {
        return _delegateQueue
    }
    
    override func synchronouslySetDelegateQueue(_ delegateQueue: DispatchQueue?) {
        _delegateQueue = delegateQueue
    }
    
    var closeCalled = false
    override func close() {
        closeCalled = true
    }
    
    var sendCalled = false
    var sendParameters: (data: Data, host: String, port: UInt16, timeout: TimeInterval, tag: Int)?
    override func send(_ data: Data, toHost host: String, port: UInt16, withTimeout timeout: TimeInterval, tag: Int) {
        sendCalled = true
        sendParameters = (data, host, port, timeout, tag)
    }
}

