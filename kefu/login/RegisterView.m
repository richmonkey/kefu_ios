//
//  RegisterView.m
//  kefu
//
//  Created by 杨朋亮 on 14/6/16.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "RegisterView.h"

@implementation RegisterView


+ (id)viewFromXib
{
    UIView *view = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([RegisterView class])
                                                  owner:nil
                                                options:nil] lastObject];
    
    return view;
}

+ (id)viewFromXibWithFrame : (CGRect)frame
{
    UIView *view = [self viewFromXib];
    
    view.frame = frame;
    
    return view;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"注册"];
    NSRange strRange = {0,[str length]};
    [str addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:strRange];
    [self.registerBtn setAttributedTitle:str forState:UIControlStateNormal];

}

@end
