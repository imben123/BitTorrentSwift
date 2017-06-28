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
                               event: .started,
                               infoHash: metaInfo.infoHash,
                               numberOfBytesRemaining: metaInfo.info.length,
                               numberOfBytesUploaded: 0,
                               numberOfBytesDownloaded: 0,
                               numberOfPeersToFetch: 50)
        
        return true
    }
    
}
