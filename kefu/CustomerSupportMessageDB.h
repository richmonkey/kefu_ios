//
//  CustomerSupportMessageDB.h
//  kefu
//
//  Created by houxh on 16/4/16.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <gobelieve/MessageDB.h>
#import <gobelieve/IMessage.h>
#import <gobelieve/ConversationIterator.h>
#import <gobelieve/IMessageIterator.h>

@interface CustomerSupportMessageDB : MessageDB
+(CustomerSupportMessageDB*)instance;

@property(nonatomic, copy) NSString *dbPath;

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid appID:(int64_t)appID;
-(id<IMessageIterator>)newMessageIterator:(int64_t)uid appID:(int64_t)appID last:(int)lastMsgID;
-(id<ConversationIterator>)newConversationIterator;

-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)uid appID:(int64_t)appID;
-(BOOL)removeMessage:(int)msgLocalID uid:(int64_t)uid appID:(int64_t)appID;
-(BOOL)clearConversation:(int64_t)uid appID:(int64_t)appID;
-(BOOL)clear;
-(BOOL)acknowledgeMessage:(int)msgLocalID uid:(int64_t)uid appID:(int64_t)appID;
-(BOOL)markMessageFailure:(int)msgLocalID uid:(int64_t)uid appID:(int64_t)appID;
-(BOOL)markMesageListened:(int)msgLocalID uid:(int64_t)uid appID:(int64_t)appID;
-(BOOL)eraseMessageFailure:(int)msgLocalID uid:(int64_t)uid appID:(int64_t)appID;
@end
