//
//  InternetProtocol.swift
//  BitTorrent
//
//  Created by Ben Davis on 03/07/2017.
//  Copyright © 2017 Ben Davis. All rights reserved.
//

import Foundation

struct InternetProtocol {
    
    static let IOS_CELLULAR_INTERFACE_NAME = "pdp_ip0"
    static let IOS_WIFI_INTERFACE_NAME = "en0"
    static let IP_ADDR_IPv4_INTERFACE_NAME = "ipv4"
    static let IP_ADDR_IPv6_INTERFACE_NAME = "ipv6"
    
    static func ipAddress(fromSockAddrData data: Data) -> String? {
        let socketAddress = data.withUnsafeBytes() { (pointer: UnsafePointer<sockaddr_in>) in
            return pointer.pointee
        }
        guard let resultCString = inet_ntoa(socketAddress.sin_addr) else {
            return nil
        }
        return String(cString: resultCString)
    }
    
    static func port(fromSockAddrData data: Data) -> UInt16 {
        let socketAddress = data.withUnsafeBytes() { (pointer: UnsafePointer<sockaddr_in>) in
            return pointer.pointee
        }
        return socketAddress.sin_port
    }
    
    static func getIPAddress(of hostname: String) -> String? {
        
        guard let hostnameCString = hostname.cString(using: .ascii),
            let hostEntry = gethostbyname(hostnameCString)?.pointee,
            let hostAddressList = hostEntry.h_addr_list?.pointee else {
                return nil
        }
        
        let firstHostAddress = hostAddressList.withMemoryRebound(to: in_addr.self, capacity: 1) { $0.pointee }
        let firstHostAddressCString = inet_ntoa(firstHostAddress)!
        return String(cString: firstHostAddressCString)
    }
    
    static func getLocalIPAddress(preferIPv4: Bool = true) -> String? {
        
        // Prefer wifi over cellular
        let searchArray = [
            ifaddrs.nameAndTypeString(from: IOS_WIFI_INTERFACE_NAME, isIpv4: preferIPv4),
            ifaddrs.nameAndTypeString(from: IOS_WIFI_INTERFACE_NAME, isIpv4: !preferIPv4),
            ifaddrs.nameAndTypeString(from: IOS_CELLULAR_INTERFACE_NAME, isIpv4: preferIPv4),
            ifaddrs.nameAndTypeString(from: IOS_CELLULAR_INTERFACE_NAME, isIpv4: !preferIPv4),
            ]
        
        let addresses = getLocalIPAddresses()
        
        for searchItem in searchArray {
            if let result = addresses[searchItem] {
                return result
            }
        }
        
        return nil
    }
    
    static func getLocalIPAddresses() -> [String: String] {
        
        var addresses: [String: String] = [:]
        
        // Get list of all network interfaces on the local machine:
        var ifaddrsPointer : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrsPointer) == 0, let ifaddrsList = ifaddrsPointer?.pointee else {
            return [:]
        }
        
        // For each network interface ...
        for ifaddrs in ifaddrsList {
            if !ifaddrs.isUpAndRunning || ifaddrs.isLoopbackNet {
                continue
            }
            
            if ifaddrs.isIpv4 || ifaddrs.isIpv6 {
                if let addressString = ifaddrs.convertToIPString(), let name = ifaddrs.nameAndTypeString() {
                    addresses[name] = addressString
                }
            }
        }
        
        freeifaddrs(ifaddrsPointer)
        
        return addresses
    }
}


public class ifaddrsIterator: IteratorProtocol {
    public typealias Element = ifaddrs
    
    var nextElement: ifaddrs?
    
    init(first: ifaddrs) {
        nextElement = first
    }
    
    public func next() -> ifaddrs? {
        let result = nextElement
        nextElement = result?.ifa_next?.pointee
        return result
    }
}

extension ifaddrs: Sequence {
    public func makeIterator() -> ifaddrsIterator {
        return ifaddrsIterator(first: self)
    }
}

extension ifaddrs {
    
    var name: String {
        return String(cString: ifa_name)
    }
    
    var isIpv4: Bool {
        let addr = ifa_addr.pointee
        return addr.sa_family == UInt8(AF_INET)
    }
    
    var isIpv6: Bool {
        let addr = ifa_addr.pointee
        return addr.sa_family == UInt8(AF_INET6)
    }
    
    var isUpAndRunning: Bool {
        let flags = Int32(ifa_flags)
        let upAndRunningFlags = (IFF_UP|IFF_RUNNING)
        return (flags & upAndRunningFlags) == upAndRunningFlags
    }
    
    var isLoopbackNet: Bool {
        let flags = Int32(ifa_flags)
        return (flags & IFF_LOOPBACK) == IFF_LOOPBACK
    }
    
    func convertToIPString() -> String? {
        return ifa_addr.pointee.toString()
    }
    
    func nameAndTypeString() -> String? {
        
        guard isIpv4 || isIpv6 else {
            return nil
        }
        
        return ifaddrs.nameAndTypeString(from: name, isIpv4: isIpv4)
    }
    
    static func nameAndTypeString(from name: String, isIpv4: Bool) -> String {
        return name + "/" + (isIpv4 ?
            InternetProtocol.IP_ADDR_IPv4_INTERFACE_NAME :
            InternetProtocol.IP_ADDR_IPv6_INTERFACE_NAME)
    }
}

extension sockaddr {
    
    func toString() -> String? {
        
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        var addr = self
        
        guard getnameinfo(&addr,
                          socklen_t(addr.sa_len),
                          &hostname,
                          socklen_t(hostname.count),
                          nil,
                          socklen_t(0),
                          NI_NUMERICHOST) == 0 else { return nil }
        
        return String(validatingUTF8: hostname)
    }
}
