//
//  CustomerSupportMessageHandler.m
//  kefu
//
//  Created by houxh on 16/4/16.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerSupportMessageHandler.h"
#import <gobelieve/IMessage.h>
#import "CustomerSupportMessageDB.h"
#import "Config.h"

@implementation CustomerSupportMessageHandler
+(CustomerSupportMessageHandler*)instance {
    static CustomerSupportMessageHandler *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[CustomerSupportMessageHandler alloc] init];
        }
    });
    return m;
}

-(BOOL)handleCustomerSupportMessage:(CustomerMessage*)msg {
    ICustomerMessage *m = [[ICustomerMessage alloc] init];
    m.customerAppID = msg.customerAppID;
    m.customerID = msg.customerID;
    m.storeID = msg.storeID;
    m.sellerID = msg.sellerID;
    m.isSupport = YES;
    m.sender = msg.customerID;
    m.receiver = msg.storeID;
    m.rawContent = msg.content;
    m.timestamp = msg.timestamp;
    
    //“小微客服”发出的消息
    if (msg.sellerID == self.uid) {
        m.flags = m.flags|MESSAGE_FLAG_ACK;
    }
    BOOL r = [[CustomerSupportMessageDB instance] insertMessage:m uid:msg.customerID appID:msg.customerAppID];
    if (r) {
        msg.msgLocalID = m.msgLocalID;
    }
    return r;
}

-(BOOL)handleMessage:(CustomerMessage*)msg {
    ICustomerMessage *m = [[ICustomerMessage alloc] init];
    m.customerAppID = msg.customerAppID;
    m.customerID = msg.customerID;
    m.storeID = msg.storeID;
    m.sellerID = msg.sellerID;
    m.isSupport = NO;
    m.sender = msg.customerID;
    m.receiver = msg.storeID;
    m.rawContent = msg.content;
    m.timestamp = msg.timestamp;
    
    //"小微客服"或者第三方app发出的消息
    if (msg.customerAppID == APPID && msg.customerID == self.uid) {
        m.flags = m.flags|MESSAGE_FLAG_ACK;
    }
    BOOL r = [[CustomerSupportMessageDB instance] insertMessage:m uid:msg.customerID appID:msg.customerAppID];
    if (r) {
        msg.msgLocalID = m.msgLocalID;
    }
    return r;
}

-(BOOL)handleMessageACK:(CustomerMessage*)msg {
    return [[CustomerSupportMessageDB instance] acknowledgeMessage:msg.msgLocalID uid:msg.customerID appID:msg.customerAppID];
}

-(BOOL)handleMessageFailure:(CustomerMessage*)msg {
    CustomerSupportMessageDB *db = [CustomerSupportMessageDB instance];
    return [db markMessageFailure:msg.msgLocalID uid:msg.customerID appID:msg.customerAppID];
}

@end
