//
//  AppDelegate.swift
//  BitTorrentExample
//
//  Created by Ben Davis on 27/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import UIKit
import BitTorrent

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var torrentClient: TorrentClient!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let metaInfo = TorrentMetaInfo(named: "LancasterPics")!
        var pathRoot = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        pathRoot = pathRoot + "/Torrent Downloads/"
        
        print(pathRoot)
                
        torrentClient = TorrentClient(metaInfo: metaInfo, rootDirectory: pathRoot)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = TorrentViewController(torrentClient: torrentClient)
        window!.backgroundColor = .white
        window!.makeKeyAndVisible()
        
        return true
    }
    
}
