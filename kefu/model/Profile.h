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

#define CONVERSATION_VIEW_WEEK 0 //默认值
#define CONVERSATION_VIEW_ALL 1

@interface Profile : NSObject
+(Profile*)instance;

@property(nonatomic, copy) NSString *status;
@property(nonatomic, readonly) BOOL isOnline;

@property(assign) int64_t uid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *avatar;
@property(nonatomic) int64_t storeID;
@property(nonatomic) int loginTimestamp;

@property(nonatomic, assign) int conversationView;//最近一周， 全部

- (void)load;
- (void)save;

@end
