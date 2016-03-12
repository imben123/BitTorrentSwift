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
    
    static let ascii_i:      Byte = 105
    static let ascii_e:      Byte = 101
    static let ascii_colon:  Byte = 58
    static let ascii_l:      Byte = 108
    static let ascii_d:      Byte = 100
    
    static let IntergerStartToken:       NSData = try! Character("i").asciiValue()
    static let StructureEndToken:        NSData = try! Character("e").asciiValue()
    static let StringSizeDelimiterToken: NSData = try! Character(":").asciiValue()
    static let ListStartToken:           NSData = try! Character("l").asciiValue()
    static let DictinaryStartToken:      NSData = try! Character("d").asciiValue()
    

    /**
     Creates BEncoded integer
     */
    public class func encodeInteger(integer: Int) -> NSData {
        let data = NSMutableData(data: IntergerStartToken)
            .andData(integer.digitsInAscii())
            .andData(StructureEndToken)
        return data
    }
    
    /**
     Creates a BEncoded byte string
     */
    public class func encodeByteString(byteString: NSData) -> NSData {
        let numberOfBytes = byteString.length
        return NSMutableData(data: numberOfBytes.digitsInAscii())
            .andData(StringSizeDelimiterToken)
            .andData(byteString)
    }
    
    /**
     Creates a BEncoded byte string with the ascii representation of the string
     */
    public class func encodeString(string: String) -> NSData {
        let stringUTF8 = string.utf8
        let data = NSMutableData(data: stringUTF8.count.digitsInAscii())
            .andData(StringSizeDelimiterToken)
            .andData(try! string.asciiValue())
        return data
    }
    
    /**
     Creates a BEncoded list containing the BEncoded values given
     
     - parameter list: This should be an array of BEncoded values. Data passed to this parameter isn't
     checked as valid BEncode so will result in bad BEncode being returned.
     
     */
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
    
    /**
     Creates a BEncoded dictionary. Containing the key/value pairs in the swift dictionary.
     Keys will be encoded as BEncoded strings
     
     - parameter dictionary: This should be a dictionary of BEncoded values keyed using NSData objects
     which will be encoded as BEncoded strings
     
     - throws: AsciiError.Invalid if the strings don't ascii encode
    
     */
    public class func encodeDictionary(dictionary: [String:NSData]) throws -> NSData {
        let dictionaryWithEncodedKeys = try self.createDictionaryWithEncodedKeys(dictionary)
        return self.encodeDictionary(dictionaryWithEncodedKeys)
    }
    
    private class func createDictionaryWithEncodedKeys(dictionary: [String:NSData]) throws -> [NSData:NSData] {
        var dictionaryWithEncodedKeys: [NSData: NSData] = [:]
        for (key, value) in dictionary {
            dictionaryWithEncodedKeys[try key.asciiValue()] = value
        }
        return dictionaryWithEncodedKeys
    }
    
    /**
     Creates a BEncoded dictionary. Containing the key/value pairs in the swift dictionary.
     Keys will be encoded as BEncoded byte strings
     
     - parameter dictionary: This should be a dictionary of BEncoded values keyed using NSData objects
     which will be encoded as BEncoded byte strings
     
     */
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