//
//  AppDB.m
//  kefu
//
//  Created by houxh on 16/4/7.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "AppDB.h"

@implementation AppDB
+(AppDB*)instance {
    static AppDB *db = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!db) {
            db = [[AppDB alloc] init];
        }
    });
    
    return db;
}

- (AppDB*)init {
    self = [super init];
    if (self) {
        self.db = [LevelDB databaseInLibraryWithName:@"kefu.ldb"];
    }
    return self;
}

@end
