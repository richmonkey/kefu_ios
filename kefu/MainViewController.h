//
//  MainViewController.h
//  kefu
//
//  Created by houxh on 16/4/20.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController

//observer只会触发一次
- (void)addTokenRefreshOneTimeObserver:(void(^)())onTokenRefresh;

- (void)onUserLogout:(NSNotification*) notification;

@end
