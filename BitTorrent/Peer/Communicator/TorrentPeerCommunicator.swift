//
//  TorrentPeerCommunicator.swift
//  BitTorrent
//
//  Created by Ben Davis on 07/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

protocol TorrentPeerCommunicatorDelegate: class {
    func peerConnected(_ sender: TorrentPeerCommunicator)
    func peerLost(_ sender: TorrentPeerCommunicator)
    
    func peerSentHandshake(_ sender: TorrentPeerCommunicator, sentHandshakeWithPeerId peerId: Data, onDHT: Bool)
    func peerSentKeepAlive(_ sender: TorrentPeerCommunicator)
    func peerBecameChoked(_ sender: TorrentPeerCommunicator)
    func peerBecameUnchoked(_ sender: TorrentPeerCommunicator)
    func peerBecameInterested(_ sender: TorrentPeerCommunicator)
    func peerBecameUninterested(_ sender: TorrentPeerCommunicator)
    func peer(_ sender: TorrentPeerCommunicator, hasPiece piece: Int)
    func peer(_ sender: TorrentPeerCommunicator, hasBitField bitField: BitField)
    func peer(_ sender: TorrentPeerCommunicator, requestedPiece index: Int, begin: Int, length: Int)
    func peer(_ sender: TorrentPeerCommunicator, sentPiece index: Int, begin: Int, block: Data)
    func peer(_ sender: TorrentPeerCommunicator, cancelledRequestedPiece index: Int, begin: Int, length: Int)
    func peer(_ sender: TorrentPeerCommunicator, onDHTPort port:Int)
    
    func peerSentMalformedMessage(_ sender: TorrentPeerCommunicator)
}

/// Responsible for sending and recieving messages in the Peer Wire Protocol
class TorrentPeerCommunicator {
    
    var enableLogging = false
    
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
        
        var stringValue: String {
            switch self {
            case .choke:
                return "choke"
            case .unchoke:
                return "unchoke"
            case .interested:
                return "interested"
            case .notInterested:
                return "notInterested"
            case .have:
                return "have"
            case .bitfield:
                return "bitfield"
            case .request:
                return "request"
            case .piece:
                return "piece"
            case .cancel:
                return "cancel"
            case .port:
                return "port"
            }
        }
    }
    
    let defaultTimeout: TimeInterval = 10
    
    weak var delegate: TorrentPeerCommunicatorDelegate?
    
    private let peerInfo: TorrentPeerInfo
    private let connection: TCPConnectionProtocol
    
    fileprivate let infoHash: Data
    
    fileprivate var handshakeReceived = false
    fileprivate let handshakeMessageBuffer: TorrentPeerHandshakeMessageBuffer
    fileprivate let messageBuffer: TorrentPeerMessageBuffer
    
    init(peerInfo: TorrentPeerInfo, infoHash: Data, tcpConnection: TCPConnectionProtocol = TCPConnection()) {
        self.peerInfo = peerInfo
        self.connection = tcpConnection
        self.infoHash = infoHash
        self.handshakeMessageBuffer = TorrentPeerHandshakeMessageBuffer(infoHash: infoHash, peerId: peerInfo.peerId)
        self.messageBuffer = TorrentPeerMessageBuffer()
        
        self.connection.delegate = self
        self.handshakeMessageBuffer.delegate = self
        self.messageBuffer.delegate = self
        
        self.connection.readData(withTimeout: -1, tag: 0)
    }
    
    func connect() throws {
        try connection.connect(to: peerInfo.ip, onPort: peerInfo.port)
    }
    
    // MARK: - Writing messages

    func sendHandshake(for clientId: Data, _ completion: (()->Void)? = nil) {
        
        if enableLogging { print("Send handshake") }
        
        let protocolString = "BitTorrent protocol"
        let protocolStringLength = UInt8(protocolString.count)
        
        let payload =
            protocolStringLength.toData() +         // pstrlen (Protocol string length)
            protocolString.data(using: .ascii)! +   // pstr (Protocol string)
            Data(bytes: [0,0,0,0,0,0,0,0]) +        // reserved (8 reserved bytes)
            infoHash +                              // info_hash
            clientId                                // peer_id of the current user
        
        connection.write(payload, withTimeout: defaultTimeout, completion: completion)
    }
    
    func sendKeepAlive(_ completion: (()->Void)? = nil) {
        
        if enableLogging { print("sendKeepAlive") }
        
        let keepAlivePayload = Data(bytes: [0, 0, 0, 0]) // 0 length message
        connection.write(keepAlivePayload, withTimeout: defaultTimeout, completion: completion)
    }
    
    func sendChoke(_ completion: (()->Void)? = nil) {
        
        if enableLogging { print("Send choke") }
        
        let payload = makePayload(forMessage: .choke)
        connection.write(payload, withTimeout: defaultTimeout, completion: completion)
    }
    
    func sendUnchoke(_ completion: (()->Void)? = nil) {
        
        if enableLogging { print("Send Unchoke") }
        
        let payload = makePayload(forMessage: .unchoke)
        connection.write(payload, withTimeout: defaultTimeout, completion: completion)
    }
    
    func sendInterested(_ completion: (()->Void)? = nil) {
        
        if enableLogging { print("Send Interested") }
        
        let payload = makePayload(forMessage: .interested)
        connection.write(payload, withTimeout: defaultTimeout, completion: completion)
    }
    
    func sendNotInterested(_ completion: (()->Void)? = nil) {
        
        if enableLogging { print("Send not interested") }
        
        let payload = makePayload(forMessage: .notInterested)
        connection.write(payload, withTimeout: defaultTimeout, completion: completion)
    }
    
    func sendHavePiece(at index: Int, _ completion: (()->Void)? = nil) {
        
        if enableLogging { print("Send have piece") }
        
        let data = UInt32(index).toData()
        let payload = makePayload(forMessage: .have, data: data)
        connection.write(payload, withTimeout: defaultTimeout, completion: completion)
    }
    
    func sendBitField(_ bitField: BitField, _ completion: (()->Void)? = nil) {
        
        if enableLogging { print("Send Bit Field") }
        
        let data = bitField.toData()
        let payload = makePayload(forMessage: .bitfield, data: data)
        connection.write(payload, withTimeout: defaultTimeout, completion: completion)
    }
    
    func sendRequest(fromPieceAtIndex index: Int, begin: Int, length: Int, _ completion: (()->Void)? = nil) {
        
        if enableLogging { print("Send Request for piece at index: \(index) begin: \(begin)") }
        
        let data = UInt32(index).toData() + UInt32(begin).toData() + UInt32(length).toData()
        let payload = makePayload(forMessage: .request, data: data)
        connection.write(payload, withTimeout: defaultTimeout, completion: completion)
    }
    
    func sendPiece(fromPieceAtIndex index: Int, begin: Int, block: Data, _ completion: (()->Void)? = nil) {
        
        if enableLogging { print("Send Piece index: \(index) begin: \(begin)") }
        
        let data = UInt32(index).toData() + UInt32(begin).toData() + block
        let payload = makePayload(forMessage: .piece, data: data)
        connection.write(payload, withTimeout: defaultTimeout, completion: completion)
    }
    
    func sendCancel(forPieceAtIndex index: Int, begin: Int, length: Int, _ completion: (()->Void)? = nil) {
        
        if enableLogging { print("Send Cancel for piece at index: \(index) begin: \(begin)") }
        
        let data = UInt32(index).toData() + UInt32(begin).toData() + UInt32(length).toData()
        let payload = makePayload(forMessage: .cancel, data: data)
        connection.write(payload, withTimeout: defaultTimeout, completion: completion)
    }
    
    func sendPort(_ listenPort: UInt16, _ completion: (()->Void)? = nil) {
        // TODO: implement with DHT peer discovery
    }
    
    // MARK -
    
    func makePayload(forMessage message: Message, data: Data? = nil) -> Data {
        let data = data ?? Data()
        let length = UInt32(data.count + 1)
        return length.toData() + message.rawValue.toData() + data
    }
}

// MARK: - Reading messages

extension TorrentPeerCommunicator: TCPConnectionDelegate {
    
    func tcpConnection(_ sender: TCPConnectionProtocol, didConnectToHost host: String, port: UInt16) {
        delegate?.peerConnected(self)
    }
    
    func tcpConnection(_ sender: TCPConnectionProtocol, didRead data: Data, withTag tag: Int) {
        
        if !handshakeReceived {
            handshakeMessageBuffer.appendData(data)
        } else {
            messageBuffer.appendData(data)
        }
        
        connection.readData(withTimeout: -1, tag: 0)
    }
    
    func tcpConnection(_ sender: TCPConnectionProtocol, didWriteDataWithTag tag: Int) {
        
    }
    
    func tcpConnection(_ sender: TCPConnectionProtocol, disconnectedWithError error: Error?) {
        
        // This was in my previous implementation, not sure why - never used:
        //     let connectionWasRefused = (error == nil) || error.code == 61
        
        delegate?.peerLost(self)
    }
}

extension TorrentPeerCommunicator: TorrentPeerHandshakeDelegate {
    
    func peerHandshakeMessageBuffer(_ sender: TorrentPeerHandshakeMessageBuffer,
                                    gotBadHandshake error: TorrentPeerHandshakeMessageBufferError) {
        
        delegate?.peerSentMalformedMessage(self)
    }
    
    func peerHandshakeMessageBuffer(_ sender: TorrentPeerHandshakeMessageBuffer,
                                    gotHandshakeWithPeerId peerId: Data,
                                    remainingBuffer: Data,
                                    onDHT: Bool) {
        
        handshakeReceived = true
        delegate?.peerSentHandshake(self, sentHandshakeWithPeerId: peerId, onDHT: onDHT)
        messageBuffer.appendData(remainingBuffer)
    }
}

extension TorrentPeerCommunicator: TorrentPeerMessageBufferDelegate {
    
    func peerMessageBuffer(_ sender: TorrentPeerMessageBuffer, gotMessage data: Data) {
        
        guard data.count > 4 else {
            delegate?.peerSentKeepAlive(self)
            return
        }
        
        guard let message = Message(rawValue: data[4]) else {
            delegate?.peerSentMalformedMessage(self)
            return
        }
        
        if enableLogging { print("Got Message from peer \(message.stringValue)") }
        
        switch message {
            
        case .choke:
            delegate?.peerBecameChoked(self)
            
        case .unchoke:
            delegate?.peerBecameUnchoked(self)
            
        case .interested:
            delegate?.peerBecameInterested(self)
            
        case .notInterested:
            delegate?.peerBecameUninterested(self)
            
        case .have:
            processHasPieceMessage(data)
            
        case .bitfield:
            processBitFieldMessage(data)
            
        case .request:
            processRequestMessage(data)
            
        case .piece:
            processSentPieceMessage(data)
            
        case .cancel:
            processCancelRequestMessage(data)
            
        case .port:
            // TODO: implement with DHT peer discovery
            return
        }
    }
    
    private func processHasPieceMessage(_ message: Data) {
        let pieceIndex = Int(UInt32(data: message[5 ..< 9]))
        delegate?.peer(self, hasPiece: pieceIndex)
    }
    
    private func processBitFieldMessage(_ message: Data) {
        let bitFieldData = message[5 ..< message.count]
        let bitField = BitField(data: bitFieldData)
        delegate?.peer(self, hasBitField: bitField)
    }
    
    private func processRequestMessage(_ message: Data) {
        let pieceIndex = Int(UInt32(data: message[5 ..< 9]))
        let begin = Int(UInt32(data: message[9 ..< 13]))
        let length = Int(UInt32(data: message[13 ..< 17]))
        delegate?.peer(self, requestedPiece: pieceIndex, begin: begin, length: length)
    }
    
    private func processSentPieceMessage(_ message: Data) {
        let pieceIndex = Int(UInt32(data: message[5 ..< 9]))
        let begin = Int(UInt32(data: message[9 ..< 13]))
        let block = message[13 ..< message.count]
        delegate?.peer(self, sentPiece: pieceIndex, begin: begin, block: block)
    }
    
    private func processCancelRequestMessage(_ message: Data) {
        let pieceIndex = Int(UInt32(data: message[5 ..< 9]))
        let begin = Int(UInt32(data: message[9 ..< 13]))
        let length = Int(UInt32(data: message[13 ..< 17]))
        delegate?.peer(self, cancelledRequestedPiece: pieceIndex, begin: begin, length: length)
    }
}
