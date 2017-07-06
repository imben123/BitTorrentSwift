//
//  TorrentUDPTrackerTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 04/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import XCTest
@testable import BitTorrent
import BEncode

class UDPConnectionStub: UDPConnectionProtocol {
    
    weak var delegate: UDPConnectionDelegate?
    
    var startListeningCalled = false
    var startListeningParameter: UInt16?
    func startListening(on port: UInt16) {
        startListeningCalled = true
        startListeningParameter = port
    }
    
    var sendCallCount = 0
    var sendDataParameters: (data: Data, host: String, port: UInt16, timeout: TimeInterval)?
    func send(_ data: Data, toHost host: String, port: UInt16, timeout: TimeInterval) {
        sendCallCount += 1
        sendDataParameters = (data, host, port, timeout)
    }
}

class TorrentUDPTrackerTests: XCTestCase {
    
    var sut: TorrentUDPTracker!
    var torrentTrackerDelegateSpy: TorrentTrackerDelegateSpy!
    var udpConnection: UDPConnectionStub!
    let port: UInt16 = 123
    
    override func setUp() {
        super.setUp()
        
        let url = URL(string: "udp://localhost:123/announce")!
        udpConnection = UDPConnectionStub()
        torrentTrackerDelegateSpy = TorrentTrackerDelegateSpy()
        sut = TorrentUDPTracker(announceURL: url, port: 123, udpConnection: udpConnection)
        sut.delegate = torrentTrackerDelegateSpy
    }
    
    func performAnnounce(withEvent event: TorrentTrackerEvent) {
        sut.announceClient(with: "peerId12345678901234",
                           port: 789,
                           event: event,
                           infoHash: Data(bytes: [ 1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0 ]),
                           numberOfBytesRemaining: 456,
                           numberOfBytesUploaded: 1234,
                           numberOfBytesDownloaded: 4321,
                           numberOfPeersToFetch: 321)
    }
    
    func test_startsListeningOnPort() {
        XCTAssert(udpConnection.startListeningCalled)
        XCTAssertEqual(udpConnection.startListeningParameter, port)
    }
    
    func test_hostIsResolvedFromURL() {
        
        performAnnounce(withEvent: .started)
        
        XCTAssertEqual(udpConnection.sendCallCount, 1)
        
        if let parameters = udpConnection.sendDataParameters {
            XCTAssertEqual(parameters.host, "127.0.0.1")
            XCTAssertEqual(parameters.port, 123)
        }
    }
    
    func test_connectMessageSentToHost() {
        
        performAnnounce(withEvent: .started)
                
        let expectedProtocolId = UInt64(0x41727101980).toData()
        let expectedAction = UInt32(0).toData()
        
        XCTAssertEqual(udpConnection.sendCallCount, 1)
        
        if let parameters = udpConnection.sendDataParameters {
            
            XCTAssertEqual(parameters.data.count, 16)
            
            let protocolId = Data(parameters.data[0..<8])
            XCTAssertEqual(protocolId, expectedProtocolId)
            
            let action = Data(parameters.data[8..<12])
            XCTAssertEqual(action, expectedAction)
            
            XCTAssertEqual(parameters.host, "127.0.0.1")
            XCTAssertEqual(parameters.port, 123)
        }
    }
    
    func test_announceSentOnConnectionAccepted() {
        
        // Given
        performAnnounce(withEvent: .started)
        
        // When
        let expectedAction = UInt32(1).toData()
        let expectedConnectionId = simulateAcceptConnection()
        
        // Then
        XCTAssertEqual(udpConnection.sendCallCount, 2)
        if let parameters = udpConnection.sendDataParameters {
            
            let connectionId = Data(parameters.data[0..<8])
            XCTAssertEqual(connectionId, expectedConnectionId)
            
            let action = Data(parameters.data[8..<12])
            XCTAssertEqual(action, expectedAction)
        }
    }
    
    func test_announcePayload() {
        
        let peerId = "peerId12345678901234"
        let exampleEvent = TorrentTrackerEvent.started
        let examplePort = 789
        let expectedInfoHash = Data(bytes: [ 1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0 ])
        let numberOfBytesRemaining = 456
        let numberOfBytesUploaded = 1234
        let numberOfBytesDownloaded = 4321
        let numberOfPeersToFetch = 321
        
        // Given
        sut.announceClient(with: peerId,
                           port: examplePort,
                           event: exampleEvent,
                           infoHash: expectedInfoHash,
                           numberOfBytesRemaining: numberOfBytesRemaining,
                           numberOfBytesUploaded: numberOfBytesUploaded,
                           numberOfBytesDownloaded: numberOfBytesDownloaded,
                           numberOfPeersToFetch: numberOfPeersToFetch)
        // When
        let expectedConnectionId    = simulateAcceptConnection()
        let expectedAction          = UInt32(1).toData()
        let expectedPeerId          = peerId.data(using: .ascii)!
        let expectedDownloaded      = UInt64(numberOfBytesDownloaded).toData()
        let expectedLeft            = UInt64(numberOfBytesRemaining).toData()
        let expectedUploaded        = UInt64(numberOfBytesUploaded).toData()
        let expectedEvent           = exampleEvent.udpDataRepresentation
        let expectedIPAddress       = UInt32(0).toData() // default value
        let expectedNumWant         = UInt32(numberOfPeersToFetch).toData()
        let expectedPort            = UInt16(examplePort).toData()
        
        // Then
        XCTAssertEqual(udpConnection.sendCallCount, 2)
        if let data = udpConnection.sendDataParameters?.data {
            
            XCTAssertEqual(data.count, 98)
            
            let connectionId = Data(data[0..<8])
            let action = Data(data[8..<12])
//          let transactionId = Data(data[12..<16])
            let infoHash = Data(data[16..<36])
            let peerId = Data(data[36..<56])
            let downloaded = Data(data[56..<64])
            let left = Data(data[64..<72])
            let uploaded = Data(data[72..<80])
            let event = Data(data[80..<84])
            let ipAddress = Data(data[84..<88])
//          let key = Data(data[88..<92])
            let numWant = Data(data[92..<96])
            let port = Data(data[96..<98])
            
            XCTAssertEqual(connectionId, expectedConnectionId)
            XCTAssertEqual(action, expectedAction)
            XCTAssertEqual(infoHash, expectedInfoHash)
            XCTAssertEqual(peerId, expectedPeerId)
            XCTAssertEqual(downloaded, expectedDownloaded)
            XCTAssertEqual(left, expectedLeft)
            XCTAssertEqual(uploaded, expectedUploaded)
            XCTAssertEqual(event, expectedEvent)
            XCTAssertEqual(ipAddress, expectedIPAddress)
            XCTAssertEqual(numWant, expectedNumWant)
            XCTAssertEqual(port, expectedPort)
        }
    }
    
    func test_basicResponseParsing() {
        
        performAnnounce(withEvent: .started)
        _ = simulateAcceptConnection()
        
        let interval = 1
        let seeders = 2
        let leechers = 3
        
        simulateAnnounceResponse(interval: interval,
                                 leechers: leechers,
                                 seeders: seeders,
                                 peers: Data())
        
        XCTAssert(torrentTrackerDelegateSpy.receivedResponseCalled)
        guard let response = torrentTrackerDelegateSpy.receivedResponseParameter else { return }
        
        XCTAssertEqual(response.interval, 1)
        XCTAssertEqual(response.numberOfPeersComplete, seeders)
        XCTAssertEqual(response.numberOfPeersIncomplete, leechers)
        XCTAssertEqual(response.peers, [])
    }
    
    func test_parsingPeers() {
        
        performAnnounce(withEvent: .started)
        _ = simulateAcceptConnection()
        
        let peers = examplePeersResponse(with: [
            (127,0,0,1, 15383),
            (216,58,198,14, 4321),
            ])
        
        simulateAnnounceResponse(interval: 1,
                                 leechers: 2,
                                 seeders: 3,
                                 peers: peers)
        
        XCTAssert(torrentTrackerDelegateSpy.receivedResponseCalled)
        guard let response = torrentTrackerDelegateSpy.receivedResponseParameter else { return }
        
        XCTAssertEqual(response.peers.count, 2)
        
        XCTAssertEqual(response.peers.first!.ip, "127.0.0.1")
        XCTAssertEqual(response.peers.first!.port, 15383)
        XCTAssertNil(response.peers.first!.peerId)
        
        XCTAssertEqual(response.peers.last!.ip, "216.58.198.14")
        XCTAssertEqual(response.peers.last!.port, 4321)
        XCTAssertNil(response.peers.last!.peerId)
    }
    
    func examplePeersResponse(with peers: [(UInt8, UInt8, UInt8, UInt8, UInt16)]) -> Data {
        
        var result = Data()
        for peer in peers {
            
            let ip = Data(bytes: [peer.0, peer.1, peer.2, peer.3])
            result.append(ip)
            
            let port = peer.4.toData()
            result.append(port)
        }
        
        return result
    }
    
    func test_announceMessageForOldTransactionIdIsIgnored() {
        
        // Given
        performAnnounce(withEvent: .started)
        _ = simulateAcceptConnection()
        guard let connectionParameters = udpConnection.sendDataParameters else { return }
        let oldTransactionId = connectionParameters.data[4..<8]
        
        // When
        performAnnounce(withEvent: .started)
        _ = simulateAcceptConnection()
        simulateAnnounceResponse(interval: 1, leechers: 2, seeders: 3, peers: Data(), transactionId: oldTransactionId)
        
        // Then
        XCTAssertFalse(torrentTrackerDelegateSpy.receivedResponseCalled)
    }
    
    func test_connectionMessageForOldTransactionIdIsIgnored() {
        
        // Given
        performAnnounce(withEvent: .started)
        guard let connectionParameters = udpConnection.sendDataParameters else { return }
        let oldTransactionId = connectionParameters.data[4..<8]
        
        // When
        performAnnounce(withEvent: .started)
        
        let connectionId = arc4random().toData() + arc4random().toData()
        let actionData = UInt32(0).toData() // Action 0 = connection
        let connectionResponse = actionData + oldTransactionId + connectionId
        
        udpConnection.delegate?.udpConnection(udpConnection,
                                              receivedData: connectionResponse,
                                              fromHost: "127.0.0.1")
        
        // Then
        XCTAssertEqual(udpConnection.sendCallCount, 2)
    }
    
    // MARK: -
    
    func simulateAnnounceResponse(interval: Int,
                                  leechers: Int,
                                  seeders: Int,
                                  peers: Data) {
        
        guard let announceParameters = udpConnection.sendDataParameters else { return }
        let transactionId = announceParameters.data[12..<16]
        
        simulateAnnounceResponse(interval: interval,
                                 leechers: leechers,
                                 seeders: seeders,
                                 peers: peers,
                                 transactionId: transactionId)
    }
    
    func simulateAnnounceResponse(interval: Int,
                                  leechers: Int,
                                  seeders: Int,
                                  peers: Data,
                                  transactionId: Data) {
        
        var announceResponse = UInt32(1).toData()
        announceResponse += transactionId
        announceResponse += UInt32(interval).toData()
        announceResponse += UInt32(leechers).toData()
        announceResponse += UInt32(seeders).toData()
        announceResponse += peers
        
        udpConnection.delegate?.udpConnection(udpConnection,
                                              receivedData: announceResponse,
                                              fromHost: "127.0.0.1")
    }
    
    func simulateAcceptConnection() -> Data {
        
        let connectionId = arc4random().toData() + arc4random().toData()
        
        guard let connectionParameters = udpConnection.sendDataParameters else {
            return connectionId
        }
        
        let transactionId = connectionParameters.data[12..<16]
        let actionData = UInt32(0).toData() // Action 0 = connection
        let connectionResponse = actionData + transactionId + connectionId
        
        udpConnection.delegate?.udpConnection(udpConnection,
                                              receivedData: connectionResponse,
                                              fromHost: "127.0.0.1")
        
        return connectionId
    }
    
    // MARK: - Error handling
    
    func delegateCalledOnError() {
        simulateErrorResponse(withError: "Error Message")
        
        XCTAssert(torrentTrackerDelegateSpy.receivedErrorMessageCalled)
        XCTAssertEqual(torrentTrackerDelegateSpy.receivedErrorMessageParameter!, "Error Message")
    }
    
    func simulateErrorResponse(withError errorString: String) {
        
        guard let connectionParameters = udpConnection.sendDataParameters else { return }
        let transactionId = connectionParameters.data[4..<8]
        
        let connectionResponse = UInt32(3).toData() +   // Action 3 = error
            transactionId +                             // Responding to transaction
            errorString.data(using: .utf8)!             // Error message
        
        udpConnection.delegate?.udpConnection(udpConnection,
                                              receivedData: connectionResponse,
                                              fromHost: "127.0.0.1")
    }
}
