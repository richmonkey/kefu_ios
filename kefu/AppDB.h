//
//  AppDB.h
//  kefu
//
//  Created by houxh on 16/4/7.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LevelDB.h"
@interface AppDB : NSObject

@property(nonatomic) LevelDB *db;

+(AppDB*)instance;
@end
