//
//  App.h
//  kefu
//
//  Created by houxh on 2017/4/23.
//  Copyright © 2017年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>

//存储顾客所来自的app信息
@interface App : NSObject
@property(nonatomic, assign) int64_t appID;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) BOOL wechat;//微信公众号



+(void)save:(App*)app;
+(App*)load:(int64_t)appID;
@end
