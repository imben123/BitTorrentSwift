//
//  TorrentTrackerResponse.swift
//  BitTorrent
//
//  Created by Ben Davis on 28/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation
import BEncode

struct TorrentHTTPTrackerResponse {
    
    let peers: [TorrentPeerInfo]
    let numberOfPeersComplete: Int // Seeders
    let numberOfPeersIncomplete: Int // Leechers
    
    let trackerId: Data?
    
    let interval: Int
    let minimumInterval: Int
    
    let warning: String?
    
    init(peers: [TorrentPeerInfo],
         numberOfPeersComplete: Int = 0,
         numberOfPeersIncomplete: Int = 0,
         trackerId: Data? = nil,
         interval: Int = 60,
         minimumInterval: Int = 0,
         warning: String? = nil) {
        
        self.peers = peers
        self.numberOfPeersComplete = numberOfPeersComplete
        self.numberOfPeersIncomplete = numberOfPeersIncomplete
        self.trackerId = trackerId
        self.interval = interval
        self.minimumInterval = minimumInterval
        self.warning = warning
    }
}

extension TorrentHTTPTrackerResponse {
    
    init?(data: Data) {
        let bencode: [String: Any]
        do {
            bencode = try BEncoder.decodeStringKeyedDictionary(data)
        } catch {
            return nil
        }
        
        guard let numberOfPeersComplete = bencode["complete"] as? Int,
            let numberOfPeersIncomplete = bencode["incomplete"] as? Int,
            let interval = bencode["interval"] as? Int,
            let peersObject = bencode["peers"] else {
            return nil
        }
        
        if let binaryData = peersObject as? Data {
            self.peers = TorrentPeerInfo.peersInfoFromBinaryModel(binaryData)
        } else {
            guard let peersDictionaries = peersObject as? [[String: Any]] else {
                return nil
            }
            self.peers = peersDictionaries.map(TorrentPeerInfo.init(dictionary:)).flatMap({ $0 })
        }
        self.numberOfPeersComplete = numberOfPeersComplete
        self.numberOfPeersIncomplete = numberOfPeersIncomplete
        self.trackerId = bencode["tracker id"] as? Data
        self.interval = interval
        self.minimumInterval = bencode["min interval"] as? Int ?? 0
        
        if let warningData = bencode["warning message"] as? Data {
            self.warning = String(data: warningData, encoding: .utf8)
        } else {
            self.warning = nil
        }
    }
}

extension TorrentHTTPTrackerResponse {
    
    static func errorMessage(fromResponseData data: Data) -> String? {
        
        let bencode: [String: Any]
        do {
            bencode = try BEncoder.decodeStringKeyedDictionary(data)
        } catch {
            return nil
        }
        
        return String(asciiData: bencode["failure reason"] as? Data)
    }
}
