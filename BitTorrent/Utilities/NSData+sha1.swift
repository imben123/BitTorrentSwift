//
//  NSData+sha1.swift
//  BitTorrent
//
//  Created by Ben Davis on 25/03/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation
import CommonCrypto

extension NSData {
    
    func sha1() -> NSData {
        let outputLength = Int(CC_SHA1_DIGEST_LENGTH)
        var digest = [UInt8](count:Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
        CC_SHA1(self.bytes, CC_LONG(self.length), &digest)
        let bytesPointer = UnsafePointer<Void>(digest)
        return NSData(bytes: bytesPointer, length: outputLength)
    }
    
}