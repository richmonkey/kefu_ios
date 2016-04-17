//
//  UIAlertView+XPAlertView.h
//  MOP
//
//  Created by XP on 4/22/14.
//  Copyright (c) 2014 NewLand. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (XPAlertView)

-(void)showWithCompletion:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))completion;

@end
