//
//  TorrentServer.swift
//  BitTorrent
//
//  Created by Ben Davis on 29/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

protocol TorrentServerDelegate: class {
    func torrentServer(_ torrentServer: TorrentServer, connectedToPeer peer: TorrentPeer)
    func currentProgress(for torrentServer: TorrentServer) -> BitField
}

class TorrentServer: NSObject, GCDAsyncSocketDelegate {
    
    weak var delegate: TorrentServerDelegate?
    var listenSocket: GCDAsyncSocket!
    let infoHash: Data
    let clientId: Data
    let port: UInt16 = 6881
    
    init(infoHash: Data, clientId: Data) {
        self.infoHash = infoHash
        self.clientId = clientId
        super.init()
        self.listenSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
    }
    
    deinit {
        listenSocket.delegate = nil
        listenSocket.disconnect()
    }
    
    func startListening() {
        do {
            try listenSocket.accept(onPort: port)
        } catch _ {
            print("Couldn't listen on port to accept incoming peers")
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        guard let delegate = self.delegate else { return }
        let peerInfo = TorrentPeerInfo(ip: newSocket.connectedHost!, port: newSocket.connectedPort, peerId: nil)
        let tcpConnection = TCPConnection(socket: newSocket)
        let communicator = TorrentPeerCommunicator(peerInfo: peerInfo, infoHash: infoHash, tcpConnection: tcpConnection)
        let currentProgress = delegate.currentProgress(for: self)
        let peer = TorrentPeer(peerInfo: peerInfo, bitFieldSize: currentProgress.size, communicator: communicator)
        peer.enableLogging = true
        try! peer.connect(withHandshakeData: (clientId: clientId, bitField: currentProgress))
        delegate.torrentServer(self, connectedToPeer: peer)
    }
}
