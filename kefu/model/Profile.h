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

- (void)load;
- (void)save;

@end
