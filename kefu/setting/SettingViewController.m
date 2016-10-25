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

@interface SettingViewController () <UITableViewDelegate,UITableViewDataSource>
@property(nonatomic) int64_t number;
@property(nonatomic, copy) NSString *name;
@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    
    Token *token = [Token instance];
    self.number = token.uid;
    self.name = token.name ? token.name : @"";
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
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if (section==0) {
        return 2;
    } else if (section == 1) {
        return 2;
    } else if (section == 2) {
        return 1;
    }
    return 1;
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
        ctrl.currentUID = [Token instance].uid;
        ctrl.storeID = STORE_ID;
        ctrl.peerName = @"小微客服";
        ctrl.appID = APPID;
        
        [self.navigationController pushViewController:ctrl animated:YES];
    }
}

- (void)unregister {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"user.logout" object:nil];
    
    Token *token = [Token instance];
    token.uid = 0;
    token.accessToken = @"";
    token.refreshToken = @"";
    token.name = @"";
    token.storeID = 0;
    token.expireTimestamp = 0;
    [token save];
    
    [[IMService instance] sendUnreadCount:0];
    [[IMService instance] stop];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    LoginViewController *ctrl = [[LoginViewController alloc] init];
    [UIApplication sharedApplication].keyWindow.rootViewController = ctrl;
}

- (void)logout {
    NSLog(@"quit...");
    AppDelegate *app = [AppDelegate instance];
    if (app.deviceToken.length > 0) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = NSLocalizedString(@"logout.doing", @"注销中...");
        
        [IMHttpAPI unbindDeviceToken:app.deviceToken success:^{
            NSLog(@"unbind device token success");
            [MBProgressHUD hideHUDForView:self.view animated:NO];
            [self unregister];
        } fail:^{
            NSLog(@"unbind device token fail");
            hud.labelText = NSLocalizedString(@"logout.failure", @"注销失败，请检查网络是否连接");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }];
    } else {
        [self unregister];
    }
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
