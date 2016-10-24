//
//  XWCustomerOutbox.m
//  kefu
//
//  Created by houxh on 16/10/24.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "XWCustomerOutbox.h"
#import "IMService.h"
#import "CustomerSupportMessageDB.h"

@implementation XWCustomerOutbox
+(XWCustomerOutbox*)instance {
    static XWCustomerOutbox *box;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!box) {
            box = [[XWCustomerOutbox alloc] init];
        }
    });
    return box;
}

-(id)init {
    self = [super init];
    if (self) {
    }
    return self;
}


- (void)sendMessage:(IMessage*)m{
    ICustomerMessage *msg = (ICustomerMessage*)m;
    CustomerMessage *im = [[CustomerMessage alloc] init];
    
    im.customerAppID = msg.customerAppID;
    im.customerID = msg.customerID;
    im.storeID = msg.storeID;
    im.sellerID = msg.sellerID;
    im.msgLocalID = msg.msgLocalID;
    im.content = msg.rawContent;
    
    [[IMService instance] sendCustomerMessage:im];
}

-(void)markMessageFailure:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    [[CustomerSupportMessageDB instance] markMessageFailure:cm.msgLocalID uid:cm.customerID appID:cm.customerAppID];
}


@end
