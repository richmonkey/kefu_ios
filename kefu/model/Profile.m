//
//  Profile.m
//  kefu
//
//  Created by houxh on 2016/10/27.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "Profile.h"

@implementation Profile

+(Profile*)instance {
    static Profile *profile;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!profile) {
            profile = [[Profile alloc] init];

        }
    });
    return profile;
}

-(id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (BOOL)isOnline {
    return [self.status isEqualToString:STATUS_ONLINE];
}

- (void)load {
    NSDictionary *dict = [self loadDictionary];
    self.status = [dict objectForKey:@"status"];
}

- (void)save {
    NSDictionary *dict = @{@"status":self.status ? self.status : @""};
    [self storeDictionary:dict];
}

-(NSDictionary*) loadDictionary {
    NSString *docPath = [self getDocumentPath];
    NSString *fullFileName = [NSString stringWithFormat:@"%@/profile", docPath];
    NSDictionary* panelLibraryContent = [NSDictionary dictionaryWithContentsOfFile:fullFileName];
    return panelLibraryContent;
}


-(void) storeDictionary:(NSDictionary*) dictionaryToStore {
    NSString *docPath = [self getDocumentPath];
    NSString *fullFileName = [NSString stringWithFormat:@"%@/profile", docPath];
    
    if (dictionaryToStore != nil) {
        [dictionaryToStore writeToFile:fullFileName atomically:YES];
    }
}

-(NSString*)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


@end
