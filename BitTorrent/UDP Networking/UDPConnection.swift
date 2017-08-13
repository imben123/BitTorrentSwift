//
//  UDPConnection.swift
//  BitTorrent
//
//  Created by Ben Davis on 03/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

protocol UDPConnectionProtocol: class {
    var port: UInt16 { get }
    weak var delegate: UDPConnectionDelegate? { set get }
    func startListening(on port: UInt16)
    func send(_ data: Data, toHost host: String, port: UInt16, timeout: TimeInterval)
}

protocol UDPConnectionDelegate: class {
    func udpConnection(_ sender: UDPConnectionProtocol, receivedData data: Data, fromHost host: String)
}

/// This class is a thin wrapper around the socket library to protect against changes
/// in its interface, and to allow me to replace CocoaAsyncSocket with a swift framework
/// one day.
class UDPConnection: NSObject, UDPConnectionProtocol {
    
    var port: UInt16 {
        return socket.localPort()
    }
    
    weak var delegate: UDPConnectionDelegate?
    
    private let socket: GCDAsyncUdpSocket
    
    init(socket: GCDAsyncUdpSocket = GCDAsyncUdpSocket()) {
        self.socket = socket
        super.init()
        socket.setDelegate(self)
        socket.synchronouslySetDelegateQueue(.main)
    }
    
    deinit {
        socket.close()
    }
    
    func startListening(on port: UInt16) {
        try? socket.bind(toPort: port)
        try? socket.beginReceiving()
    }
    
    func send(_ data: Data, toHost host: String, port: UInt16, timeout: TimeInterval) {
        socket.send(data, toHost: host, port: port, withTimeout: timeout, tag: 0)
    }
}

extension UDPConnection: GCDAsyncUdpSocketDelegate {
    
    func udpSocket(_ sock: GCDAsyncUdpSocket,
                   didReceive data: Data,
                   fromAddress address: Data,
                   withFilterContext filterContext: Any?) {
        
        let hostString = InternetProtocol.ipAddress(fromSockAddrData: address)!
        delegate?.udpConnection(self, receivedData: data, fromHost: hostString)
    }
}
