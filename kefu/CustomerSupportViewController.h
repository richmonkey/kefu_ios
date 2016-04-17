//
//  CustomerMessageViewController.h
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <gobelieve/MessageViewController.h>

//最近发出的消息
#define LATEST_CUSTOMER_MESSAGE        @"latest_customer_message"

//清空会话的未读消息数
#define CLEAR_CUSTOMER_NEW_MESSAGE @"clear_customer_single_conv_new_message_notify"

@interface CustomerSupportViewController : MessageViewController<TCPConnectionObserver>

@property(nonatomic, assign) int64_t currentUID;

@property(nonatomic, copy) NSString *customerName;


@property(nonatomic) int64_t customerAppID;
@property(nonatomic) int64_t customerID;
@property(nonatomic) int64_t storeID;

@end
