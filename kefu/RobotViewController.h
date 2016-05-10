//
//  RobotViewController.h
//  kefu
//
//  Created by houxh on 16/5/10.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RobotViewControllerDelegate <NSObject>
-(void)sendRobotAnswer:(NSString*)answer;
@end

@interface RobotViewController : UITableViewController
@property(nonatomic, copy) NSString *question;

@property(nonatomic, weak) id<RobotViewControllerDelegate> delegate;
@end
