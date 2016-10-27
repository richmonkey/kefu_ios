//
//  Profile.h
//  kefu
//
//  Created by houxh on 2016/10/27.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>

#define STATUS_ONLINE @"online"
#define STATUS_OFFLINE @"offline"

@interface Profile : NSObject
+(Profile*)instance;

@property(nonatomic, copy) NSString *status;
@property(nonatomic, readonly) BOOL isOnline;

@property(assign) int64_t uid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *avatar;
@property(nonatomic) int64_t storeID;
@property(nonatomic) int loginTimestamp;

- (void)load;
- (void)save;

@end
