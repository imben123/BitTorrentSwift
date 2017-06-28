//
//  Tracker.swift
//  BitTorrent
//
//  Created by Ben Davis on 27/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

protocol TorrentTrackerDelegate: class {
    func torrentTracker(_ sender: TorrentHTTPTracker, receivedResponse: TorrentHTTPTrackerResponse)
    func torrentTracker(_ sender: TorrentHTTPTracker, receivedErrorMessage: String)
}

enum TorrentHTTPTrackerEvent {
    case started, stopped, completed
    
    var name: String {
        switch self {
        case .started:
            return "started"
        case .stopped:
            return "stopped"
        case .completed:
            return "completed"
        }
    }
}

class TorrentHTTPTracker {
    
    let metaInfo: TorrentMetaInfo
    let connection: BasicHTTPConnection
    
    weak var delegate: TorrentTrackerDelegate?
    
    init(metaInfo: TorrentMetaInfo, connection: BasicHTTPConnection = HTTPConnection()) {
        self.metaInfo = metaInfo
        self.connection = connection
    }
    
    func announceClient(with peerId: String,
                        port: Int,
                        event: TorrentHTTPTrackerEvent = .started,
                        infoHash: Data,
                        numberOfBytesRemaining: Int,
                        numberOfBytesUploaded: Int,
                        numberOfBytesDownloaded: Int,
                        numberOfPeersToFetch: Int) {
        
        let urlParameters = [
            "info_hash" : String(urlEncodingData: metaInfo.infoHash),
            "peer_id" : "\(peerId)",
            "port" : "\(port)",
            "uploaded" : "\(numberOfBytesUploaded)",
            "downloaded" : "\(numberOfBytesDownloaded)",
            "left" : "\(numberOfBytesRemaining)",
            "compact" : "1",
            "event" : event.name,
            "numwant" : "\(numberOfPeersToFetch)"
        ]
        
        connection.makeRequest(url: metaInfo.announce, urlParameters: urlParameters) { [weak self] response in
            
            guard self != nil else {
                return
            }
            
            if let data = response.responseData {
                if let result = TorrentHTTPTrackerResponse(data: data) {
                    self!.delegate?.torrentTracker(self!, receivedResponse: result)
                } else if let errorMessage = TorrentHTTPTrackerResponse.errorMessage(fromResponseData: data) {
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
