//
//  QuitTableViewCell.m
//  kefu
//
//  Created by 杨朋亮 on 17/4/16.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "QuitTableViewCell.h"

@implementation QuitTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.quitButton.layer setMasksToBounds:YES];
    [self.quitButton.layer setCornerRadius:5.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
