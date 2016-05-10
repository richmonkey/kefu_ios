//
//  RobotViewController.m
//  kefu
//
//  Created by houxh on 16/5/10.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "RobotViewController.h"
#import "Config.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "Token.h"
#import "UIAlertView+XPAlertView.h"

@interface Question: NSObject
@property(nonatomic, assign) int64_t id;
@property(nonatomic, copy) NSString *question;
@property(nonatomic, copy) NSString *answer;
@end

@implementation Question
@end

@interface RobotViewController ()
@property(nonatomic) NSArray *questions;
@end

@implementation RobotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.questions = [NSArray array];
    
    //self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;

    int imageSize = 30; //REPLACE WITH YOUR IMAGE WIDTH
    
    UIImage *barBackBtnImg = [[UIImage imageNamed:@"back"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, imageSize, 0, 0)];
    UIBarButtonItem *barButtonItemLeft=[[UIBarButtonItem alloc] initWithImage:barBackBtnImg
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(back)];
    [self.navigationItem setLeftBarButtonItem:barButtonItemLeft];
    
    self.navigationItem.title = @"相似问题";
    
    NSLog(@"q:%@", self.question);
    [self askRobotWithQuestion:self.question];
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)askRobotWithQuestion:(NSString*)question {
    NSString *base = [NSString stringWithFormat:@"%@/", KEFU_API];
    NSURL *baseURL = [NSURL URLWithString:base];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [Token instance].accessToken];
    [manager.requestSerializer setValue:auth forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *dict = @{@"question":question};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"robot.doing", @"搜索中...");
    
    [manager GET:@"robot/answer"
       parameters:dict
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              NSLog(@"response:%@", responseObject);
              
              if ([responseObject count] == 0) {
                  hud.labelText = NSLocalizedString(@"robot.empty", @"未找到相似问题");
                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                      [MBProgressHUD hideHUDForView:self.view animated:YES];
                  });
              } else {
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
                  
                  NSMutableArray *questions = [NSMutableArray array];
                  for (NSDictionary *obj in responseObject) {
                      Question *q = [[Question alloc] init];
                      q.id = [[obj objectForKey:@"id"] longLongValue];
                      q.answer = [obj objectForKey:@"answer"];
                      q.question = [obj objectForKey:@"question"];
                      [questions addObject:q];
                  }
                  
                  self.questions = questions;
                  [self.tableView reloadData];
              }
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSLog(@"failure:%@", error);
              hud.labelText = NSLocalizedString(@"robot.failure", @"搜索失败");
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  [MBProgressHUD hideHUDForView:self.view animated:YES];
              });
          }
     ];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.questions.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"robot_cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"robot_cell"];

    }
    Question *q = [self.questions objectAtIndex:indexPath.row];
    [cell.textLabel setText:q.question];
    [cell.detailTextLabel setText:q.answer];
    return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"确定发送" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定",nil];
    [alert showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex==1) {
            Question *q = [self.questions objectAtIndex:indexPath.row];
            [self.delegate sendRobotAnswer:q.answer];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
