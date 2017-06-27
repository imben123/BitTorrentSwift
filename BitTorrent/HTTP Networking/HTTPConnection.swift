//
//  HTTPConnection.swift
//  BitTorrent
//
//  Created by Ben Davis on 27/06/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation
import Alamofire

struct HTTPResponse {
    let completed: Bool
    let responseData: Data?
    let statusCode: Int
    
    init(completed: Bool, responseData: Data? = nil, statusCode: Int = 0) {
        self.completed = completed
        self.responseData = responseData
        self.statusCode = statusCode;
    }
    
    init(response: DataResponse<Data>) {
        
        guard let data = response.data,
            let httpResponse = response.response,
            response.error == nil else {
                
                self.init(completed: false)
                return
        }
        
        self.init(completed: true, responseData: data, statusCode: httpResponse.statusCode)
    }
}

protocol BasicHTTPConnection {
    func makeRequest(url: URL, urlParameters: [String: String]?, completion: @escaping (HTTPResponse)->Void)
}

class HTTPConnection: BasicHTTPConnection {
    
    func makeRequest(url: URL, urlParameters: [String: String]? = nil, completion: @escaping (HTTPResponse)->Void) {
        
        
        // TODO: Think of a way to fix this...
        class ParameterEncodingFixer: ParameterEncoding {
            
            func encode(_ requestConvertable: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
                
                let urlEncoding = URLEncoding()
                
                guard parameters != nil else {
                    return try urlEncoding.encode(requestConvertable, with: nil)
                }
                
                var newParameters = parameters
                newParameters!.removeValue(forKey: "info_hash")
                
                var result = try urlEncoding.encode(requestConvertable, with: newParameters)
                
                if let infoHash: String = parameters?["info_hash"] as? String {
                    let newURL = result.url!.absoluteString + "&info_hash=" + infoHash
                    result.url = URL(string: newURL)
                }
                
                return result;
            }
            
        }
        
        let encoding: ParameterEncoding = ParameterEncodingFixer()
        
        Alamofire.request(url, parameters: urlParameters, encoding: encoding).responseData { response in
            completion(HTTPResponse(response: response))
        }
    }
    
}
