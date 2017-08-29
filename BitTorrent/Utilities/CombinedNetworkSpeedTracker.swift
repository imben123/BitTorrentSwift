//
//  CombinedNetworkSpeedTracker.swift
//  BitTorrent
//
//  Created by Ben Davis on 13/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

class CombinedNetworkSpeedTracker: NetworkSpeedTrackable {
    
    let trackers: () -> [NetworkSpeedTracker]
    
    init(trackers: @escaping () -> [NetworkSpeedTracker]) {
        self.trackers = trackers
    }
    
    // MARK: - NetworkSpeedTrackable
    
    var totalNumberOfBytes: Int {
        var result = 0
        for tracker in trackers() {
            result += tracker.totalNumberOfBytes
        }
        return result
    }
    
    func numberOfBytesDownloaded(since date: Date) -> Int {
        var result = 0
        for tracker in trackers() {
            result += tracker.numberOfBytesDownloaded(since: date)
        }
        return result
    }
    
    func numberOfBytesDownloaded(over timeInterval: TimeInterval) -> Int {
        var result = 0
        for tracker in trackers() {
            result += tracker.numberOfBytesDownloaded(over: timeInterval)
        }
        return result
    }
}
