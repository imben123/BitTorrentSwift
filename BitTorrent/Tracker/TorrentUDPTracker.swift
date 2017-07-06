//
//  TorrentUDPTracker.swift
//  BitTorrent
//
//  Created by Ben Davis on 04/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation
import BEncode

private let PROTOCOL_ID = UInt64(0x41727101980).toData() // magic constant (protocol_id)

private let CONNECTION_ACTION = UInt32(0).toData()
private let ANNOUNCE_ACTION = UInt32(1).toData()
private let ERROR_ACTION = UInt32(3).toData()

class TorrentUDPTracker {
    
    var enableLogging = false
    
    weak var delegate: TorrentTrackerDelegate?
    
    private let announceURL: URL
    private var discoveredHostIpAddress: String?
    private let udpConnection: UDPConnectionProtocol
    
    private var pendingAnnounce: ((_ transactionId: Data, _ connectionId: Data)->Void)?
    private var pendingTransactionId: Data?
    
    init(announceURL: URL, port: UInt16, udpConnection: UDPConnectionProtocol = UDPConnection()) {
        self.announceURL = announceURL
        self.udpConnection = udpConnection
        udpConnection.delegate = self
        udpConnection.startListening(on: port)
    }
    
    func announceClient(with peerId: String,
                        port: Int,
                        event: TorrentTrackerEvent = .started,
                        infoHash: Data,
                        numberOfBytesRemaining: Int,
                        numberOfBytesUploaded: Int,
                        numberOfBytesDownloaded: Int,
                        numberOfPeersToFetch: Int) {
        
        guard let host = getHostIpAddress() else { return }
        let announcePort = UInt16(announceURL.port ?? 80)
        
        log("Will connect to UDP tracker: \(host):\(announcePort)")
        
        let transactionId = makeTransactionId()
        let payload = makeConnectionPayload(with: transactionId)
        udpConnection.send(payload, toHost: host, port: announcePort, timeout: 10)
        
        pendingAnnounce = { [weak self] (responseTransactionId, connectionId) in
            
            guard let strongSelf = self else { return }
            guard responseTransactionId == transactionId else { return }
            
            self?.log("Will announce to UDP tracker: \(host):\(announcePort)")
            
            var payload = connectionId                           // 0      64-bit integer  connection_id
            payload += ANNOUNCE_ACTION                           // 8      32-bit integer  action          1 // announce
            payload += strongSelf.makeTransactionId()            // 12     32-bit integer  transaction_id
            payload += infoHash                                  // 16     20-byte string  info_hash
            payload += peerId.data(using: .ascii)!               // 36     20-byte string  peer_id
            payload += UInt64(numberOfBytesDownloaded).toData()  // 56     64-bit integer  downloaded
            payload += UInt64(numberOfBytesRemaining).toData()   // 64     64-bit integer  left
            payload += UInt64(numberOfBytesUploaded).toData()    // 72     64-bit integer  uploaded
            payload += event.udpDataRepresentation               // 80     32-bit integer  event
            payload += UInt32(0).toData()                        // 84     32-bit integer  IP address      0 // default
            payload += UInt32(0).toData()                        // 88     32-bit integer  key             0 // default
            payload += UInt32(numberOfPeersToFetch).toData()     // 92     32-bit integer  num_want       -1 // default
            payload += UInt16(port).toData()                     // 96     16-bit integer  port
            
            strongSelf.udpConnection.send(payload, toHost: host, port: announcePort, timeout: 10)
        }
    }
    
    private func getHostIpAddress() -> String? {
        guard discoveredHostIpAddress == nil else {
            return discoveredHostIpAddress
        }
        
        let result = InternetProtocol.getIPAddress(of: announceURL.host!)
        discoveredHostIpAddress = result
        return result
    }
    
    private func makeConnectionPayload(with transactionId: Data) -> Data {
        return PROTOCOL_ID + CONNECTION_ACTION + transactionId
    }
    
    private func makeTransactionId() -> Data {
        let result = arc4random().toData()
        pendingTransactionId = result
        return result
    }
}

extension TorrentUDPTracker: UDPConnectionDelegate {
    
    func udpConnection(_ sender: UDPConnectionProtocol, receivedData data: Data, fromHost host: String) {
        
        let action = Data(data[0..<4])
        
        log("Got response from UDP tracker \(host)")
        
        if action == CONNECTION_ACTION {
            log("UDP tracker \(host) accepted connection")
            parseConnectionResponse(data)
        } else if action == ANNOUNCE_ACTION {
            log("UDP tracker \(host) responded to announce")
            parseAnnounceResponse(data)
        } else if action == ERROR_ACTION {
            log("UDP tracker \(host) gave error")
            parseErrorResponse(data)
        }
    }
    
    func parseConnectionResponse(_ response: Data) {
        
        let transactionId = Data(response[4..<8])
        let connectionId = Data(response[8..<16])
        
        pendingAnnounce?(transactionId, connectionId)
        pendingAnnounce = nil
    }
    
    private func parseAnnounceResponse(_ response: Data) {
        
        let transactionId = Data(response[4..<8])
        guard pendingTransactionId == transactionId else { return }
        
        let interval = response[8..<12].toUInt32()
        let leechers = response[12..<16].toUInt32()
        let seeders  = response[16..<20].toUInt32()
        let peers = TorrentPeerInfo.peersInfoFromBinaryModel(response[20..<response.count])
        
        let response = TorrentTrackerResponse(peers: peers,
                                              numberOfPeersComplete: Int(seeders),
                                              numberOfPeersIncomplete: Int(leechers),
                                              interval: Int(interval))
        
        self.delegate?.torrentTracker(self, receivedResponse: response)
    }
    
    private func parseErrorResponse(_ response: Data) {
        
        if let errorMessage = String(data: response[8..<response.count], encoding: .utf8) {
            delegate?.torrentTracker(self, receivedErrorMessage: errorMessage)
        }
    }
}

extension TorrentUDPTracker {
     func log(_ items: Any...) {
        if enableLogging { print(items) }
    }
}
