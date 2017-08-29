//
//  TorrentInfoRowData.swift
//  BitTorrentExample
//
//  Created by Ben Davis on 13/08/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import BitTorrent

enum TorrentInfoRowData: Int {
    case name = 0
    case size, percentageComplete, status, seeds, peers, downloadSpeed, uploadSpeed, eta, uploaded
    
    static var numberOfRows: Int = 10
    
    var titleText: String {
        switch self {
        case .name:
            return "Name"
        case .size:
            return "Size"
        case .percentageComplete:
            return "Completed"
        case .status:
            return "Status"
        case .seeds:
            return "Seeds"
        case .peers:
            return "Peers"
        case .downloadSpeed:
            return "↓ Speed"
        case .uploadSpeed:
            return "↑ Speed"
        case .eta:
            return "ETA"
        case .uploaded:
            return "Uploaded"
        }
    }
    
    func value(using client: TorrentClient) -> String {
        
        let speedSampleSize: TimeInterval = 5
        
        switch self {
            
        case .name:
            return client.metaInfo.info.name
            
        case .size:
            return bytesToString(client.metaInfo.info.length)
            
        case .percentageComplete:
            let percentageComplete = client.progress.percentageComplete
            let progressString = twoDecimalPlaceFloat(percentageComplete * 100)
            return "\(progressString)%"
            
        case .status:
            return client.status.toString
            
        case .seeds:
            return "\(client.numberOfConnectedSeeds)"
            
        case .peers:
            return "\(client.numberOfConnectedPeers)"
            
        case .downloadSpeed:
            let speed = client.downloadSpeedTracker.numberOfBytesDownloaded(over: speedSampleSize)
            return bytesToString(speed / Int(speedSampleSize)) + "/s"
            
        case .uploadSpeed:
            return "????"
            
        case .eta:
            let speed = client.downloadSpeedTracker.numberOfBytesDownloaded(over: speedSampleSize)
            let speedPerSecond = Double(speed) / speedSampleSize
            guard speed > 0 else { return "∞" }
            
            let remaining = client.progress.remaining * client.metaInfo.info.pieceLength
            guard remaining > 0 else { return "n/a" }
            
            return (Double(remaining) / speedPerSecond).stringTime
            
        case .uploaded:
            return "????"
        }
    }
}
