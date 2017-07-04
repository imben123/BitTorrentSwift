//
//  UDPConnection.swift
//  BitTorrent
//
//  Created by Ben Davis on 03/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

protocol UDPConnectionDelegate: class {
    func udpConnection(_ sender: UDPConnection, receivedData data: Data, fromHost host: String)
}

/// This class is a thin wrapper around the socket library to protect against changes
/// in its interface, and to allow me to replace CocoaAsyncSocket with a swift framework
/// one day.
class UDPConnection: NSObject {
    
    weak var delegate: UDPConnectionDelegate?
    
    private let socket: GCDAsyncUdpSocket
    
    // Designated init for testing
    init(socket: GCDAsyncUdpSocket) {
        self.socket = socket
        super.init()
        socket.setDelegate(self)
        socket.synchronouslySetDelegateQueue(.main)
    }
    
    // Useful init which should be used
    override convenience init() {
        self.init(socket: GCDAsyncUdpSocket())
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
        
        let hostString = ipAddress(fromSockAddrData: address)!
        delegate?.udpConnection(self, receivedData: data, fromHost: hostString)
    }
}
