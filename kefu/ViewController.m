//
//  ViewController.m
//  kefu
//
//  Created by houxh on 16/4/6.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "ViewController.h"
#import "Masonry.h"
#import "AFNetworking.h"
#import "LevelDB.h"
#import "MBProgressHUD.h"
#import "CustomerMessageListViewController.h"
#import <gobelieve/IMService.h>
#import "AppDB.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)handleTap:(id)sender {
    [self.view endEditing:NO];
}

- (IBAction)onLogin:(id)sender {
    [self login:@"13800000000@gobelieve.io" password:@"11111111"];
}

- (void)login:(NSString*)username password:(NSString*)password {
    LevelDB *ldb = [AppDB instance].db;
    
    NSURL *baseURL = [NSURL URLWithString:@"http://192.168.33.10:6000/"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSDictionary *dict = @{@"username":username, @"password":password};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"login.doing", @"登录中...");
    
    [manager POST:@"auth/token"
       parameters:dict
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              NSLog(@"response:%@", responseObject);
              [ldb setObject:responseObject forKey:@"user_auth"];
              
              [MBProgressHUD hideHUDForView:self.view animated:YES];
              CustomerMessageListViewController *ctrl = [[CustomerMessageListViewController alloc] init];
              UINavigationController *navigationCtrl = [[UINavigationController alloc] initWithRootViewController:ctrl];
              [UIApplication sharedApplication].keyWindow.rootViewController = navigationCtrl;
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSLog(@"failure");
              hud.labelText = NSLocalizedString(@"login.failure", @"登录失败");
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
              });
          }
     ];
}

@end
