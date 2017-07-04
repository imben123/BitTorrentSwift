//
//  InternetProtocol.h
//  BitTorrent
//
//  Created by Ben Davis on 16/11/2014.
//  Copyright (c) 2014 Ben Davis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InternetProtocol : NSObject

+ (NSString *)getIPAddress:(BOOL)preferIPv4;
+ (NSDictionary *)getIPAddresses;

+ (NSString*)ipAddressOfHostname:(NSString*)hostName;

+ (NSString*)ipAddressFromSockAddrData:(NSData*)data;
+ (uint16_t)portFromSockAddrData:(NSData*)data;

@end
