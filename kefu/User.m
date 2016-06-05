//
//  User.m
//  kefu
//
//  Created by houxh on 16/4/28.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "User.h"
#import "AppDB.h"
@implementation User


+(void)save:(User*)u {
    LevelDB *db = [AppDB instance].db;
    
    NSString *key;
    NSString *keyPrefix = [NSString stringWithFormat:@"users_%lld_%lld", u.appID, u.uid];
    
    key = [NSString stringWithFormat:@"%@_appid", keyPrefix];
    [db setObject:[NSNumber numberWithLongLong:u.appID] forKey:key];
  
    key = [NSString stringWithFormat:@"%@_uid", keyPrefix];
    [db setObject:[NSNumber numberWithLongLong:u.uid] forKey:key];

    NSString *name = u.name;
    if (!name) {
        name = @"";
    }
    key = [NSString stringWithFormat:@"%@_name", keyPrefix];
    [db setObject:name forKey:key];
    
    NSString *avatarURL = u.avatarURL;
    if (!avatarURL) {
        avatarURL = @"";
    }
    key = [NSString stringWithFormat:@"%@_avatar", keyPrefix];
    [db setObject:avatarURL forKey:key];
    
    key = [NSString stringWithFormat:@"%@_timestamp", keyPrefix];
    [db setObject:[NSNumber numberWithInt:u.timestamp] forKey:key];
}

+(User*)load:(int64_t)uid appID:(int64_t)appID {
    User *u = [[User alloc] init];
    
    LevelDB *db = [AppDB instance].db;
    
    NSString *key;
    NSString *keyPrefix = [NSString stringWithFormat:@"users_%lld_%lld", appID, uid];

    u.appID = appID;
    u.uid = uid;
    
    key = [NSString stringWithFormat:@"%@_name", keyPrefix];
    u.name = [db objectForKey:key];
    
    key = [NSString stringWithFormat:@"%@_avatar", keyPrefix];
    u.avatarURL = [db objectForKey:key];
    
    key = [NSString stringWithFormat:@"%@_timestamp", keyPrefix];
    u.timestamp = [[db objectForKey:key] intValue];
    
    return u;
}
@end
