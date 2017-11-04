//
//  Data+subscript.swift
//  BitTorrent
//
//  Created by Ben Davis on 03/11/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

/// This class wraps a Data instance to guarantee that the byte at index 0
/// is the first byte in the represented data, regardless of whether the instance
/// represents a slice of a different Data instance.
///
/// For example:
/// ```
/// let data = Data(bytes: [1,2,3])
/// let slice = data[1..<3]             // represents data with bytes [2,3]
/// print(slice[1])                     // prints '2'
/// print(slice.correctingIndicies[1])  // prints '3'
/// ```
struct IndexCorrectedDataSlice: Collection {
    
    private let originalData: Data
    
    let startIndex = 0
    let endIndex: Int
    
    fileprivate init(originalData: Data) {
        self.originalData = originalData
        self.endIndex = originalData.distance(from: originalData.startIndex,
                                              to: originalData.endIndex)
    }
    
    /// Note: The resulting data shares indicies with the original Data instance.
    subscript(_ range: Range<Int>) -> Data {
        let actualLowerBound = originalData.startIndex + range.lowerBound
        let actualUpperBound = originalData.startIndex + range.upperBound
        return originalData[actualLowerBound ..< actualUpperBound]
    }
    
    subscript(_ index: Int) -> UInt8 {
        let correctedIndex = originalData.startIndex + index
        return originalData[correctedIndex]
    }
    
    func index(after i: Int) -> Int {
        return i + 1
    }
}

extension Data {
    var correctingIndicies: IndexCorrectedDataSlice {
        return IndexCorrectedDataSlice(originalData: self)
    }
}
