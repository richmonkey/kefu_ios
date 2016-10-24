//
//  NewCount.h
//  kefu
//
//  Created by houxh on 16/4/28.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NewCount : NSObject
+(int)getNewCount:(int64_t)uid appID:(int64_t)appID;
+(void)setNewCount:(int)count uid:(int64_t)uid appID:(int64_t)appID;
@end
