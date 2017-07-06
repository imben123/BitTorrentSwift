//
//  TorrentPeerInfo.swift
//  BitTorrent
//
//  Created by Ben Davis on 28/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

struct TorrentPeerInfo {
    let ip: String
    let port: Int
    let peerId: Data?
    
    init(ip: String, port: Int, peerId: Data?) {
        self.ip = ip
        self.port = port
        self.peerId = peerId
    }
    
    init?(dictionary: [String: Any]) {
        
        guard let ipData = dictionary["ip"] as? Data,
            let ip = String(asciiData: ipData),
            let port = dictionary["port"] as? Int else {
                return nil
        }
        
        self.ip = ip
        self.port = port
        self.peerId = dictionary["peer id"] as? Data
    }
    
    static func peersInfoFromBinaryModel(_ data: Data) -> [TorrentPeerInfo] {
        let numberOfPeers = data.count / 6
        var result: [TorrentPeerInfo] = []
        for i in 0..<numberOfPeers {
            let ip1 = Int(data[i*6])
            let ip2 = Int(data[i*6 + 1])
            let ip3 = Int(data[i*6 + 2])
            let ip4 = Int(data[i*6 + 3])
            let portBytes = [data[i*6 + 5], data[i*6 + 4]]
            
            let portu16 = UnsafePointer(portBytes).withMemoryRebound(to: UInt16.self, capacity: 1) {
                $0.pointee
            }
            let port = Int(portu16)
                        
            let peer = TorrentPeerInfo(ip: "\(ip1).\(ip2).\(ip3).\(ip4)", port: port, peerId: nil)
            result.append(peer)
        }
        return result
    }
}
