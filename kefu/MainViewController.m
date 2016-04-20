//
//  MainViewController.m
//  kefu
//
//  Created by houxh on 16/4/20.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "MainViewController.h"
#import <gobelieve/IMessage.h>
#import <gobelieve/IMService.h>
#import <gobelieve/PeerMessageDB.h>
#import <gobelieve/GroupMessageDB.h>
#import <gobelieve/CustomerMessageDB.h>
#import <gobelieve/PeerMessageViewController.h>
#import <gobelieve/GroupMessageViewController.h>
#import "CustomerSupportMessageDB.h"
#import "CustomerSupportViewController.h"
#import "MessageConversationCell.h"
#import "LevelDB.h"
#import "AFNetworking.h"
#import "CustomerConversation.h"
#import <gobelieve/IMHttpAPI.h>
#import <gobelieve/IMService.h>

#import "Token.h"
#import "Config.h"

@interface MainViewController()
@property(nonatomic) dispatch_source_t refreshTimer;
@property(nonatomic) int refreshFailCount;
@property(nonatomic, copy) NSString *deviceToken;
@end

@implementation MainViewController

- (void)dealloc {
    NSLog(@"MainViewController dealloc");
   [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString*)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    Token *token = [Token instance];
    
    //配置消息存储路径
    NSString *path = [self getDocumentPath];
    NSString *customerPath = [NSString stringWithFormat:@"%@/%lld/customer", path, token.uid];
    [[CustomerSupportMessageDB instance] setDbPath:customerPath];
    
    //初始化im服务
    [IMHttpAPI instance].accessToken = token.accessToken;
    [IMService instance].uid = token.uid;
    [IMService instance].token = token.accessToken;
    
    [[IMService instance] start];
    
    //获取apns的devicetoken
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert
                                                                                         | UIUserNotificationTypeBadge
                                                                                         | UIUserNotificationTypeSound) categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRegisterForRemoteNotificationsWithDeviceToken:) name:@"didRegisterForRemoteNotificationsWithDeviceToken" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(onUserLogout:) name:@"user.logout" object:nil];

    //刷新access token
    __weak MainViewController *wself = self;
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.refreshTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_event_handler(self.refreshTimer, ^{
        [wself refreshAccessToken];
    });
    
    [self startRefreshTimer];
}


-(void)prepareTimer {
    Token *token = [Token instance];
    int now = (int)time(NULL);
    if (now >= token.expireTimestamp - 1) {
        dispatch_time_t w = dispatch_walltime(NULL, 0);
        dispatch_source_set_timer(self.refreshTimer, w, DISPATCH_TIME_FOREVER, 0);
    } else {
        dispatch_time_t w = dispatch_walltime(NULL, (token.expireTimestamp - now - 1)*NSEC_PER_SEC);
        dispatch_source_set_timer(self.refreshTimer, w, DISPATCH_TIME_FOREVER, 0);
    }
}

-(void)startRefreshTimer {
    [self prepareTimer];
    dispatch_resume(self.refreshTimer);
}

-(void)refreshAccessToken {
    Token *token = [Token instance];
    if (!token.accessToken) {
        return;
    }
    
    NSString *base = [NSString stringWithFormat:@"%@/", KEFU_API];
    NSURL *baseURL = [NSURL URLWithString:base];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSDictionary *dict = @{@"refresh_token":token.refreshToken};
    
    [manager POST:@"auth/refresh_token"
       parameters:dict
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              NSLog(@"refresh token success:%@", responseObject);
              token.accessToken = [responseObject objectForKey:@"access_token"];
              token.refreshToken = [responseObject objectForKey:@"refresh_token"];
              token.uid = [[responseObject objectForKey:@"uid"] longLongValue];
              token.storeID = [[responseObject objectForKey:@"store_id"] longLongValue];
              token.name = [responseObject objectForKey:@"name"];
              token.expireTimestamp = (int)time(NULL) + [[responseObject objectForKey:@"expires_in"] intValue];
              [token save];
              [self prepareTimer];
              
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSLog(@"refresh token failure");
              
              self.refreshFailCount = self.refreshFailCount + 1;
              int64_t timeout;
              if (self.refreshFailCount > 60) {
                  timeout = 60*NSEC_PER_SEC;
              } else {
                  timeout = (int64_t)self.refreshFailCount*NSEC_PER_SEC;
              }
              
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout), dispatch_get_main_queue(), ^{
                  [self prepareTimer];
              });
              
          }
     ];
    
    
}


-(void)didRegisterForRemoteNotificationsWithDeviceToken:(NSNotification*)notification {
    NSData *deviceToken = (NSData*)notification.object;
    
    NSString* newToken = [deviceToken description];
    newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [IMHttpAPI bindDeviceToken:newToken
                       success:^{
                           NSLog(@"bind device token success");
                           self.deviceToken = newToken;
                       }
                          fail:^{
                              NSLog(@"bind device token fail");
                          }];
}


- (void)onUserLogout:(NSNotification*) notification {
    if (self.deviceToken.length > 0) {
        [IMHttpAPI unbindDeviceToken:self.deviceToken success:^{
            NSLog(@"unbind device token success");
        } fail:^{
            NSLog(@"unbind device token fail");
        }];
    }
}

@end
