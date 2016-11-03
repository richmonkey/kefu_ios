//
//  LoginViewController.h
//
//  Copyright © 2016年 beetle. All rights reserved.

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate>
@property(nonatomic) BOOL hint;//下线提示
@end
