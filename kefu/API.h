//
//  API.h
//  kefu
//
//  Created by houxh on 2016/10/27.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AFHTTPSessionManager;
@interface API : NSObject
+(AFHTTPSessionManager*)newSessionManager;
+(AFHTTPSessionManager*)newLoginSessionManager;

@end
