//
//  LoginViewController.h
//
//  Copyright © 2016年 beetle. All rights reserved.

#import <UIKit/UIKit.h>
#import "BaseViewController.h"


@interface LoginViewController : BaseViewController <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate>
@property(nonatomic) BOOL hint;//下线提示
@end
