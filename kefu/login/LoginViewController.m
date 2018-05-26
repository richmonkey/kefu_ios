//
//  LoginViewController.m
//
//  Copyright © 2016年 beetle. All rights reserved.

#import "LoginViewController.h"

#import "LoginViewOneCell.h"
#import "LoginViewTwoCell.h"

#import "Masonry.h"
#import "AFNetworking.h"
#import "LevelDB.h"
#import "MBProgressHUD.h"
#import "CustomerMessageListViewController.h"
#import <gobelieve/IMService.h>
#import "AppDB.h"
#import "Config.h"
#import "Token.h"
#import "Profile.h"
#import "API.h"
#import "UIView+Toast.h"
#import "UIAlertView+XPAlertView.h"

#import <SafariServices/SafariServices.h>


#define kFirstCellOffset    20
#define kSecondMax      60
#define kTextFieldTag  40

@interface LoginViewController ()<SFSafariViewControllerDelegate> {
    
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableVIewTop;
@property (strong, nonatomic) UITextField *loginNumberTextField;
@property (strong, nonatomic) UITextField *loginPasswordTextField;
@property (weak, nonatomic) IBOutlet UIButton *registerBtn;

@property (strong,nonatomic) LoginViewOneCell *headCell;

@property (nonatomic) CGFloat registerOneCellHeight;



@end

@implementation LoginViewController

- (void)dealloc {
    NSLog(@"LoginViewControler dealloc");
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate   = self;
    self.tableView.dataSource = self;
    self.tableView.showsVerticalScrollIndicator = NO;
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"注册"];
    NSRange strRange = {0,[str length]};
    [str addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:strRange];
    [str addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0f] range:strRange];
    [self.registerBtn setAttributedTitle:str forState:UIControlStateNormal];
    [self.registerBtn setBackgroundColor:[UIColor colorWithRed:238.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1.0f]];
    [self.registerBtn addTarget:self action:@selector(registerAction) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.hint) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"你的账号在其它设备上登录"
                                                       delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    
    [self registerForKeyboardNotifications];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:YES];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    if([[[UIDevice currentDevice] systemVersion] doubleValue] >=
       7.0){
        self.tableVIewTop.constant = -kFirstCellOffset;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[self navigationController] setNavigationBarHidden:NO];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark-- UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        static NSString *identifyCell = @"LoginViewOneCell";
        LoginViewOneCell *cell = (LoginViewOneCell *)[tableView dequeueReusableCellWithIdentifier:identifyCell];
        if (cell == nil) {
            NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"LoginViewOneCell" owner:self options:nil];
            cell = [array objectAtIndex:0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        self.headCell = cell;
        return cell;
    }
    else if (indexPath.row == 1) {
        //登录界面
        static NSString *identifyCell = @"LoginViewTwoCell";
        LoginViewTwoCell *cell = (LoginViewTwoCell *)[tableView dequeueReusableCellWithIdentifier:identifyCell];
        if (cell == nil) {
            NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"LoginViewTwoCell" owner:self options:nil];
            cell = [array objectAtIndex:0];
            cell.userNumberTextField.delegate = self;
            cell.passwordTextField.delegate = self;
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.loginNumberTextField = cell.userNumberTextField;
        self.loginPasswordTextField = cell.passwordTextField;
        
        [cell.loginUserButton.layer setMasksToBounds:YES];
        [cell.loginUserButton.layer setCornerRadius:5.0];
        [cell.loginUserButton addTarget:self action:@selector(loginSubmitButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
        
    }
   
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.view.frame.size.height < 556) {
        // iphone4/4s 屏幕长度比较短
        CGFloat allcellHeight = 586.0f;
        if (indexPath.row == 0) {
            self.registerOneCellHeight = allcellHeight/3.0+10;
            return allcellHeight/3.0+10;
        }
        else if(indexPath.row == 1){
            return allcellHeight/3.0;
        }
        else if(indexPath.row == 2){
            return allcellHeight/3.0-10;
        }
        else{
            return allcellHeight*2/3.0-10;
        }
    }
    else{
        //iphone4/4s以上 均匀分布
        if (indexPath.row == 0) {
            self.registerOneCellHeight = self.view.frame.size.height/3.0+10;
            return self.view.frame.size.height/3.0 + 10;
        }
        else if(indexPath.row == 1){
            return self.view.frame.size.height/3.0;
        }
        return  0;
    }
}

/**
 *  拉伸顶部代码
 *
 *  @param scrollView
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGPoint offset = scrollView.contentOffset;
    if (offset.y < 0) {
        CGRect rect = self.headCell.backgroundImageView.frame;
        rect.origin.y = offset.y + kFirstCellOffset;
        rect.size.height = self.registerOneCellHeight - rect.origin.y;
        self.headCell.backgroundImageView.frame = rect;
    }
}

#pragma mark -- 登录界面Action

- (void)loginSubmitButtonAction:(id)sender{
    if (self.loginNumberTextField.text.length == 0){
        [self.view makeToast:@"客服账号不能为空" duration:1.0 position:@"center"];
        return;
    }
    if(self.loginPasswordTextField.text.length == 0) {
        [self.view makeToast:@"密码不能为空" duration:1.0 position:@"center"];
        return;
    }
    
    //取消键盘
    [[self findFirstResponderBeneathView:self.view] resignFirstResponder];

    NSString *userName = self.loginNumberTextField.text;
    NSString *password = self.loginPasswordTextField.text;
    [self login:userName password:password];
    
}


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

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}



- (void)login:(NSString*)username password:(NSString*)password {
    AFHTTPSessionManager *manager = [API newLoginSessionManager];
    
#define  PLATFORM_IOS 1
    
    NSString *name = [[UIDevice currentDevice] name];
#if TARGET_IPHONE_SIMULATOR
    NSString *deviceID = @"7C8A8F5B-E5F4-4797-8758-05367D2A4D61";
#else
    NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#endif
    
    NSDictionary *dict = @{@"username":username, @"password":password,
                           @"device_name":name,  @"device_id":deviceID,
                           @"platform":@PLATFORM_IOS};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"login.doing", @"登录中...");
    
    [manager POST:@"auth/token"
       parameters:dict
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              NSLog(@"response:%@", responseObject);
              Token *token = [Token instance];
              token.accessToken = [responseObject objectForKey:@"access_token"];
              token.refreshToken = [responseObject objectForKey:@"refresh_token"];
              token.expireTimestamp = (int)time(NULL) + [[responseObject objectForKey:@"expires_in"] intValue];
              [token save];
              
              [Profile instance].uid = [[responseObject objectForKey:@"uid"] longLongValue];
              [Profile instance].storeID = [[responseObject objectForKey:@"store_id"] longLongValue];
              [Profile instance].name = [responseObject objectForKey:@"name"];
              [Profile instance].avatar = [responseObject objectForKey:@"avatar"];
              [Profile instance].loginTimestamp = (int)time(NULL);
              [Profile instance].status = STATUS_ONLINE;
              [[Profile instance] save];
              
              [MBProgressHUD hideHUDForView:self.view animated:YES];
              CustomerMessageListViewController *ctrl = [[CustomerMessageListViewController alloc] init];
              UINavigationController *navigationCtrl = [[UINavigationController alloc] initWithRootViewController:ctrl];
              [UIApplication sharedApplication].keyWindow.rootViewController = navigationCtrl;
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSHTTPURLResponse* r = (NSHTTPURLResponse*)task.response;
              NSData *errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
              if (errorData) {
                  NSDictionary *serializedData = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
                  NSLog(@"failure:%@ %@ %zd", error, [serializedData objectForKey:@"error"], r.statusCode);
                  NSString *e = [serializedData objectForKey:@"error"];
                  if (e.length > 0) {
                      hud.labelText = e;
                  } else {
                      hud.labelText = NSLocalizedString(@"login.failure", @"登录失败");
                  }
              } else {
                  hud.labelText = NSLocalizedString(@"login.failure", @"登录失败");
              }
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
              });
          }
     ];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}


-(void)registerAction{
    
    NSURL *url = [NSURL URLWithString: REGISTER_URL];
    SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:url];
    svc.delegate = self;
    [self presentViewController:svc animated:YES completion:nil];
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
