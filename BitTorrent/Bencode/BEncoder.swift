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
    case UnrepresentableObject
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
     Creates a NSData object containing the BEncoded representation of the object passed.
     
     - parameter object: Object to be encoded
     
     - throws: BEncoderException if the object cannot be represented in BEncode
     */
    public class func encode(object: AnyObject) throws -> NSData {
        if object is Int {
            return self.encodeInteger(object as! Int)
        } else if object is String {
            return try self.encodeString(object as! String)
        } else if object is NSData {
            return self.encodeByteString(object as! NSData)
        } else if object is [AnyObject] {
            return try self.encodeList(object as! [AnyObject])
        } else if object is [String:AnyObject] {
            return try self.encodeDictionary(object as! [String:AnyObject])
        } else if object is [NSData:AnyObject] {
            return try self.encodeByteStringKeyedDictionary(object as! [NSData:AnyObject])
        }
        throw BEncoderException.UnrepresentableObject
    }

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
     
     - throws: BEncoderException.InvalidAscii if the string cannot be represented in ASCII
     */
    public class func encodeString(string: String) throws -> NSData {
        let asciiString = try self.asciiValue(string)
        let data = NSMutableData(data: asciiString.length.digitsInAscii())
            .andData(StringSizeDelimiterToken)
            .andData(asciiString)
        return data
    }
    
    /**
     Creates a BEncoded list and BEncodes each object in the list
     
     - parameter list: Array of items to be BEncoded and added to the resulting BEncode list
     
     - throws: Exception if any of the objects are not BEncode-able
     
     */
    public class func encodeList(list: [AnyObject]) throws -> NSData {
        let innerData = try encodeListInnerValues(list)
        return NSMutableData(data: ListStartToken).andData(innerData).andData(StructureEndToken)
    }
    
    private class func encodeListInnerValues(list: [AnyObject]) throws -> NSData {
        return try list.reduce(NSMutableData()) { (result: NSMutableData, item: AnyObject) throws -> NSMutableData in
            let encodedItem = try self.encode(item)
            result.appendData(encodedItem)
            return result
        }
    }
    
    /**
     Creates a BEncoded dictionary and BEncodes each value.
     The keys are BEncoded as byte strings
     
     - parameter list: Dictionary of items to be BEncoded and added to the resulting BEncode
     dictionary. Keys should be data which will be BEncoded as a byte string.
     
     - throws: BEncoderException if any of the objects are not BEncode-able
     
     */
    public class func encodeByteStringKeyedDictionary(dictionary: [NSData:AnyObject]) throws -> NSData {
        let innerData = try encodeDictionaryInnerValues(dictionary)
        return NSMutableData(data: DictinaryStartToken).andData(innerData).andData(StructureEndToken)
    }
    
    private class func encodeDictionaryInnerValues(dictionary: [NSData:AnyObject]) throws -> NSData {
        return try dictionary.reduce(NSMutableData(), combine: self.appendKeyValuePairToDictionaryData)
    }
    
    private class func appendKeyValuePairToDictionaryData(data: NSMutableData,
        pair: (key: NSData, value: AnyObject)) throws -> NSMutableData {
            data.appendData(self.encodeByteString(pair.key))
            data.appendData(try self.encode(pair.value))
            return data
    }
    
    /**
     Creates a BEncoded dictionary and BEncodes each value.
     The keys are BEncoded as strings
     
     - parameter list: Dictionary of items to be BEncoded and added to the resulting BEncode 
                       dictionary. Keys should be ASCII encodeable strings.
     
     - throws: BEncoderException if any of the objects are not BEncode-able.
     BEncoderException.InvalidAscii is thrown if the keys cannot be encoded in ASCII

     */
    public class func encodeDictionary(dictionary: [String:AnyObject]) throws -> NSData {
        let dictionaryWithEncodedKeys = try self.createDictionaryWithEncodedKeys(dictionary)
        let innerData = try self.encodeDictionaryInnerValues(dictionaryWithEncodedKeys)
        return NSMutableData(data: DictinaryStartToken).andData(innerData).andData(StructureEndToken)
    }
    
    private class func createDictionaryWithEncodedKeys(dictionary: [String:AnyObject]) throws -> [NSData:AnyObject] {
        var dictionaryWithEncodedKeys: [NSData: AnyObject] = [:]
        for (key, value) in dictionary {
            let asciiKey = try self.asciiValue(key)
            dictionaryWithEncodedKeys[asciiKey] = value
        }
        return dictionaryWithEncodedKeys
    }
    
    private class func asciiValue(string: String) throws -> NSData {
        do {
            let asciiString = try string.asciiValue()
            return asciiString
        } catch _ {
            throw BEncoderException.InvalidAscii
        }
    }

}