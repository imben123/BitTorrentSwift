//
//  AppDelegate.swift
//  BitTorrentExample
//
//  Created by Ben Davis on 27/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import UIKit
@testable import BitTorrent

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var tracker: TorrentHTTPTracker!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = UIViewController()
        window!.backgroundColor = .white
        window!.makeKeyAndVisible()
        
        
        let path = Bundle(for: type(of: self)).path(forResource: "TestText", ofType: "torrent")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let metaInfo = TorrentMetaInfo(data: data)!
        
        tracker = TorrentHTTPTracker(metaInfo: metaInfo)
        
        tracker.announceClient(with: "-BD0000-bxa]N#IRKqv`",
                               port: 6881,
                               numberOfBytesRemaining: 117,
                               infoHash: Data(bytes:[ 0xf0, 0xb8, 0x71, 0x98, 0x99, 0x53, 0x97, 0x3f, 0xbf, 0xa9,
                                                      0x4d, 0xc8, 0x14, 0x98, 0xee, 0x8d, 0x20, 0x5b, 0xb2, 0x23]),
                               numberOfPeersToFetch: 50,
                               peerKey: "key")
        
        return true
    }
    
}
