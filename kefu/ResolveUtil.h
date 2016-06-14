//
//  ResolveUtil.h
//  kefu
//
//  Created by houxh on 16/4/24.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResolveUtil : NSObject
+ (NSString *)resolveHost:(NSString *)host usingDNSServer:(NSString *)dnsServer;


@end
