//
//  NewCount.h
//  kefu
//
//  Created by houxh on 16/4/28.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConversationDB : NSObject
+(int)getNewCount:(int64_t)uid appID:(int64_t)appID;
+(void)setNewCount:(int)count uid:(int64_t)uid appID:(int64_t)appID;

+(void)setTop:(int64_t)uid appID:(int64_t)appID top:(BOOL)top;
+(BOOL)getTop:(int64_t)uid appID:(int64_t)appID;
@end
