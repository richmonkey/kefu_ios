//
//  NewCount.m
//  kefu
//
//  Created by houxh on 16/4/28.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "ConversationDB.h"
#import "AppDB.h"
@implementation ConversationDB
+(int)getNewCount:(int64_t)uid appID:(int64_t)appID {
    LevelDB *db = [AppDB instance].db;
    
    NSString *key = [NSString stringWithFormat:@"news_%lld_%lld", appID, uid];
    return [[db objectForKey:key] intValue];
}

+(void)setNewCount:(int)count uid:(int64_t)uid appID:(int64_t)appID {
    LevelDB *db = [AppDB instance].db;
    
    NSString *key = [NSString stringWithFormat:@"news_%lld_%lld", appID, uid];
    [db setObject:[NSNumber numberWithInt:count] forKey:key];
}

+(void)setTop:(int64_t)uid appID:(int64_t)appID top:(BOOL)top {
    LevelDB *db = [AppDB instance].db;
    
    NSString *key = [NSString stringWithFormat:@"top_%lld_%lld", appID, uid];
    [db setObject:[NSNumber numberWithBool:top] forKey:key];
}
+(BOOL)getTop:(int64_t)uid appID:(int64_t)appID {
    LevelDB *db = [AppDB instance].db;
    
    NSString *key = [NSString stringWithFormat:@"top_%lld_%lld", appID, uid];
    return [[db objectForKey:key] boolValue];
}
@end
