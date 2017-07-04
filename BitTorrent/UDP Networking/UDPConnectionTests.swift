//
//  UDPConnectionTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 03/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
import CocoaAsyncSocket
@testable import BitTorrent

class UDPConnectionDelegateTestingStub: UDPConnectionDelegate {
    
    var receivedDataCalled = false
    var receivedDataParameters: (sender: UDPConnection, data: Data, host: String)?
    func udpConnection(_ sender: UDPConnection, receivedData data: Data, fromHost host: String) {
        receivedDataCalled = true
        receivedDataParameters = (sender, data, host)
    }
}

class UDPConnectionTests: XCTestCase {
    
    var socket: GCDAsyncUdpSocketStub!
    var delegate: UDPConnectionDelegateTestingStub!
    var sut: UDPConnection!
    
    override func setUp() {
        super.setUp()
        
        socket = GCDAsyncUdpSocketStub()
        delegate = UDPConnectionDelegateTestingStub()
        sut = UDPConnection(socket: socket)
        sut.delegate = delegate
    }
    
    func test_isSocketDelegate() {
        XCTAssert(socket._delegate === sut)
        XCTAssert(socket._delegateQueue === DispatchQueue.main)
    }
    
    func test_canStartListeningOnPort() {
        
        let port: UInt16 = 123
        sut.startListening(on: port)
        
        XCTAssert(socket.bindToPortCalled)
        XCTAssertEqual(socket.bindToPortParameter, port)
        XCTAssert(socket.beginReceivingCalled)
    }
    
    func test_socketClosedOnDeinit() {
        sut = nil
        XCTAssert(socket.closeCalled)
    }
    
    // MARK: - Receiving data
    
    func test_canRecieveData() {
        
        // 127.0.0.1:27002
        let addressData = Data(bytes: [16,2,122,105,127,0,0,1,0,0,0,0,0,0,0,0])
        let packetData = Data(bytes: [1,2,3])
        
        sut.udpSocket(socket, didReceive: packetData, fromAddress: addressData, withFilterContext: nil)
        
        XCTAssert(delegate.receivedDataCalled)
        XCTAssertEqual(delegate.receivedDataParameters?.sender, sut)
        XCTAssertEqual(delegate.receivedDataParameters?.data, packetData)
        XCTAssertEqual(delegate.receivedDataParameters?.host, "127.0.0.1")
    }
    
    // MARK: - Sending data
    
    func test_canSendData() {
        
        let data = Data(bytes: [1,2,3])
        let host = "127.0.0.1"
        let port: UInt16 = 3475
        let timeout: TimeInterval = 10
        
        sut.send(data, toHost: host, port: port, timeout: timeout)
        
        XCTAssert(socket.sendCalled)
        XCTAssertEqual(socket.sendParameters!.data, data)
        XCTAssertEqual(socket.sendParameters!.host, host)
        XCTAssertEqual(socket.sendParameters!.port, port)
        XCTAssertEqual(socket.sendParameters!.timeout, timeout)
    }
}

