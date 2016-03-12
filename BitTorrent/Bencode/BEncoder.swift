//
//  BEncoder.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

enum BEncoderException: ErrorType {
    case InvalidAscii
    case InvalidBEncode
}

public class BEncoder {
    
    public static let IntergerStartToken:   NSData = try! Character("i").asciiValue()
    public static let StructureEndToken:    NSData = try! Character("e").asciiValue()
    public static let StringSizeDelimiter:  NSData = try! Character(":").asciiValue()
    public static let ListStartToken:       NSData = try! Character("l").asciiValue()
    public static let DictinaryStartToken:  NSData = try! Character("d").asciiValue()
    
    public class func encodeInteger(integer: Int) -> NSData {
        let data = NSMutableData(data: IntergerStartToken)
            .andData(integer.digitsInAscii())
            .andData(StructureEndToken)
        return data
    }
    
    public class func encodeByteString(byteString: NSData) -> NSData {
        let numberOfBytes = byteString.length
        return NSMutableData(data: numberOfBytes.digitsInAscii())
            .andData(StringSizeDelimiter)
            .andData(byteString)
    }
    
    public class func encodeString(string: String) -> NSData {
        let stringUTF8 = string.utf8
        let data = NSMutableData(data: stringUTF8.count.digitsInAscii())
            .andData(StringSizeDelimiter)
            .andData(try! string.asciiValue())
        return data
    }
    
    public class func encodeList(list: [NSData]) -> NSData {
        let innerData = encodeListInnerData(list)
        return NSMutableData(data: ListStartToken).andData(innerData).andData(StructureEndToken)
    }
    
    private class func encodeListInnerData(list: [NSData]) -> NSData {
        return list.reduce(NSMutableData()) { (result: NSMutableData, item: NSData) -> NSMutableData in
            result.appendData(item)
            return result
        }
    }
    
    public class func encodeDictionary(dictionary: [NSData:NSData]) -> NSData {
        let innerData = encodeDictionaryInnerValues(dictionary)
        return NSMutableData(data: DictinaryStartToken).andData(innerData).andData(StructureEndToken)
    }
    
    private class func encodeDictionaryInnerValues(dictionary: [NSData:NSData]) -> NSData {
        return dictionary.reduce(NSMutableData()) { (result: NSMutableData, current: (NSData, NSData)) -> NSMutableData in
            return self.appendKeyValuePairToDictionaryData(result, key: current.0, value: current.1)
        }
    }
    
    private class func appendKeyValuePairToDictionaryData(data: NSMutableData, key: NSData, value: NSData) -> NSMutableData {
        data.appendData(self.encodeByteString(key))
        data.appendData(value)
        return data
    }
    
}