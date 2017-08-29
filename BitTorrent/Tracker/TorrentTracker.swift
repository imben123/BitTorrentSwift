//
//  TorrentTracker.swift
//  BitTorrent
//
//  Created by Ben Davis on 12/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

protocol TorrentTracker: class {
    
    weak var delegate: TorrentTrackerDelegate? { get set }
    
    func announceClient(with peerId: String,
                        port: UInt16,
                        event: TorrentTrackerEvent,
                        infoHash: Data,
                        numberOfBytesRemaining: Int,
                        numberOfBytesUploaded: Int,
                        numberOfBytesDownloaded: Int,
                        numberOfPeersToFetch: Int)
}
