//
//  SettingViewController.m
//  kefu
//
//  Created by 杨朋亮 on 17/4/16.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "SettingViewController.h"
#import "SettingInforTableViewCell.h"
#import "QuitTableViewCell.h"
#import "AppDB.h"
#import "LoginViewController.h"
#import <gobelieve/IMService.h>
#import <gobelieve/IMHttpAPI.h>
#import <gobelieve/CustomerMessageViewController.h>
#import "XWMessageViewController.h"
#import "Token.h"
#import "Config.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import <AFNetWorking.h>
#import "Profile.h"
#import "API.h"
#import "UIAlertView+XPAlertView.h"

@interface SettingViewController () <UITableViewDelegate,UITableViewDataSource>
@property(nonatomic) int64_t number;
@property(nonatomic, copy) NSString *name;
@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";

    Profile *profile = [Profile instance];
    self.number = profile.uid;
    self.name = profile.name ? profile.name : @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44.0f;
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section==0) {
        return 2;
    } else if (section == 1) {
        return 2;
    } else if (section == 2) {
        return 2;
    } else if (section == 3) {
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section==0) {
        static NSString *reusableCellWithIdentifier = @"SettingInforTableViewCell";
        SettingInforTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableCellWithIdentifier];
        
        if (cell == nil) {
            NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"SettingInforTableViewCell" owner:self options:nil];
            cell = [array objectAtIndex:0];
        }
        if (indexPath.row == 0) {
            [cell.nameLabel setText:@"客服工号"];
            NSString *number = [NSString stringWithFormat:@"%lld", self.number];
            [cell.valueLabel setText:number];
        }else if(indexPath.row == 1){
            [cell.nameLabel setText:@"客服姓名"];
            if (self.name.length > 0) {
                [cell.valueLabel setText:self.name];
            } else {
                [cell.valueLabel setText:@""];
            }
        }
        
        [cell.line setHidden:NO];
        if (indexPath.row==1) {
            [cell.line setHidden:YES];
        }
        
        return cell;
    } else if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell1"];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell1"];
        }

        if (indexPath.row == 0) {
           [cell.textLabel setText:@"帮助与反馈"];
        } else if(indexPath.row == 1){
            [cell.textLabel setText:@"关于我们"];
        }
        
        return cell;

    } else if (indexPath.section == 2) {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell2"];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell2"];
        }
        
        BOOL isOnline = [Profile instance].isOnline;
        if (indexPath.row == 0) {
            [cell.textLabel setText:@"在线"];
            cell.accessoryType = isOnline ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } else if(indexPath.row == 1){
            [cell.textLabel setText:@"隐身"];
            cell.accessoryType = !isOnline ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        return cell;
    } else if (indexPath.section == 3) {
        static NSString *reusableCellWithIdentifier = @"QuitTableViewCell";
        QuitTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableCellWithIdentifier];
        
        if (cell == nil) {
            NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"QuitTableViewCell" owner:self options:nil];
            cell = [array objectAtIndex:0];
            [cell.quitButton addTarget:self action:@selector(quitAction) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //取消选中项
    NSLog(@"select index path:%zd, %zd", indexPath.row, indexPath.section);
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
    
    if (indexPath.section == 1 && indexPath.row == 0) {
        //帮助与反馈
        XWMessageViewController *ctrl = [[XWMessageViewController alloc] init];
        ctrl.currentUID = [Profile instance].uid;
        ctrl.storeID = XIAOWEI_STORE_ID;
        ctrl.sellerID = XIAOWEI_SELLER_ID;
        ctrl.peerName = @"小微客服";
        ctrl.appID = APPID;
        
        [self.navigationController pushViewController:ctrl animated:YES];
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        if (![Profile instance].isOnline) {
            [self setUserStatus:YES];
        }
    } else if (indexPath.section == 2 && indexPath.row == 1) {
        if ([Profile instance].isOnline) {
            [self setUserStatus:NO];
        }
    }
}

//用户上线／下线
- (void)setUserStatus:(BOOL)online {
    AFHTTPSessionManager *manager = [API newSessionManager];
    int64_t uid = [Profile instance].uid;
    NSString *url = [NSString stringWithFormat:@"users/%lld", uid];
    NSDictionary *params = @{@"status":(online ? @"online" : @"offline")};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [manager PATCH:url
       parameters:params
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              NSLog(@"set user status success:%@", responseObject);
              [Profile instance].status = online ? STATUS_ONLINE : STATUS_OFFLINE;
              [[Profile instance] save];
              NSArray *array = @[[NSIndexPath indexPathForRow:1 inSection:2],
                                 [NSIndexPath indexPathForRow:0 inSection:2]];
              [self.tableView reloadRowsAtIndexPaths:array
                                    withRowAnimation:UITableViewRowAnimationFade];
              [MBProgressHUD hideHUDForView:self.view animated:YES];
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSLog(@"set user status failure:%@", error);
              hud.labelText = online ? @"上线失败" : @"隐身失败";
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                             dispatch_get_main_queue(),
                             ^{
                                 [MBProgressHUD hideHUDForView:self.view animated:YES];
                             });
          }
     ];
    
}

- (void)unregister {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"user.logout" object:nil];
    
    Token *token = [Token instance];
    token.accessToken = @"";
    token.refreshToken = @"";
    token.expireTimestamp = 0;
    [token save];
    
    Profile *profile = [Profile instance];
    profile.uid = 0;
    profile.name = @"";
    profile.storeID = 0;
    profile.avatar = @"";
    profile.loginTimestamp = 0;
    [profile save];
    
    [[IMService instance] sendUnreadCount:0];
    [[IMService instance] stop];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    LoginViewController *ctrl = [[LoginViewController alloc] init];
    [UIApplication sharedApplication].keyWindow.rootViewController = ctrl;
}

- (void)logout {
    NSLog(@"quit...");
    AppDelegate *app = [AppDelegate instance];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"logout.doing", @"注销中...");

    //注销接口会将当前用户设置下线状态以及解除devicetoken的绑带关系
    AFHTTPSessionManager *manager = [API newSessionManager];
    NSString *url = @"auth/unregister";
    NSDictionary *params = @{@"apns_device_token":app.deviceToken?app.deviceToken:@""};
    [manager POST:url parameters:params
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              NSLog(@"unregister client success:%@", responseObject);
              [MBProgressHUD hideHUDForView:self.view animated:NO];
              [self unregister];
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSLog(@"unregister fail:%@", error);
              hud.labelText = NSLocalizedString(@"logout.failure", @"注销失败，请检查网络是否连接");
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                             dispatch_get_main_queue(),
                             ^{
                                 [MBProgressHUD hideHUDForView:self.view animated:YES];
                             });
          }
     ];
}

- (void)quitAction{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"是否退出当前账户" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"退出",nil];
    [alert showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex==1) {
            [self logout];
        }
    }];
}

@end
