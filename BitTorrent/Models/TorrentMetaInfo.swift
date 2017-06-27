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
    
    let infoHash : Data // this is the original BEncoded dictionary, hashed

    let info: TorrentInfoDictionary
    let announce: URL
    let announceList: [[String]]?
    let creationDate: Date?
    let comment: String?
    let createdBy: String?
    
    init?(data: Data) {
        
        let decodedMetainfo = try! BEncoder.decodeStringKeyedDictionary(data)
        
        if let infoDictionary = decodedMetainfo["info"] as? [String: AnyObject],
            let info = TorrentInfoDictionary(infoDictionary) {
            self.infoHash = try! BEncoder.decodeDictionaryKeysOnly(data)["info"]!.sha1()
            self.info = info
        } else {
            return nil
        }
        
        if let announceData = decodedMetainfo["announce"],
            let announceString = String(asciiData: announceData as? Data),
            let announceURL = URL(string: announceString) {
            self.announce = announceURL
        } else {
            return nil
        }
        
        if let announceListData = decodedMetainfo["announce-list"] as? [[Data]] {
            if let announceList = TorrentMetaInfo.parseAnnounceList(announceListData) {
                self.announceList = announceList
            } else {
                return nil
            }
        } else {
            self.announceList = nil
        }
        
        if let creationDateInt = decodedMetainfo["creation date"] as? Int {
            self.creationDate = Date(timeIntervalSince1970: Double(creationDateInt))
        } else {
            self.creationDate = nil
        }
        
        if let commentString = String(asciiData: decodedMetainfo["comment"] as? Data) {
            self.comment = commentString
        } else {
            self.comment = nil
        }
        
        if let createdBy = String(asciiData: decodedMetainfo["created by"] as? Data) {
            self.createdBy = createdBy
        } else {
            self.createdBy = nil
        }
    }
    
    fileprivate class func parseAnnounceList(_ announceListData: [[Data]]) -> [[String]]? {
        
        var result: [[String]] = []
        
        for trackersArray in announceListData {
            
            var currentArray: [String] = []
            for trackerData in trackersArray {
                if let tracker = urlCompatibleStringFromAsciiData(trackerData) {
                    currentArray.append(tracker)
                } else {
                    return nil
                }
            }
            result.append(currentArray)
        }
        
        return result
    }
    
    fileprivate class func urlCompatibleStringFromAsciiData(_ asciiData: Data) -> String? {
        let result = String(asciiData: asciiData)
        
        if result == nil || URL(string: result!) == nil {
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
    let pieces : [Data]?
    let length: Int

    init?(_ dictionary: [String : AnyObject]) {
        
        if let nameData = dictionary["name"] as? Data, let name = String(asciiData: nameData) {
            self.name = name
        } else {
            return nil
        }
        
        if let pieceLength = dictionary["piece length"] as? Int {
            self.pieceLength = pieceLength
        } else {
            return nil
        }
        
        if let pieces = dictionary["pieces"] as? Data, let piecesArray = TorrentInfoDictionary.seperatePieces(pieces) {
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
    
    fileprivate class func parseFilesAndLengthFromDictionary(_ dictionary: [String: AnyObject],
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
    
    fileprivate class func parseSingleFileFromInfoDictionary(_ dictionary: [ String : AnyObject ],
                                                             parsedName name: String,
                                                             parsedLength length: Int) -> ([TorrentFileInfo], Int) {
        
        let md5sumData = dictionary["md5sum"] as? Data
        let md5sum = String(asciiData: md5sumData)
        let files = [ TorrentFileInfo(path: name, length: length, md5sum: md5sum) ]
        
        return (files, length)
    }
    
    fileprivate class func parseFilesDictionaries(_ files: [ [ String : AnyObject ] ]) -> ([TorrentFileInfo], Int)? {
        
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
    
    fileprivate class func seperatePieces(_ pieces: Data) -> [Data]? {
        if pieces.count % 20 != 0 {
            return nil
        }
        
        var result: [Data] = []
        for index in stride(from: 0, to:pieces.count, by: 20) {
            result.append(pieces.subdata(in: Range(uncheckedBounds: (lower: index, upper: index+20))))
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
        
        let pathData = dictionary["path"] as? Data
        let path = String(asciiData: pathData)
        
        let length = dictionary["length"] as? Int
        
        if let length = length, let path = path {
            
            let md5sumData = dictionary["md5sum"] as? Data
            let md5sum = String(asciiData: md5sumData)
            
            self.init(path: path, length: length, md5sum: md5sum)
            
        } else {
            return nil
        }
    }
}
