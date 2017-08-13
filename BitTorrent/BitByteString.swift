//
//  BitByteString.swift
//  BitTorrent
//
//  Created by Ben Davis on 12/04/2015.
//  Copyright (c) 2015 Ben Davis. All rights reserved.
//

import Foundation

let bytesInKB = 1024
let bytesInMB = bytesInKB*1024
let bytesInGB = bytesInMB*1024

func twoDecimalPlaceFloat(_ float: Float) -> String {
    return String(format: "%.2f", float)
}

func bytesToString(_ numberOfBytes: Int) -> String {
    if (numberOfBytes > bytesInGB) {
        let numberOfGBs: Float = Float(numberOfBytes) / Float(bytesInGB)
        return "\(twoDecimalPlaceFloat(numberOfGBs)) GB"
    } else if (numberOfBytes > bytesInMB) {
        let numberOfMBs: Float = Float(numberOfBytes) / Float(bytesInMB)
        return "\(twoDecimalPlaceFloat(numberOfMBs)) MB"
    } else if (numberOfBytes > bytesInKB) {
        let numberOfKBs: Float = Float(numberOfBytes) / Float(bytesInKB)
        return "\(twoDecimalPlaceFloat(numberOfKBs)) KB"
    } else {
        return "\(numberOfBytes) Bytes"
    }
}
