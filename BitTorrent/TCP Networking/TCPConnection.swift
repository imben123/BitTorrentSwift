//
//  TCPConnection.swift
//  BitTorrent
//
//  Created by Ben Davis on 06/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

protocol TCPConnectionProtocol: class {
    weak var delegate: TCPConnectionDelegate? { set get }
    
    var connectedHost: String? { get }
    var connectedPort: UInt16? { get }
    
    func connect(to host: String, onPort port: UInt16) throws
    func disconnect()
    
    func readData(withTimeout timeout: TimeInterval, tag: Int)
    func write(_ data: Data, withTimeout timeout: TimeInterval, tag: Int)
}

protocol TCPConnectionDelegate: class {
    func tcpConnection(_ sender: TCPConnectionProtocol, didConnectToHost host: String, port: UInt16)
    func tcpConnection(_ sender: TCPConnectionProtocol, didRead data: Data, withTag tag: Int)
    func tcpConnection(_ sender: TCPConnectionProtocol, didWriteDataWithTag tag: Int)
    func tcpConnection(_ sender: TCPConnectionProtocol, disconnectedWithError error: Error?)
}

/// This class is a thin wrapper around the socket library to protect against changes
/// in its interface, and to allow me to replace CocoaAsyncSocket with a swift framework
/// one day.
class TCPConnection: NSObject, TCPConnectionProtocol {
    
    weak var delegate: TCPConnectionDelegate?
    
    private let socket: GCDAsyncSocket
    
    var connectedHost: String? {
        return socket.connectedHost
    }
    
    var connectedPort: UInt16? {
        guard connectedHost != nil else {
            return nil
        }
        return socket.connectedPort
    }
    
    init(socket: GCDAsyncSocket = GCDAsyncSocket()) {
        self.socket = socket
        super.init()
        socket.delegateQueue = .main
        socket.synchronouslySetDelegate(self)
    }
    
    func connect(to host: String, onPort port: UInt16) throws {
        try socket.connect(toHost: host, onPort: port)
    }
    
    func disconnect() {
        socket.delegate = nil
        socket.disconnect()
    }
    
    func readData(withTimeout timeout: TimeInterval, tag: Int) {
        socket.readData(withTimeout: timeout, tag: tag)
    }
    
    func write(_ data: Data, withTimeout timeout: TimeInterval, tag: Int) {
        socket.write(data, withTimeout: timeout, tag: tag)
    }
}

extension TCPConnection: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        delegate?.tcpConnection(self, didConnectToHost: host, port: port)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        delegate?.tcpConnection(self, didRead: data, withTag: tag)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        delegate?.tcpConnection(self, didWriteDataWithTag: tag)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        delegate?.tcpConnection(self, disconnectedWithError: err)
    }
}
