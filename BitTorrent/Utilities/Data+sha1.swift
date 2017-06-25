//
//  Data+sha1.swift
//  BitTorrent
//
//  Created by Ben Davis on 25/03/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation
import CommonCrypto

extension Data {
    
    func sha1() -> Data {
        let outputLength = Int(CC_SHA1_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1((self as NSData).bytes, CC_LONG(self.count), &digest)
        let bytesPointer = UnsafeRawPointer(digest)
        return Data(bytes: bytesPointer, count: outputLength)
    }
}
