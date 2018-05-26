//
//  LogViewController.m
//  kefu
//
//  Created by houxh on 2018/4/18.
//  Copyright © 2018年 beetle. All rights reserved.
//

#import "LogViewController.h"
#import "Masonry.h"
#import "UIView+Toast.h"


@interface LogViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation LogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIEdgeInsets padding = UIEdgeInsetsMake(0, 0, 0, 0);
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view).with.insets(padding);
    }];
    
    
    // Do any additional setup after loading the view from its nib.
    NSArray *allPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [allPaths objectAtIndex:0];
    NSString *pathForLog = [documentsDirectory stringByAppendingPathComponent:@"app.log"];
    
    NSString *content = [NSString stringWithContentsOfFile:pathForLog  usedEncoding:NULL  error:NULL];

    NSLog(@"log path:%@", pathForLog);
    
    self.textView.text = content;
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"复制" style:UIBarButtonItemStylePlain target:self action:@selector(copyText)];
    [self.navigationItem setRightBarButtonItem:item];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)copyText {
  [[UIPasteboard generalPasteboard] setString:self.textView.text];
   [self.view makeToast:@"复制成功" duration:1.0 position:@"center"];
}
@end
