//
//  XWMessageViewController.h
//  kefu
//
//  Created by houxh on 16/10/24.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <gobelieve/MessageViewController.h>

//最近发出的消息
#define LATEST_CUSTOMER_MESSAGE        @"latest_customer_message"

//清空会话的未读消息数
#define CLEAR_CUSTOMER_NEW_MESSAGE @"clear_customer_single_conv_new_message_notify"

//小微团队
@interface XWMessageViewController : MessageViewController
@property(nonatomic, assign) int64_t currentUID;
@property(nonatomic, copy) NSString *peerName;

@property(nonatomic, assign) int64_t storeID;
@property(nonatomic, assign) int64_t sellerID;
@property(nonatomic, assign) int64_t appID;
@end
