//
//  BaseViewController.h
//  kefu
//
//  Created by 杨朋亮 on 17/4/16.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+Toast.h"
#import "UIAlertView+XPAlertView.h"



@interface BaseViewController : UIViewController



- (UIView*)findFirstResponderBeneathView:(UIView*)view;

- (void)backAction;


@end
