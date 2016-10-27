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
#import "API.h"

//RGB颜色
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
//RGB颜色和不透明度
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f \
alpha:(a)]

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
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = RGBACOLOR(235, 235, 237, 1);
    self.tableView.separatorColor = RGBCOLOR(208, 208, 208);
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
    AFHTTPSessionManager *manager = [API newSessionManager];
    
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

    UIFont *font = [UIFont systemFontOfSize:14];

    Question *q = [self.questions objectAtIndex:indexPath.row];
    
    CGSize size = self.view.frame.size;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:q.answer
                                                                         attributes:@{NSFontAttributeName: font}];
    CGRect rect = [attributedText boundingRectWithSize:(CGSize){size.width - 20, CGFLOAT_MAX}
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    CGSize s = rect.size;
    return 30 + s.height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"robot_cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"robot_cell"];
        
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [cell.detailTextLabel setBackgroundColor:[UIColor clearColor]];
    
        [cell.textLabel setBackgroundColor:[UIColor clearColor]];
        
        [cell setBackgroundColor:RGBCOLOR(253, 253, 253)];
        [cell.contentView setBackgroundColor:RGBCOLOR(250, 250, 250)];
        
        UIView *line = [[UIView alloc] init];
        [line setBackgroundColor:RGBACOLOR(170, 170, 170,0.35f)];
        [line setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];
        [cell addSubview:line];
        line.tag = (indexPath.row+1)*10001;
    }
    
    UIView *tmp = [cell viewWithTag:10001];
    if (tmp) {
        [tmp setFrame:CGRectMake(8, cell.bounds.size.height - 1 , cell.bounds.size.width - 16, 1)];
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


@end
