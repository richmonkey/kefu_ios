//
//  AppDelegate.m
//  kefu
//
//  Created by houxh on 16/4/6.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "AppDelegate.h"
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>

#import <gobelieve/IMService.h>
#import <gobelieve/PeerMessageHandler.h>
#import <gobelieve/GroupMessageHandler.h>
#import <gobelieve/CustomerMessageHandler.h>
#import <gobelieve/CustomerMessageDB.h>
#import <gobelieve/CustomerOutbox.h>
#import <gobelieve/IMHttpAPI.H>
#import "CustomerSupportMessageHandler.h"
#import "CustomerMessageListViewController.h"
#import "LoginViewController.h"
#import "Config.h"
#import "Token.h"
#import "ResolveUtil.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

+(AppDelegate*)instance {
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
    // Override point for customization after application launch.
    [IMHttpAPI instance].apiURL = IM_API;
    [IMService instance].host = IM_HOST;
    [IMService instance].appID = APPID;

#if TARGET_IPHONE_SIMULATOR
    [IMService instance].deviceID = @"7C8A8F5B-E5F4-4797-8758-05367D2A4D61";
    NSLog(@"device id:%@", @"7C8A8F5B-E5F4-4797-8758-05367D2A4D61");
#else
    [IMService instance].deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSLog(@"device id:%@", [[[UIDevice currentDevice] identifierForVendor] UUIDString]);
#endif

    [IMService instance].peerMessageHandler = [PeerMessageHandler instance];
    [IMService instance].groupMessageHandler = [GroupMessageHandler instance];
    [IMService instance].customerMessageHandler = [CustomerSupportMessageHandler instance];
    [[IMService instance] startRechabilityNotifier];

    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];

    Token *token = [Token instance];
    if (token.uid > 0 && token.accessToken.length > 0) {
        //已经登录
        CustomerMessageListViewController *ctrl = [[CustomerMessageListViewController alloc] init];
        UINavigationController *navigationCtrl = [[UINavigationController alloc] initWithRootViewController:ctrl];
        self.window.rootViewController = navigationCtrl;
        [self.window makeKeyAndVisible];
    } else {
        LoginViewController *ctrl = [[LoginViewController alloc] init];
        self.window.rootViewController = ctrl;
        [self.window makeKeyAndVisible];
    }
    
    [self refreshHostIP];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
   [[IMService instance] enterBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [[IMService instance] enterForeground];
    
    [self refreshHostIP];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString* newToken = [deviceToken description];
    newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"device token is:%@", newToken);
    
    self.deviceToken = newToken;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didRegisterForRemoteNotificationsWithDeviceToken"
                                                        object:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"register remote notification error:%@", error);
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"did receive remote notification:%@", userInfo);
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    if (notificationSettings.types != UIUserNotificationTypeNone) {
        NSLog(@"didRegisterUser");
        [application registerForRemoteNotifications];
    }
}


- (void)refreshHostIP {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"refresh host ip...");
        for (int i = 0; i < 10; i++) {
            NSString *host = @"imnode.gobelieve.io";
            NSString *ip = [self resolveIP:host];
            
            NSString *apiHost = @"api.gobelieve.io";
            NSString *apiIP = [self resolveIP:apiHost];
            
            NSString *kapiHost = @"api.kefu.gobelieve.io";
            NSString *kapiIP = [self resolveIP:kapiHost];
            
            NSLog(@"host:%@ ip:%@", host, ip);
            NSLog(@"api host:%@ ip:%@", apiHost, apiIP);
            NSLog(@"kefu api host:%@ ip:%@", kapiHost, kapiIP);
            if (ip.length == 0 || apiIP.length == 0 || kapiIP.length == 0) {
                continue;
            } else {
                break;
            }
        }
        
        NSString *hostIP = [ResolveUtil resolveHost:IM_HOST usingDNSServer:@"223.5.5.5"];//ali dns
        if (hostIP.length > 0) {
            NSLog(@"set im host ip:%@ %@", IM_HOST, hostIP);
            [IMService instance].hostIP = hostIP;
        }
    });
}


-(NSString*)IP2String:(struct in_addr)addr {
    char buf[64] = {0};
    const char *p = inet_ntop(AF_INET, &addr, buf, 64);
    if (p) {
        return [NSString stringWithUTF8String:p];
    }
    return nil;
    
}

-(NSString*)resolveIP:(NSString*)host {
    struct addrinfo hints;
    struct addrinfo *result, *rp;
    int s;
    
    char buf[32];
    snprintf(buf, 32, "%d", 0);
    
    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags = 0;
    
    s = getaddrinfo([host UTF8String], buf, &hints, &result);
    if (s != 0) {
        NSLog(@"get addr info error:%s", gai_strerror(s));
        return nil;
    }
    NSString *ip = nil;
    rp = result;
    if (rp != NULL) {
        struct sockaddr_in *addr = (struct sockaddr_in*)rp->ai_addr;
        ip = [self IP2String:addr->sin_addr];
    }
    freeaddrinfo(result);
    return ip;
}
@end
