//
//  App.m
//  kefu
//
//  Created by houxh on 2017/4/23.
//  Copyright © 2017年 beetle. All rights reserved.
//

#import "App.h"
#import "AppDB.h"

@implementation App

+(void)save:(App*)app {
    LevelDB *db = [AppDB instance].db;
    
    NSString *key;
    NSString *keyPrefix = [NSString stringWithFormat:@"apps_%lld", app.appID];
    
    key = [NSString stringWithFormat:@"%@_appid", keyPrefix];
    [db setObject:[NSNumber numberWithLongLong:app.appID] forKey:key];
    
    NSString *name = app.name;
    if (!name) {
        name = @"";
    }
    key = [NSString stringWithFormat:@"%@_name", keyPrefix];
    [db setObject:name forKey:key];
    

    key = [NSString stringWithFormat:@"%@_wechat", keyPrefix];
    [db setObject:[NSNumber numberWithBool:app.wechat] forKey:key];
}

+(App*)load:(int64_t)appID {
    App *app = [[App alloc] init];
    
    LevelDB *db = [AppDB instance].db;
    
    NSString *key;
    NSString *keyPrefix = [NSString stringWithFormat:@"apps_%lld", appID];
    
    app.appID = appID;
    
    key = [NSString stringWithFormat:@"%@_name", keyPrefix];
    app.name = [db objectForKey:key];
    
    key = [NSString stringWithFormat:@"%@_avatar", keyPrefix];
    app.wechat = [[db objectForKey:key] boolValue];

    return app;
}
@end
