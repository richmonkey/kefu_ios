//
//  CustomerConversation.h
//  kefu
//
//  Created by houxh on 16/4/16.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <gobelieve/IMessage.h>
@interface CustomerConversation : Conversation
@property(nonatomic) int64_t customerAppID;
@property(nonatomic) int64_t customerID;
@end
