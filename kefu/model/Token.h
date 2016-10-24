//
//  Token.h
//  Message
//
//  Created by houxh on 14-7-8.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Token : NSObject
+(Token*)instance;
@property(copy) NSString *accessToken;
@property(copy) NSString *refreshToken;
@property(assign) int expireTimestamp;
@property(assign) int64_t uid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic) int64_t storeID;
@property(nonatomic) int loginTimestamp;

-(void)save;
@end
