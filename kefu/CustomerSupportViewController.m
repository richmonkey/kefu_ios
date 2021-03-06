//
//  CustomerMessageViewController.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerSupportViewController.h"
#import "CustomerSupportOutbox.h"
#import "AudioDownloader.h"
#import "CustomerSupportMessageDB.h"
#import "SDImageCache.h"
#import "FileCache.h"
#import "UIImage+Resize.h"
#import "AFNetworking.h"

#import <gobelieve/EaseChatToolbar.h>
#import "RobotViewController.h"
#import "Profile.h"
#import "Config.h"
#import "App.h"
#import "API.h"
#import "Token.h"

#define PAGE_COUNT 10

@interface CustomerSupportViewController ()<OutboxObserver, CustomerMessageObserver,
                                            AudioDownloaderObserver, RobotViewControllerDelegate,
                                            SystemMessageObserver>

@end

@implementation CustomerSupportViewController

- (void)dealloc {
    NSLog(@"CustomerMessageViewController dealloc");
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self addObserver];
    App *app = [App load:self.customerAppID];
    if (app.name.length == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //等待界面动画结束
            [self getApp:self.customerAppID];
        });
        self.navigationItem.title = self.customerName;
    } else {
        [self setBarTitle:app];
    }
}

//http://stackoverflow.com/questions/9921026/center-custom-title-in-uinavigationbar
- (void)setBarTitle:(App*)app {
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 22)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 1;
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    titleLabel.text = self.customerName;
    
    [titleLabel sizeToFit];
    
    UILabel *subTitleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 22, 100, 22)];
    subTitleLabel.textAlignment = NSTextAlignmentCenter;
    [subTitleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:12.0]];
    subTitleLabel.numberOfLines = 1;
    subTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    subTitleLabel.text = app.name;
    
    [subTitleLabel sizeToFit];
    
    int width = MAX(titleLabel.frame.size.width + 8, subTitleLabel.frame.size.width + 8);
    //最大宽度不超过220px
    width = MIN(220, width);
    UIView *titleView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, width, 44)];
    [titleView addSubview:titleLabel];
    [titleView addSubview:subTitleLabel];
    
    titleLabel.frame = CGRectMake(0, 0, width, 22);
    subTitleLabel.frame = CGRectMake(0, 22, width, 22);
    
    self.navigationItem.titleView = titleView;
}

//从服务器获取用户信息
- (void)getApp:(int64_t)appID {
    if ([Token instance].isAccessTokenExpired) {
        return;
    }
    
    AFHTTPSessionManager *manager = [API newSessionManager];
    NSString *url = [NSString stringWithFormat:@"customers/%lld", appID];
    [manager GET:url
      parameters:nil
        progress:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             NSLog(@"response:%@", responseObject);
             NSString *name = [responseObject objectForKey:@"name"];
             BOOL wechat = [[responseObject objectForKey:@"wechat"] boolValue];
             if (name.length > 0) {
                 App *app = [[App alloc] init];
                 app.appID = appID;
                 app.name = name;
                 app.wechat = wechat;
                 [App save:app];
                 
                 [self setBarTitle:app];
             }
         }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSLog(@"failure");
         }
     ];
}


-(void)addObserver {
    [[AudioDownloader instance] addDownloaderObserver:self];
    [[CustomerSupportOutbox instance] addBoxObserver:self];
    [[IMService instance] addConnectionObserver:self];
    [[IMService instance] addCustomerMessageObserver:self];
    [[IMService instance] addSystemMessageObserver:self];
}

-(void)removeObserver {
    [[AudioDownloader instance] removeDownloaderObserver:self];
    [[CustomerSupportOutbox instance] removeBoxObserver:self];
    [[IMService instance] removeConnectionObserver:self];
    [[IMService instance] removeCustomerMessageObserver:self];
    [[IMService instance] removeSystemMessageObserver:self];
}

- (void)loadSenderInfo:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    if (cm.isSupport) {
        Profile *profile = [Profile instance];
        
        IUser *u = [[IUser alloc] init];
        u.name = profile.name;
        u.avatarURL = profile.avatar;
        
        msg.senderInfo = u;
    } else {
        IUser *u = [[IUser alloc] init];
        u.name = self.customerName;
        u.avatarURL = self.customerAvatar;
        
        msg.senderInfo = u;
    }
}

- (void)loadSenderInfo:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self loadSenderInfo:msg];
    }
}


- (int64_t)sender {
    return self.storeID;
}

- (int64_t)receiver {
    return self.customerID;
}

- (BOOL)isMessageSending:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    return [[IMService instance] isCustomerSupportMessageSending:msg.msgLocalID
                                                      customerID:cm.customerID
                                                   customerAppID:cm.customerAppID];
}

- (BOOL)isInConversation:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    return (cm.customerAppID == self.customerAppID && cm.customerID == self.customerID);
}

- (void)onBack {
    [self removeObserver];
    [self stopPlayer];
    
    id obj = @{
        @"uid": [NSNumber numberWithLongLong:self.customerID],
        @"appid": [NSNumber numberWithLongLong:self.customerAppID]
    };
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_CUSTOMER_SUPPORT_NEW_MESSAGE
                                                                 object:nil
                                                               userInfo:obj];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}




//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state{
    if(state == STATE_CONNECTED){
        [self enableSend];
    } else {
        [self disableSend];
    }
}


- (void)loadConversationData {
    int count = 0;
    id<IMessageIterator> iterator =  [[CustomerSupportMessageDB instance] newMessageIterator:self.customerID
                                                                                       appID:self.customerAppID];
    ICustomerMessage *msg = (ICustomerMessage*)[iterator next];
    while (msg) {
        if (self.textMode) {
            if (msg.type == MESSAGE_TEXT) {
                [self.messages insertObject:msg atIndex:0];
                if (++count >= PAGE_COUNT) {
                    break;
                }
            }
        } else {
            if (msg.type == MESSAGE_ATTACHMENT) {
                MessageAttachmentContent *att = msg.attachmentContent;
                [self.attachments setObject:att
                                     forKey:[NSNumber numberWithInt:att.msgLocalID]];
            } else {
                msg.isOutgoing = (msg.isSupport && msg.sellerID == self.currentUID);
                [self.messages insertObject:msg atIndex:0];
                if (++count >= PAGE_COUNT) {
                    break;
                }
            }
        }
        msg = (ICustomerMessage*)[iterator next];
    }
    


    [self downloadMessageContent:self.messages count:count];
    [self loadSenderInfo:self.messages count:count];
    [self checkMessageFailureFlag:self.messages count:count];
    
    [self initTableViewData];
}


- (void)loadEarlierData {
    //找出第一条实体消息
    IMessage *last = nil;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        IMessage *m = [self.messages objectAtIndex:i];
        if (m.type != MESSAGE_TIME_BASE) {
            last = m;
            break;
        }
    }
    if (last == nil) {
        return;
    }
    
    id<IMessageIterator> iterator =  [[CustomerSupportMessageDB instance] newMessageIterator:self.customerID
                                                                                       appID:self.customerAppID
                                                                                        last:last.msgLocalID];
    
    int count = 0;
    ICustomerMessage *msg = (ICustomerMessage*)[iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
            
        } else {
            msg.isOutgoing = (msg.isSupport && msg.sellerID == self.currentUID);
            [self.messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = (ICustomerMessage*)[iterator next];
    }
    if (count == 0) {
        return;
    }
    
    [self downloadMessageContent:self.messages count:count];
    [self loadSenderInfo:self.messages count:count];
    [self checkMessageFailureFlag:self.messages count:count];
    
    [self initTableViewData];
    
    [self.tableView reloadData];
    
    int c = 0;
    int section = 0;
    int row = 0;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        row++;
        IMessage *m = [self.messages objectAtIndex:i];
        if (m.type == MESSAGE_TIME_BASE) {
            continue;
        }
        c++;
        if (c >= count) {
            break;
        }
    }
    NSLog(@"scroll to row:%d section:%d", row, section);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

-(void)checkMessageFailureFlag:(IMessage*)msg {
    if (msg.isOutgoing) {
        if (msg.type == MESSAGE_AUDIO) {
            msg.uploading = [[CustomerSupportOutbox instance] isUploading:msg];
        } else if (msg.type == MESSAGE_IMAGE) {
            msg.uploading = [[CustomerSupportOutbox instance] isUploading:msg];
        }
        
        //消息发送过程中，程序异常关闭
        if (!msg.isACK && !msg.uploading &&
            !msg.isFailure && ![self isMessageSending:msg]) {
            [self markMessageFailure:msg];
            msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
        }
    }
}

-(void)checkMessageFailureFlag:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self checkMessageFailureFlag:msg];
    }
}

-(void)saveMessageAttachment:(IMessage*)m address:(NSString*)address {
    //以附件的形式存储，以免第二次查询
    ICustomerMessage *msg = (ICustomerMessage*)m;
    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID address:address];
    ICustomerMessage *attachment = [[ICustomerMessage alloc] init];
    attachment.rawContent = att.raw;
    [self saveMessage:attachment];
}



-(BOOL)saveMessage:(IMessage*)msg {
    return [[CustomerSupportMessageDB instance] insertMessage:msg
                                                          uid:self.customerID
                                                        appID:self.customerAppID];
}

-(BOOL)removeMessage:(IMessage*)msg {
    return [[CustomerSupportMessageDB instance] removeMessage:msg.msgLocalID
                                                          uid:self.customerID
                                                        appID:self.customerAppID];
    
}
-(BOOL)markMessageFailure:(IMessage*)msg {

    return [[CustomerSupportMessageDB instance] markMessageFailure:msg.msgLocalID
                                                               uid:self.customerID
                                                             appID:self.customerAppID];
}

-(BOOL)markMesageListened:(IMessage*)msg {
    return [[CustomerSupportMessageDB instance] markMesageListened:msg.msgLocalID
                                                               uid:self.customerID
                                                             appID:self.customerAppID];
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    return [[CustomerSupportMessageDB instance] eraseMessageFailure:msg.msgLocalID
                                                                uid:self.customerID
                                                              appID:self.customerAppID];
}

#pragma mark SystemMessageObserver
-(void)onSystemMessage:(NSString*)sm {
    const char *utf8 = [sm UTF8String];
    NSData *data = [NSData dataWithBytes:utf8 length:strlen(utf8)];
    NSDictionary *d = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    if ([d objectForKey:@"wechat"]) {
        NSDictionary *dict = [d objectForKey:@"wechat"];
        ICustomerMessage *msg = [[ICustomerMessage alloc] init];
        msg.customerAppID = [[dict objectForKey:@"customer_appid"] longLongValue];
        msg.customerID = [[dict objectForKey:@"customer_id"] longLongValue];
        
        msg.storeID = self.storeID;
        msg.sellerID = self.currentUID;
        
        NSString *headline = [dict objectForKey:@"notification"];
        MessageHeadlineContent *content = [[MessageHeadlineContent alloc] initWithHeadline:headline];
        msg.rawContent = content.raw;
        
        msg.timestamp = [[dict objectForKey:@"timestamp"] intValue];
        msg.isSupport = NO;
        msg.isOutgoing = NO;
        [self insertMessage:msg];
    }
}

-(void)onCustomerSupportMessage:(CustomerMessage*)im {
    if (self.customerAppID != im.customerAppID || self.customerID != im.customerID) {
        return;
    }
    
    
    NSLog(@"receive msg:%@",im);
    ICustomerMessage *m = [[ICustomerMessage alloc] init];
    m.sender = im.storeID;
    m.receiver = im.customerID;
    
    m.customerAppID = im.customerAppID;
    m.customerID = im.customerID;
    m.storeID = im.storeID;
    m.sellerID = im.sellerID;
    m.isSupport = YES;
    m.isOutgoing = (self.currentUID == im.sellerID);
    if (m.isOutgoing) {
        m.flags = m.flags | MESSAGE_FLAG_ACK;
    }
    
    m.msgLocalID = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;

    
    int now = (int)time(NULL);
    if (now - self.lastReceivedTimestamp > 1) {
        [[self class] playMessageReceivedSound];
        self.lastReceivedTimestamp = now;
    }
    
    [self downloadMessageContent:m];
    [self loadSenderInfo:m];
    [self insertMessage:m];
}


-(void)onCustomerMessage:(CustomerMessage*)im {
    if (self.customerAppID != im.customerAppID || self.customerID != im.customerID) {
        return;
    }
    
    
    NSLog(@"receive msg:%@",im);
    ICustomerMessage *m = [[ICustomerMessage alloc] init];
    m.sender = im.customerID;
    m.receiver = im.storeID;
    
    m.customerAppID = im.customerAppID;
    m.customerID = im.customerID;
    m.storeID = im.storeID;
    m.sellerID = im.sellerID;
    m.isSupport = NO;
    m.isOutgoing = (im.customerAppID == APPID && im.customerID == self.currentUID);
    if (m.isOutgoing) {
        m.flags = m.flags | MESSAGE_FLAG_ACK;
    }
    m.msgLocalID = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    
    int now = (int)time(NULL);
    if (now - self.lastReceivedTimestamp > 1) {
        [[self class] playMessageReceivedSound];
        self.lastReceivedTimestamp = now;
    }
    
    [self downloadMessageContent:m];
    [self loadSenderInfo:m];
    [self insertMessage:m];
}

//服务器ack
-(void)onCustomerMessageACK:(CustomerMessage*)cm {
    if (self.customerAppID != cm.customerAppID || self.customerID != cm.customerID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:cm.msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_ACK;
}

//消息发送失败
-(void)onCustomerMessageFailure:(CustomerMessage*)cm {
    if (self.customerAppID != cm.customerAppID || self.customerID != cm.customerID) {
        return;
    }

    IMessage *msg = [self getMessageWithID:cm.msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
}

- (void)sendMessage:(IMessage *)msg withImage:(UIImage*)image {
    msg.uploading = YES;
    [[CustomerSupportOutbox instance] uploadImage:msg withImage:image];
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_CUSTOMER_SUPPORT_MESSAGE object:msg userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)sendMessage:(IMessage*)message {
    ICustomerMessage *msg = (ICustomerMessage*)message;
    if (message.type == MESSAGE_AUDIO) {
        message.uploading = YES;
        [[CustomerSupportOutbox instance] uploadAudio:message];
    } else if (message.type == MESSAGE_IMAGE) {
        message.uploading = YES;
        [[CustomerSupportOutbox instance] uploadImage:message];
    } else {
        CustomerMessage *im = [[CustomerMessage alloc] init];
        im.customerAppID = msg.customerAppID;
        im.customerID = msg.customerID;
        im.storeID = msg.storeID;
        im.sellerID = msg.sellerID;
        im.msgLocalID = message.msgLocalID;
        im.content = message.rawContent;
        
        [[IMService instance] sendCustomerSupportMessage:im];
    }
    
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_CUSTOMER_SUPPORT_MESSAGE object:message userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}





#pragma mark - Outbox Observer
- (void)onAudioUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.uploading = NO;
    }
}

-(void)onAudioUploadFail:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.flags = m.flags|MESSAGE_FLAG_FAILURE;
        m.uploading = NO;
    }
}

- (void)onImageUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.uploading = NO;
    }
}

- (void)onImageUploadFail:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.flags = m.flags|MESSAGE_FLAG_FAILURE;
        m.uploading = NO;
    }
}


#pragma mark - Audio Downloader Observer
- (void)onAudioDownloadSuccess:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.downloading = NO;
    }
}

- (void)onAudioDownloadFail:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.downloading = NO;
    }
}


#pragma mark - send message
- (void)sendLocationMessage:(CLLocationCoordinate2D)location address:(NSString*)address {
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.customerAppID = self.customerAppID;
    msg.customerID = self.customerID;
    msg.storeID = self.storeID;
    msg.sellerID = self.currentUID;
    msg.isSupport = YES;
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    MessageLocationContent *content = [[MessageLocationContent alloc] initWithLocation:location];
    msg.rawContent = content.raw;
    
    content = msg.locationContent;
    content.address = address;
    
    msg.timestamp = (int)time(NULL);
    msg.isSupport = YES;
    msg.isOutgoing = YES;
    
    [self loadSenderInfo:msg];
    
    [self saveMessage:msg];
    
    [self sendMessage:msg];
    
    [[self class] playMessageSentSound];
    
    [self createMapSnapshot:msg];
    if (content.address.length == 0) {
        [self reverseGeocodeLocation:msg];
    } else {
        [self saveMessageAttachment:msg address:content.address];
    }
    [self insertMessage:msg];
}

- (void)sendAudioMessage:(NSString*)path second:(int)second {
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.customerAppID = self.customerAppID;
    msg.customerID = self.customerID;
    msg.storeID = self.storeID;
    msg.sellerID = self.currentUID;
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    MessageAudioContent *content = [[MessageAudioContent alloc] initWithAudio:[self localAudioURL] duration:second];
    
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isSupport = YES;
    msg.isOutgoing = YES;
    
    //todo 优化读文件次数
    NSData *data = [NSData dataWithContentsOfFile:path];
    FileCache *fileCache = [FileCache instance];
    [fileCache storeFile:data forKey:content.url];

    [self loadSenderInfo:msg];
    
    [self saveMessage:msg];
    
    [self sendMessage:msg];
    
    [[self class] playMessageSentSound];
    
    [self insertMessage:msg];
}


- (void)sendImageMessage:(UIImage*)image {
    if (image.size.height == 0) {
        return;
    }
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    float newHeight = screenHeight;
    float newWidth = newHeight*image.size.width/image.size.height;
    
    
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.customerAppID = self.customerAppID;
    msg.customerID = self.customerID;
    msg.storeID = self.storeID;
    msg.sellerID = self.currentUID;
    msg.isSupport = YES;
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:[self localImageURL] width:newWidth height:newHeight];
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isSupport = YES;
    msg.isOutgoing = YES;
    
    
    UIImage *sizeImage = [image resizedImage:CGSizeMake(128, 128) interpolationQuality:kCGInterpolationDefault];
    image = [image resizedImage:CGSizeMake(newWidth, newHeight) interpolationQuality:kCGInterpolationDefault];
    
    [[SDImageCache sharedImageCache] storeImage:image forKey:content.imageURL];
    NSString *littleUrl =  [content littleImageURL];
    [[SDImageCache sharedImageCache] storeImage:sizeImage forKey: littleUrl];
    
    [self loadSenderInfo:msg];
    
    [self saveMessage:msg];
    
    [self sendMessage:msg withImage:image];
    
    [self insertMessage:msg];
    
    [[self class] playMessageSentSound];
}

-(void) sendTextMessage:(NSString*)text {
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    
    msg.customerAppID = self.customerAppID;
    msg.customerID = self.customerID;
    msg.storeID = self.storeID;
    msg.sellerID = self.currentUID;

    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    MessageTextContent *content = [[MessageTextContent alloc] initWithText:text];
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isSupport = YES;
    msg.isOutgoing = YES;
    
    [self loadSenderInfo:msg];
    
    [self saveMessage:msg];
    
    [self sendMessage:msg];
    
    [[self class] playMessageSentSound];
    
    [self insertMessage:msg];
}


- (void)resendMessage:(IMessage*)message {
    message.flags = message.flags & (~MESSAGE_FLAG_FAILURE);
    [self eraseMessageFailure:message];
    [self sendMessage:message];
}

- (void)moreViewRobotAction:(EaseChatBarMoreView *)moreView {
    NSLog(@"robot action...");
    RobotViewController *ctrl = [[RobotViewController alloc] init];
    ctrl.delegate = self;
    [self.navigationController pushViewController:ctrl animated:YES];
}


- (void)search:(NSString*)text {
    NSLog(@"robot action...");
    RobotViewController *ctrl = [[RobotViewController alloc] init];
    ctrl.question = text;
    ctrl.delegate = self;
    [self.navigationController pushViewController:ctrl animated:YES];
}

#pragma mark - RobotViewControllerDelegate
-(void)sendRobotAnswer:(NSString*)answer {
    NSLog(@"send robot answer...");
    [self sendTextMessage:answer];
}


@end
