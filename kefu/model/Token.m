//
//  Token.m
//  Message
//
//  Created by houxh on 14-7-8.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "Token.h"
#import "AppDB.h"


@implementation Token

+(Token*)instance {
    static Token *tok;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!tok) {
            tok = [[Token alloc] init];
            [tok load];
        }
    });
    return tok;
}

-(id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

-(BOOL)isAccessTokenExpired {
    int now = (int)time(NULL);
    if (now >= self.expireTimestamp - 10) {
        return YES;
    } else {
        return NO;
    }
}

-(void)load {
    LevelDB *db = [AppDB instance].db;
    self.accessToken = [db objectForKey:@"token_access_token"];
    self.refreshToken = [db objectForKey:@"token_refresh_token"];
    self.expireTimestamp = [[db objectForKey:@"token_expire"] intValue];
}

-(void)save {
    LevelDB *db = [AppDB instance].db;


    NSString *accessToken = self.accessToken ? self.accessToken : @"";
    [db setObject:accessToken forKey:@"token_access_token"];
    
    NSString *refreshToken = self.refreshToken ? self.refreshToken : @"";
    [db setObject:refreshToken forKey:@"token_refresh_token"];
    
    [db setObject:[NSNumber numberWithInt:self.expireTimestamp] forKey:@"token_expire"];

}

@end
