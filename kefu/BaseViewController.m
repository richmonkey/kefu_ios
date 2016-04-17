//
//  BaseViewController.m
//  kefu
//
//  Created by 杨朋亮 on 17/4/16.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    int imageSize = 30; //REPLACE WITH YOUR IMAGE WIDTH
    
    UIImage *barBackBtnImg = [[UIImage imageNamed:@"back"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, imageSize, 0, 0)];
    UIBarButtonItem *barButtonItemLeft=[[UIBarButtonItem alloc] initWithImage:barBackBtnImg
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(backAction)];
    [self.navigationItem setLeftBarButtonItem:barButtonItemLeft];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

/*
 //取消键盘
 [[self findFirstResponderBeneathView:self.view] resignFirstResponder];
 */
- (UIView*)findFirstResponderBeneathView:(UIView*)view{
    
    // Search recursively for first responder
    for ( UIView *childView in view.subviews ) {
        if ( [childView respondsToSelector:@selector(isFirstResponder)] && [childView isFirstResponder] )
            return childView;
        UIView *result = [self findFirstResponderBeneathView:childView];
        if ( result )
            return result;
    }
    return nil;
}

- (void)backAction{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
