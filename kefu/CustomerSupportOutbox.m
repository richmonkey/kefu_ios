//
//  CustomerSupportOutbox.m
//  kefu
//
//  Created by houxh on 16/4/17.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerSupportOutbox.h"
#import <gobelieve/IMService.h>
#import "CustomerSupportMessageDB.h"

@implementation CustomerSupportOutbox
+(CustomerSupportOutbox*)instance {
    static CustomerSupportOutbox *box;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!box) {
            box = [[CustomerSupportOutbox alloc] init];
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
    
    [[IMService instance] sendCustomerSupportMessage:im];
}

-(void)markMessageFailure:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    [[CustomerSupportMessageDB instance] markMessageFailure:cm.msgLocalID
                                                        uid:cm.customerID
                                                      appID:cm.customerAppID];
}

-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID url:url];
    ICustomerMessage *attachment = [[ICustomerMessage alloc] init];
    attachment.storeID = cm.storeID;
    attachment.sellerID = cm.sellerID;
    attachment.customerID = cm.customerID;
    attachment.customerAppID = cm.customerAppID;
    attachment.rawContent = att.raw;
    
    [[CustomerSupportMessageDB instance] insertMessage:attachment uid:cm.customerID appID:cm.customerAppID];
}
@end
