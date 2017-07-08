//
//  BitField.swift
//  BitTorrent
//
//  Created by Ben Davis on 08/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

struct BitField {
    let size: Int
    var value: [Bool]
    
    init(size: Int) {
        self.size = size
        self.value = Array(repeating: false, count: size)
    }
    
    mutating func set(at index: Int) {
        value[index] = true
    }
    
    mutating func unset(at index: Int) {
        value[index] = false
    }
    
    func toData() -> Data {
        let numberOfBytes: Int
        if (size % 8) == 0 {
            numberOfBytes = size / 8
        } else {
            numberOfBytes = (size / 8) + 1
        }
        
        var bytes: [UInt8] = []
        for i in 0..<numberOfBytes {
            let startIndex = i * 8
            var byte: UInt8
            if size >= startIndex + 8 {
                byte = UInt8(bits: (value[startIndex],
                                    value[startIndex + 1],
                                    value[startIndex + 2],
                                    value[startIndex + 3],
                                    value[startIndex + 4],
                                    value[startIndex + 5],
                                    value[startIndex + 6],
                                    value[startIndex + 7]))
            } else {
                byte = UInt8(bits: (value[startIndex],
                                    (size > startIndex + 1) ? value[startIndex + 1] : false,
                                    (size > startIndex + 2) ? value[startIndex + 2] : false,
                                    (size > startIndex + 3) ? value[startIndex + 3] : false,
                                    (size > startIndex + 4) ? value[startIndex + 4] : false,
                                    (size > startIndex + 5) ? value[startIndex + 5] : false,
                                    (size > startIndex + 6) ? value[startIndex + 6] : false,
                                    false))
            }
            bytes.append(byte)
        }
        
        return Data(bytes: bytes)
    }
}
