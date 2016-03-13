//
//  ByteStream.swift
//  BitTorrent
//
//  Created by Ben Davis on 12/03/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

public protocol ByteStream {
    
    var currentIndex: Int { get }
    
    func nextByte() -> Byte?
    
    func nextBytes(numberOfBytes: Int) -> NSData?

    func indexIsValid(index: Int) -> Bool
    
    func advanceBy(numberOfBytes: Int)

}