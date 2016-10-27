//
//  API.m
//  kefu
//
//  Created by houxh on 2016/10/27.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "API.h"
#import "Config.h"
#import "AFNetworking.h"
#import "Token.h"
@implementation API

+(AFHTTPSessionManager*)newSessionManager {
    NSString *base = [NSString stringWithFormat:@"%@/", KEFU_API];
    NSURL *baseURL = [NSURL URLWithString:base];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [Token instance].accessToken];
    [manager.requestSerializer setValue:auth forHTTPHeaderField:@"Authorization"];
    return manager;
}

+(AFHTTPSessionManager*)newLoginSessionManager {
    NSString *base = [NSString stringWithFormat:@"%@/", KEFU_API];
    NSURL *baseURL = [NSURL URLWithString:base];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    return manager;
}

@end
