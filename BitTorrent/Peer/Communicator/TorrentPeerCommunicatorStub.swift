//
//  TorrentPeerCommunicatorStub.swift
//  BitTorrentTests
//
//  Created by Ben Davis on 16/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

@testable import BitTorrent

class TorrentPeerCommunicatorStub: TorrentPeerCommunicator {
    
    var connectCalled = false
    override func connect() throws {
        connectCalled = true
    }
    
    var sendHandshakeCalled = false
    var sendHandshakeParameters: (clientId: Data, completion: (()->Void)?)?
    override func sendHandshake(for clientId: Data, _ completion: (() -> Void)?) {
        sendHandshakeCalled = true
        sendHandshakeParameters = (clientId, completion)
    }
    
    var sendBitFieldCalled = false
    var sendBitFieldParameters: (bitField: BitField, completion: (()->Void)?)?
    override func sendBitField(_ bitField: BitField, _ completion: (() -> Void)?) {
        sendBitFieldCalled = true
        sendBitFieldParameters = (bitField, completion)
    }
    
    var sendInterestedCalled = false
    var sendInterestedParameter: ((()->Void)?)?
    override func sendInterested(_ completion: (() -> Void)?) {
        sendInterestedCalled = true
        sendInterestedParameter = completion
    }
    
    var sendRequestCalled = false
    var sendRequestParameters: [(index: Int, begin: Int, length: Int, completion:(()->Void)?)] = []
    override func sendRequest(fromPieceAtIndex index: Int, begin: Int, length: Int, _ completion: (() -> Void)?) {
        sendRequestCalled = true
        sendRequestParameters.append((index, begin, length, completion))
    }
    
}
