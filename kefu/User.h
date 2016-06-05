//
//  User.h
//  kefu
//
//  Created by houxh on 16/4/28.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject
@property(nonatomic) int64_t appID;
@property(nonatomic) int64_t uid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *avatarURL;
@property(nonatomic, assign) int timestamp;

+(void)save:(User*)u;
+(User*)load:(int64_t)uid appID:(int64_t)appID;
@end
