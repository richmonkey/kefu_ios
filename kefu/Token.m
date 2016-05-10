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

-(void)load {
    LevelDB *db = [AppDB instance].db;
    
    self.uid = [[db objectForKey:@"token_uid"] longLongValue];
    self.accessToken = [db objectForKey:@"token_access_token"];
    self.refreshToken = [db objectForKey:@"token_refresh_token"];
    self.storeID = [[db objectForKey:@"token_store_id"] longLongValue];
    self.name = [db objectForKey:@"token_name"];
    self.expireTimestamp = [[db objectForKey:@"token_expire"] intValue];
    self.loginTimestamp = [[db objectForKey:@"token_login"] intValue];
}

-(void)save {
    LevelDB *db = [AppDB instance].db;


    NSString *accessToken = self.accessToken ? self.accessToken : @"";
    [db setObject:accessToken forKey:@"token_access_token"];
    
    NSString *refreshToken = self.refreshToken ? self.refreshToken : @"";
    [db setObject:refreshToken forKey:@"token_refresh_token"];
    
    NSString *name = self.name ? self.name : @"";
    [db setObject:name forKey:@"token_name"];
    
    [db setObject:[NSNumber numberWithLongLong:self.storeID] forKey:@"token_store_id"];
    [db setObject:[NSNumber numberWithLongLong:self.uid] forKey:@"token_uid"];
    [db setObject:[NSNumber numberWithInt:self.expireTimestamp] forKey:@"token_expire"];
    [db setObject:[NSNumber numberWithInt:self.loginTimestamp] forKey:@"token_login"];
}

@end
