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
    self.uid = [[dict objectForKey:@"uid"] longLongValue];
    self.storeID = [[dict objectForKey:@"store_id"] longLongValue];
    self.loginTimestamp = [[dict objectForKey:@"login_timestamp"] intValue];
    self.name = [dict objectForKey:@"name"];
    self.avatar = [dict objectForKey:@"avatar"];
    self.conversationView = [[dict objectForKey:@"conversation_view"] intValue];
}

- (void)save {
    NSDictionary *dict = @{@"status":self.status ? self.status : @"",
                           @"uid":[NSNumber numberWithLongLong:self.uid],
                           @"store_id":[NSNumber numberWithLongLong:self.storeID],
                           @"login_timestamp":[NSNumber numberWithInteger:self.loginTimestamp],
                           @"name":self.name ? self.name : @"",
                           @"avatar":self.avatar ? self.avatar : @"",
                           @"conversation_view":[NSNumber numberWithInteger:self.conversationView]};
    
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
