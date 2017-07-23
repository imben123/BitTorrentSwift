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

public class TorrentMetaInfo {
    
    let infoHash : Data // this is the original BEncoded dictionary, hashed

    let info: TorrentInfoDictionary
    let announce: URL
    let announceList: [[URL]]?
    let creationDate: Date?
    let comment: String?
    let createdBy: String?
    
    public init?(data: Data) {
        
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
    
    fileprivate class func parseAnnounceList(_ announceListData: [[Data]]) -> [[URL]]? {
        
        var result: [[URL]] = []
        
        for trackersArray in announceListData {
            
            var currentArray: [URL] = []
            for trackerData in trackersArray {
                if let tracker = urlFromAsciiData(trackerData) {
                    currentArray.append(tracker)
                } else {
                    return nil
                }
            }
            result.append(currentArray)
        }
        
        return result
    }
    
    fileprivate class func urlFromAsciiData(_ asciiData: Data) -> URL? {
        guard let result = String(asciiData: asciiData) else { return nil }
        return URL(string: result)
    }
}

class TorrentInfoDictionary {
    
    let name : String
    let pieceLength : Int
    let isPrivate : Bool
    let files: [TorrentFileInfo]
    let pieces : [Data]
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
    
    func lengthOfPiece(at index: Int) -> Int {
        if index == pieces.count-1 {
            return length % pieceLength
        } else {
            return pieceLength
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

extension TorrentMetaInfo {
    
    func sensibleDownloadDirectoryName() -> String {
        if info.files.count > 1 {
            return info.name
        } else {
            let url = URL(fileURLWithPath: info.name, isDirectory: false).deletingPathExtension()
            return url.path
        }
    }
    
}

extension TorrentMetaInfo {
    
    public convenience init?(named name: String) {
        let path = Bundle.main.path(forResource: name, ofType: "torrent")
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path!)) else {
            return nil
        }
        self.init(data: data)
    }
}
