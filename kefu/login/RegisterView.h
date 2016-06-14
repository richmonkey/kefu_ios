//
//  RegisterView.h
//  kefu
//
//  Created by 杨朋亮 on 14/6/16.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegisterView : UIView

@property (weak, nonatomic) IBOutlet UIButton *registerBtn;

+ (id)viewFromXib;
+ (id)viewFromXibWithFrame : (CGRect)frame;


@end
