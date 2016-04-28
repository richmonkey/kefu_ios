//
//  CustomerMessageListViewController.h
//  im_demo
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"

@protocol MessageViewControllerUserDelegate;

@interface CustomerMessageListViewController : MainViewController
@property(nonatomic, assign) int64_t currentUID;
@property(nonatomic, assign) int64_t storeID;

@end
