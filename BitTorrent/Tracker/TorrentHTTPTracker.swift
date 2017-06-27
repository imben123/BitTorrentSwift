//
//  Tracker.swift
//  BitTorrent
//
//  Created by Ben Davis on 27/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

//tracker.announceClient(self.peerId,
//                       port: 6881,
//                       numberOfBytes: self.metaInfo.length,
//                       infoHash: self.metaInfo.infoHash,
//                       numwant: 20,
//                       key: "-BD0000-bxa]N#IRKqv`");

//func makePeerId() -> String {
//    var peerId = "-BD0000-"
//
//    for _ in 0...11 {
//        let asciiCharacters = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
//        let numberOfAscii = asciiCharacters.characters.count
//        let randomIndex = arc4random() % UInt32(numberOfAscii)
//        let random = asciiCharacters[Int(randomIndex)]
//        peerId += random
//    }
//
//    if (GENERAL_DEBUG_LOG) { print("Client Peer ID: \(peerId)") }
//
//    return peerId
//}

class TorrentHTTPTracker {
    
    let metaInfo: TorrentMetaInfo
    let connection: BasicHTTPConnection
    
    init(metaInfo: TorrentMetaInfo, connection: BasicHTTPConnection = HTTPConnection()) {
        self.metaInfo = metaInfo
        self.connection = connection
    }
    
    func announceClient(with peerId: String,
                        port: Int,
                        numberOfBytesRemaining: Int,
                        infoHash: Data,
                        numberOfPeersToFetch: Int,
                        peerKey: String) {
        
        let urlParameters = [
            "info_hash" : String(urlEncodingData: metaInfo.infoHash),
            "peer_id" : "\(peerId)",
            "port" : "\(port)",
            "uploaded" : "0",
            "downloaded" : "0",
            "left" : "\(numberOfBytesRemaining)",
            "compact" : "1",
            "event" : "started",
            "numwant" : "\(numberOfPeersToFetch)",
            "key" : peerKey,
        ]
        
        connection.makeRequest(url: metaInfo.announce, urlParameters: urlParameters) { response in
            
            if let data = response.responseData, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)")
            }
        }
    }
    
}
