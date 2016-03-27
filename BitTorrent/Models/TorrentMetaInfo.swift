//
//  TorrentMetaInfo.swift
//  BitTorrent
//
//  Created by Ben Davis on 25/03/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation
import class BEncode.BEncoder
import enum BEncode.AsciiError

class TorrentMetaInfo {
    
    let infoHash : NSData // this is the original bencoded dictionary, hashed

    let info: TorrentInfoDictionary
    let announce: String
    let announceList: [[String]]?
    let creationDate: NSDate?
    let comment: String?
    let createdBy: String?

    init?(data: NSData) {
        
        let decodedMetainfo = try! BEncoder.decodeStringKeyedDictionary(data)
        
        if let infoDictionary = decodedMetainfo["info"] as? [String : AnyObject],
            info = TorrentInfoDictionary(infoDictionary) {
            self.infoHash = try! BEncoder.decodeDictionaryKeysOnly(data)["info"]!.sha1()
            self.info = info
        } else {
            return nil
        }
        
        if let announceData = decodedMetainfo["announce"] as? NSData, announceString = String(asciiData: announceData) {
            self.announce = announceString
        } else {
            return nil
        }
        
        if let announceListData = decodedMetainfo["announce-list"] as? [ [ NSData ] ] {
            if let announceList = TorrentMetaInfo.parseAnnounceList(announceListData) {
                self.announceList = announceList
            } else {
                return nil
            }
        } else {
            self.announceList = nil
        }
        
        if let creationDateInt = decodedMetainfo["creation date"] as? Int {
            self.creationDate = NSDate(timeIntervalSince1970: Double(creationDateInt))
        } else {
            self.creationDate = nil
        }
        
        if let commentString = String(asciiData: decodedMetainfo["comment"] as? NSData) {
            self.comment = commentString
        } else {
            self.comment = nil
        }
        
        if let createdBy = String(asciiData: decodedMetainfo["created by"] as? NSData) {
            self.createdBy = createdBy
        } else {
            self.createdBy = nil
        }
    }
    
    private class func parseAnnounceList(announceListData: [ [ NSData ] ]) -> [[String]]? {
        
        var result: [[String]] = []
        
        for trackersArray in announceListData {
            
            var currentArray: [String] = []
            for trackerData in trackersArray {
                if let tracker = self.urlCompatibleStringFromAsciiData(trackerData) {
                    currentArray.append(tracker)
                } else {
                    return nil
                }
            }
            result.append(currentArray)
        }
        
        return result
    }
    
    private class func urlCompatibleStringFromAsciiData(asciiData: NSData) -> String? {
        let result = String(asciiData: asciiData)
        
        if result == nil || NSURL(string: result!) == nil {
            return nil
        }
        
        return result
    }
}

class TorrentInfoDictionary {
    
    let name : String
    let pieceLength : Int
    let isPrivate : Bool
    let files: [TorrentFileInfo]
    let pieces : [NSData]?
    let length: Int

    init?(_ dictionary: [String : AnyObject]) {
        
        if let nameData = dictionary["name"] as? NSData, name = String(asciiData: nameData) {
            self.name = name
        } else {
            return nil
        }
        
        if let pieceLength = dictionary["piece length"] as? Int {
            self.pieceLength = pieceLength
        } else {
            return nil
        }
        
        if let pieces = dictionary["pieces"] as? NSData, piecesArray = TorrentInfoDictionary.seperatePieces(pieces) {
            self.pieces = piecesArray
        } else {
            return nil
        }
        
        if let tuple = TorrentInfoDictionary.parseFilesAndLengthFromDictionary(dictionary, parsedName: name) {
            self.files = tuple.files
            self.length = tuple.totalLength
        } else {
            return nil
        }
        
        if let isPrivate = dictionary["private"] as? Int {
            self.isPrivate = (isPrivate == 1)
        } else {
            self.isPrivate = false
        }
        
    }
    
    private class func parseFilesAndLengthFromDictionary(dictionary: [ String : AnyObject ],
                                                         parsedName name: String)
        -> (files: [TorrentFileInfo], totalLength: Int)? {
            
            if let files = dictionary["files"] as? [ [ String : AnyObject ] ] {
                
                return TorrentInfoDictionary.parseFilesDictionaries(files)
                
            } else if let length = dictionary["length"] as? Int {
                
                return TorrentInfoDictionary.parseSingleFileFromInfoDictionary(dictionary,
                                                                               parsedName: name,
                                                                               parsedLength: length)
                
            } else {
                
                return nil
                
            }
    }
    
    private class func parseSingleFileFromInfoDictionary(dictionary: [ String : AnyObject ],
                                                         parsedName name: String,
                                                         parsedLength length: Int) -> ([TorrentFileInfo], Int) {
        
        let md5sumData = dictionary["md5sum"] as? NSData
        let md5sum = String(asciiData: md5sumData)
        let files = [ TorrentFileInfo(path: name, length: length, md5sum: md5sum) ]
        
        return (files, length)
    }
    
    private class func parseFilesDictionaries(files: [ [ String : AnyObject ] ]) -> ([TorrentFileInfo], Int)? {
        
        var totalLength = 0
        var result: [TorrentFileInfo] = []
        
        for fileDictionary in files {
            
            if let file = TorrentFileInfo(dictionary: fileDictionary) {
                
                totalLength += file.length
                result.append(file)
                
            } else {
                return nil
            }
            
        }
        
        return (files: result, totalLength: totalLength)
    }
    
    private class func seperatePieces(pieces: NSData) -> [NSData]? {
        if pieces.length % 20 != 0 {
            return nil
        }
        
        var result: [NSData] = []
        for index in 0.stride(to:pieces.length, by: 20) {
            result.append(pieces.subdataWithRange(NSMakeRange(index, 20)))
        }
        return result
    }
}

class TorrentFileInfo {
    let path: String
    let length: Int
    let md5sum: String?

    init(path: String, length: Int, md5sum: String?) {
        self.path = path
        self.length = length
        self.md5sum = md5sum
    }
    
    convenience init?(dictionary: [ String : AnyObject ]) {
        
        let pathData = dictionary["path"] as? NSData
        let path = String(asciiData: pathData)
        
        let length = dictionary["length"] as? Int
        
        if let length = length, path = path {
            
            let md5sumData = dictionary["md5sum"] as? NSData
            let md5sum = String(asciiData: md5sumData)
            
            self.init(path: path, length: length, md5sum: md5sum)
            
        } else {
            return nil
        }
    }
}
