//
//  TorrentFileInfo.swift
//  BitTorrent
//
//  Created by Ben Davis on 23/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

class TorrentFileInfo {
    let path: String
    let length: Int
    let md5sum: String?
    
    init(path: String, length: Int, md5sum: String?) {
        self.path = path
        self.length = length
        self.md5sum = md5sum
    }
    
    convenience init?(dictionary: [ String : AnyObject ]) {
        
        guard let length = dictionary["length"] as? Int,
            let pathData = dictionary["path"] as? [Data],
            let pathComponents = pathData.map(String.init(asciiData:)) as? [String] else {
                return nil
        }
        
        let path = pathComponents.reduce("") { $0.count == 0 ? $1 : $0 + "/" + $1 }
        
        let md5sumData = dictionary["md5sum"] as? Data
        let md5sum = String(asciiData: md5sumData)
        
        self.init(path: path, length: length, md5sum: md5sum)
    }
}
