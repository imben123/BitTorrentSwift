//
//  TorrentPeerCommunicator.swift
//  BitTorrent
//
//  Created by Ben Davis on 07/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

class TorrentPeerCommunicator {
    
    enum Message: UInt8 {
        case choke = 0
        case unchoke = 1
        case interested = 2
        case notInterested = 3
        case have = 4
        case bitfield = 5
        case request = 6
        case piece = 7
        case cancel = 8
        case port = 9
    }
    
    let defaultTimeout: TimeInterval = 10
    
    private let peerInfo: TorrentPeerInfo
    private let connection: TCPConnectionProtocol
    
    init(peerInfo: TorrentPeerInfo, tcpConnection: TCPConnectionProtocol = TCPConnection()) {
        self.peerInfo = peerInfo
        self.connection = tcpConnection
    }
    
    func connect() throws {
        try connection.connect(to: peerInfo.ip, onPort: peerInfo.port)
    }
    
    func sendHandshake(for infoHash: Data, clientId: Data) {
        
        let protocolString = "BitTorrent protocol"
        let protocolStringLength = UInt8(protocolString.count)
        
        let payload =
            protocolStringLength.toData() +         // pstrlen (Protocol string length)
            protocolString.data(using: .ascii)! +   // pstr (Protocol string)
            Data(bytes: [0,0,0,0,0,0,0,0]) +        // reserved (8 reserved bytes)
            infoHash +                              // info_hash
            clientId                                // peer_id of the current user
        
        connection.write(payload, withTimeout: defaultTimeout, tag: 0)
    }
    
    private let keepAlivePayload = Data(bytes: [0, 0, 0, 0]) // 0 length message
    
    func sendKeepAlive() {
        connection.write(keepAlivePayload, withTimeout: defaultTimeout, tag: 0)
    }
    
    func sendChoke() {
        let payload = makePayload(forMessage: .choke)
        connection.write(payload, withTimeout: defaultTimeout, tag: 0)
    }
    
    func sendUnchoke() {
        let payload = makePayload(forMessage: .unchoke)
        connection.write(payload, withTimeout: defaultTimeout, tag: 0)
    }
    
    func sendInterested() {
        let payload = makePayload(forMessage: .interested)
        connection.write(payload, withTimeout: defaultTimeout, tag: 0)
    }
    
    func sendNotInterested() {
        let payload = makePayload(forMessage: .notInterested)
        connection.write(payload, withTimeout: defaultTimeout, tag: 0)
    }
    
    func sendHavePiece(at index: Int) {
        let data = UInt32(index).toData()
        let payload = makePayload(forMessage: .have, data: data)
        connection.write(payload, withTimeout: defaultTimeout, tag: 0)
    }
    
    func sendBitField(_ bitField: BitField) {
        let data = bitField.toData()
        let payload = makePayload(forMessage: .bitfield, data: data)
        connection.write(payload, withTimeout: defaultTimeout, tag: 0)
    }
    
    func sendRequest(fromPieceAtIndex index: Int, begin: Int, length: Int) {
        let data = UInt32(index).toData() + UInt32(begin).toData() + UInt32(length).toData()
        let payload = makePayload(forMessage: .request, data: data)
        connection.write(payload, withTimeout: defaultTimeout, tag: 0)
    }
    
    func sendPiece(fromPieceAtIndex index: Int, begin: Int, block: Data) {
        let data = UInt32(index).toData() + UInt32(begin).toData() + block
        let payload = makePayload(forMessage: .piece, data: data)
        connection.write(payload, withTimeout: defaultTimeout, tag: 0)
    }
    
    func sendCancel(forPieceAtIndex index: Int, begin: Int, length: Int) {
        let data = UInt32(index).toData() + UInt32(begin).toData() + UInt32(length).toData()
        let payload = makePayload(forMessage: .cancel, data: data)
        connection.write(payload, withTimeout: defaultTimeout, tag: 0)
    }
    
    func sendPort(_ listenPort: UInt16) {
        // TODO: implement with DHT peer discovery
    }
    
    // MARK -
    
    func makePayload(forMessage message: Message, data: Data? = nil) -> Data {
        let data = data ?? Data()
        let length = UInt32(data.count + 1)
        return length.toData() + message.rawValue.toData() + data
    }
}
