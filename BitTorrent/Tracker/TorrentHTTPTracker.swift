//
//  Tracker.swift
//  BitTorrent
//
//  Created by Ben Davis on 27/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

class TorrentHTTPTracker {
    
    let announceURL: URL
    let connection: BasicHTTPConnection
    
    weak var delegate: TorrentTrackerDelegate?
    
    init(announceURL: URL, connection: BasicHTTPConnection = HTTPConnection()) {
        self.announceURL = announceURL
        self.connection = connection
    }
    
    func announceClient(with peerId: String,
                        port: Int,
                        event: TorrentTrackerEvent = .started,
                        infoHash: Data,
                        numberOfBytesRemaining: Int,
                        numberOfBytesUploaded: Int,
                        numberOfBytesDownloaded: Int,
                        numberOfPeersToFetch: Int) {
        
        let urlParameters = [
            "info_hash" : String(urlEncodingData: infoHash),
            "peer_id" : "\(peerId)",
            "port" : "\(port)",
            "uploaded" : "\(numberOfBytesUploaded)",
            "downloaded" : "\(numberOfBytesDownloaded)",
            "left" : "\(numberOfBytesRemaining)",
            "compact" : "1",
            "event" : event.name,
            "numwant" : "\(numberOfPeersToFetch)"
        ]
        
        connection.makeRequest(url: announceURL, urlParameters: urlParameters) { [weak self] response in
            
            guard self != nil else {
                return
            }
            
            if let data = response.responseData {
                if let result = TorrentTrackerResponse(bencode: data) {
                    self!.delegate?.torrentTracker(self!, receivedResponse: result)
                } else if let errorMessage = TorrentTrackerResponse.errorMessage(fromResponseData: data) {
                    self!.delegate?.torrentTracker(self!, receivedErrorMessage: errorMessage)
                }
            }
        }
    }
}

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
