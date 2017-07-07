//
//  TCPConnectionTests.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 07/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent

class TCPConnectionDelegateStub: TCPConnectionDelegate {
    
    var didConnectToHostCalled = false
    var didConnectToHostParameters: (sender: TCPConnection, host: String, port: UInt16)?
    func tcpConnection(_ sender: TCPConnection, didConnectToHost host: String, port: UInt16) {
        didConnectToHostCalled = true
        didConnectToHostParameters = (sender, host, port)
    }
    
    var didReadDataCalled = false
    var didReadDataParameters: (sender: TCPConnection, data: Data, tag: Int)?
    func tcpConnection(_ sender: TCPConnection, didRead data: Data, withTag tag: Int) {
        didReadDataCalled = true
        didReadDataParameters = (sender, data, tag)
    }
    
    var didWriteDataCalled = false
    var didWriteDataParameters: (sender: TCPConnection, tag: Int)?
    func tcpConnection(_ sender: TCPConnection, didWriteDataWithTag tag: Int) {
        didWriteDataCalled = true
        didWriteDataParameters = (sender, tag)
    }
    
    var disconnectedWithErrorCalled = false
    var disconnectedWithErrorParameters: (sender: TCPConnection, error: Error?)?
    func tcpConnection(_ sender: TCPConnection, disconnectedWithError error: Error?) {
        disconnectedWithErrorCalled = true
        disconnectedWithErrorParameters = (sender, error)
    }
}

class TCPConnectionTests: XCTestCase {
    
    var socket: GCDAsyncSocketStub!
    var delegateStub: TCPConnectionDelegateStub!
    var sut: TCPConnection!
    
    override func setUp() {
        super.setUp()
        
        delegateStub = TCPConnectionDelegateStub()
        socket = GCDAsyncSocketStub()
        sut = TCPConnection(socket: socket)
        sut.delegate = delegateStub
    }
    
    func test_isSocketDelegate() {
        XCTAssert(socket.delegate === sut)
        XCTAssert(socket.delegateQueue === DispatchQueue.main)
    }
    
    func test_canGetConnectedHostAndPort() {
        
        // Not sure how to test this as I cannot override stored properties in a stub
        
        // Potential solution:  Use a protocol instead of a subclass
        // Issue with solution: Cannot call delegate methods using this protocol as parameter
        //                      (delegate methods are defined as taking the concrete class)
        
        // For now just assert they are both nil
        XCTAssertNil(sut.connectedHost)
        XCTAssertNil(sut.connectedPort)
    }
    
    func test_canStartReadingData() {
        
        let timeout: TimeInterval = 123
        let tag = 456
        sut.readData(withTimeout: timeout, tag: tag)
        
        XCTAssert(socket.readDataCalled)
        XCTAssertEqual(socket.readDataParameters?.timeout, timeout)
        XCTAssertEqual(socket.readDataParameters?.tag, tag)
    }
    
    func test_canConnectToHost() {
        let host = "127.0.0.1"
        let port: UInt16 = 3475
        
        try? sut.connect(to: host, onPort: port)
        
        XCTAssert(socket.connectToHostCalled)
        XCTAssertEqual(socket.connectToHostParameters!.host, host)
        XCTAssertEqual(socket.connectToHostParameters!.port, port)
    }
    
    func test_canDisconnect() {
        sut.disconnect()
        
        XCTAssertNil(socket.delegate)
        XCTAssert(socket.disconnectCalled)
    }
    
    func test_canWriteData() {
        
        let data = Data(bytes: [3,2,1])
        let timeout: TimeInterval = 123
        let tag = 456
        
        sut.write(data, withTimeout: timeout, tag: tag)
        
        XCTAssert(socket.writeCalled)
        XCTAssertEqual(socket.writeParameters?.data, data)
        XCTAssertEqual(socket.writeParameters?.timeout, timeout)
        XCTAssertEqual(socket.writeParameters?.tag, tag)
    }
    
    func test_didConnectToHostPassedToDelegate() {
        let host = "127.0.0.1"
        let port: UInt16 = 123
        sut.socket(socket, didConnectToHost: host, port: port)
        
        XCTAssert(delegateStub.didConnectToHostCalled)
        XCTAssertEqual(delegateStub.didConnectToHostParameters?.sender, sut)
        XCTAssertEqual(delegateStub.didConnectToHostParameters?.host, host)
        XCTAssertEqual(delegateStub.didConnectToHostParameters?.port, port)
    }
    
    func test_didReadDataPassedToDelegate() {
        let data = Data(bytes: [3,2,1])
        let tag = 123
        sut.socket(socket, didRead: data, withTag: tag)
    }
    
    func test_didWriteDataPassedToDelegate() {
        let tag = 123
        sut.socket(socket, didWriteDataWithTag: tag)
        
        XCTAssert(delegateStub.didWriteDataCalled)
        XCTAssertEqual(delegateStub.didWriteDataParameters?.sender, sut)
        XCTAssertEqual(delegateStub.didWriteDataParameters?.tag, tag)
    }
    
    func test_disconnectedWithErrorPassedToDelegate() {
        enum MyError: Error, Equatable {
            case failure
            
            static func ==(_ lhs: MyError, rhs: MyError) -> Bool {
                return true
            }
        }
        
        let error = MyError.failure
        sut.socketDidDisconnect(socket, withError: error)
        XCTAssert(delegateStub.disconnectedWithErrorCalled)
        XCTAssertEqual(delegateStub.disconnectedWithErrorParameters?.sender, sut)
        XCTAssertEqual(delegateStub.disconnectedWithErrorParameters?.error as? MyError, error)
    }
}
