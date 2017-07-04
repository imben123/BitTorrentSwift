//
//  InternetProtocol.m
//  BitTorrent
//
//  Created by Ben Davis on 16/11/2014.
//  Copyright (c) 2014 Ben Davis. All rights reserved.
//

#import "InternetProtocol.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <netdb.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

@implementation InternetProtocol

+ (NSString *)getIPAddress:(BOOL)preferIPv4 {
    NSArray *searchArray = preferIPv4 ?
    @[ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         if(address) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

+ (NSDictionary *)getIPAddresses {
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

+(NSString *)ipAddressOfHostname:(NSString *)hostName {
    struct hostent *host_entry = gethostbyname([hostName cStringUsingEncoding:NSASCIIStringEncoding]);
    char *buff;
    if (host_entry != NULL) {
        buff = inet_ntoa(*((struct in_addr *)host_entry->h_addr_list[0]));
        NSString *ip = [NSString stringWithUTF8String:buff];
        return ip;
    } else {
        return nil;
    }
}

+ (NSString*)ipAddressFromSockAddrData:(NSData*)data {
    struct sockaddr_in * socketAddress = (struct sockaddr_in *)data.bytes;
    struct	in_addr ipAsStruct = ((struct sockaddr_in)*(socketAddress)).sin_addr;
    char *buff;
    buff = inet_ntoa(ipAsStruct);
    NSString *ip = [NSString stringWithUTF8String:buff];
    return ip;
}

+ (uint16_t)portFromSockAddrData:(NSData*)data {
    struct sockaddr_in * socketAddressPtr = (struct sockaddr_in *)data.bytes;
    struct sockaddr_in socketAddress = ((struct sockaddr_in)*(socketAddressPtr));
    return socketAddress.sin_port;
}

@end
