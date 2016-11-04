//
//  CustomerMessageListViewController.m
//  im_demo
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerMessageListViewController.h"

#import <gobelieve/IMessage.h>
#import <gobelieve/IMService.h>
#import <gobelieve/PeerMessageDB.h>
#import <gobelieve/GroupMessageDB.h>
#import <gobelieve/CustomerMessageDB.h>
#import <gobelieve/PeerMessageViewController.h>
#import <gobelieve/GroupMessageViewController.h>
#import "CustomerSupportMessageDB.h"
#import "CustomerSupportViewController.h"
#import "XWMessageViewController.h"
#import "MessageConversationCell.h"
#import "LevelDB.h"
#import "AFNetworking.h"
#import "CustomerConversation.h"
#import <gobelieve/IMHttpAPI.h>
#import <gobelieve/IMService.h>
#import "AppDB.h"
#import "SettingViewController.h"
#import "Token.h"
#import "User.h"
#import "ConversationDB.h"
#import "LoginViewController.h"
#import "Config.h"
#import "API.h"
#import "Profile.h"

//RGB颜色
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
//RGB颜色和不透明度
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f \
alpha:(a)]

#define kConversationCellHeight         68

@interface CustomerMessageListViewController()<UITableViewDelegate, UITableViewDataSource,
TCPConnectionObserver, CustomerMessageObserver, SystemMessageObserver>
@property(nonatomic)dispatch_source_t refreshTimer;
@property(nonatomic)int refreshFailCount;

@property (strong , nonatomic) NSMutableArray *conversations;
@property (strong , nonatomic) UITableView *tableview;
@end

@implementation CustomerMessageListViewController

-(id)init {
    self = [super init];
    if (self) {
        self.conversations = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dealloc {
    NSLog(@"CustomerMessageListViewController dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    Profile *profile = [Profile instance];
    
    self.currentUID = profile.uid;
    self.storeID = profile.storeID;
    NSLog(@"store id:%lld uid:%lld", self.storeID, self.currentUID);
    

    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.tableview = [[UITableView alloc]initWithFrame:rect style:UITableViewStylePlain];
    self.tableview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableview.delegate = self;
    self.tableview.dataSource = self;
    self.tableview.scrollEnabled = YES;
    self.tableview.showsVerticalScrollIndicator = NO;
    self.tableview.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableview.backgroundColor = RGBACOLOR(235, 235, 237, 1);
    self.tableview.separatorColor = RGBCOLOR(208, 208, 208);
    [self.view addSubview:self.tableview];


    [[IMService instance] addConnectionObserver:self];
    [[IMService instance] addCustomerMessageObserver:self];
    [[IMService instance] addSystemMessageObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(newCustomerSupportMessage:)
                                                 name:LATEST_CUSTOMER_SUPPORT_MESSAGE
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(clearCustomerSupportNewState:)
                                                 name:CLEAR_CUSTOMER_SUPPORT_NEW_MESSAGE
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(newCustomerMessage:)
                                                 name:LATEST_CUSTOMER_MESSAGE
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(clearCustomerNewState:)
                                                 name:CLEAR_CUSTOMER_NEW_MESSAGE
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    
    id<ConversationIterator> iterator =  [[CustomerSupportMessageDB instance] newConversationIterator];
    Conversation * conversation = [iterator next];
    while (conversation) {
        [self.conversations addObject:conversation];
        conversation = [iterator next];
    }
    
    for (Conversation *conv in self.conversations) {
        CustomerConversation *cc = (CustomerConversation*)conv;
        conv.newMsgCount = [ConversationDB getNewCount:cc.customerID appID:cc.customerAppID];
        cc.isXiaoWei = (cc.customerID == self.currentUID && APPID == cc.customerAppID);
        cc.top = [ConversationDB getTop:cc.customerID appID:cc.customerAppID];
        
        [self updateConversationName:conv];
        [self updateConversationDetail:conv];
    }
    
    NSArray *sortedArray = [self.conversations sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        CustomerConversation *c1 = obj1;
        CustomerConversation *c2 = obj2;
        
        int64_t top1 = c1.top ? 1 : 0;
        int64_t top2 = c2.top ? 1 : 0;
        
        int64_t t1 = top1 << 32 | c1.timestamp;
        int64_t t2 = top2 << 32 | c2.timestamp;
        
        if (t1 < t2) {
            return NSOrderedDescending;
        } else if (t1 == t2) {
            return NSOrderedSame;
        } else {
            return NSOrderedAscending;
        }
    }];
    
    self.conversations = [NSMutableArray arrayWithArray:sortedArray];
    
    
    self.navigationItem.title = @"对话";
    if ([[IMService instance] connectState] == STATE_CONNECTING) {
        self.navigationItem.title = @"连接中...";
    }
    
    UIBarButtonItem *barButtonItemRight =[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"first_pg_right_setting"]
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(rightBarButtonItemClicked:)];
    [self.navigationItem setRightBarButtonItem:barButtonItemRight];
    
    __weak CustomerMessageListViewController *wself = self;
    if ([Token instance].isAccessTokenExpired) {
        [self addTokenRefreshOneTimeObserver:^{
            for (Conversation *conv in wself.conversations) {
                [wself updateConversationName:conv];
            }
        }];
    }
}





- (void)rightBarButtonItemClicked:(id)sender{
    SettingViewController *setting = [[SettingViewController alloc] init];
    setting.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:setting animated:YES];
}

- (void)updateConversationDetail:(Conversation*)conv {
    conv.timestamp = conv.message.timestamp;
    if (conv.message.type == MESSAGE_IMAGE) {
        conv.detail = @"一张图片";
    }else if(conv.message.type == MESSAGE_TEXT){
        MessageTextContent *content = conv.message.textContent;
        conv.detail = content.text;
    }else if(conv.message.type == MESSAGE_LOCATION){
        conv.detail = @"一个地理位置";
    }else if (conv.message.type == MESSAGE_AUDIO){
        conv.detail = @"一个音频";
    }
}

-(void)updateConversationName:(Conversation*)conversation {
    if (conversation.type == CONVERSATION_CUSTOMER_SERVICE) {
        CustomerConversation *cc = (CustomerConversation*)conversation;
        if (cc.isXiaoWei) {
            conversation.name = @"小微团队";
            conversation.avatarURL = XIAOWEI_ICON_URL;
        } else {
            IUser *u = [self getUser:cc.customerID appID:cc.customerAppID];
            if (u.name.length > 0) {
                conversation.name = u.name;
                conversation.avatarURL = u.avatarURL;
            } else {
                conversation.name = u.identifier;
                conversation.avatarURL = u.avatarURL;
            }
            
            //24hour refresh name
            int now = (int)time(NULL);
            if (now - u.timestamp > 24*3600) {
                [self asyncGetUser:cc.customerID appID:cc.customerAppID cb:^(IUser *u) {
                    conversation.name = u.name;
                    conversation.avatarURL = u.avatarURL;
                }];
            }
        }
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.conversations count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kConversationCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageConversationCell"];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle]loadNibNamed:@"MessageConversationCell" owner:self options:nil] lastObject];
    }
    Conversation * conv = nil;
    conv = (Conversation*)[self.conversations objectAtIndex:(indexPath.row)];
    
    [cell setConversation:conv];
    
    return cell;
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.tableview) {
        return YES;
    }
    return NO;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *action1 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        NSLog(@"delete");
        Conversation *con = [self.conversations objectAtIndex:indexPath.row];
        if (con.type == CONVERSATION_CUSTOMER_SERVICE) {
            CustomerConversation *cc = (CustomerConversation*)con;
            [[CustomerSupportMessageDB instance] clearConversation:cc.customerID appID:cc.customerAppID];
        }
        
        [self.conversations removeObject:con];
        [self.tableview reloadData];
    }];
    
    CustomerConversation *cc = [self.conversations objectAtIndex:indexPath.row];
    if (cc.top) {
        UITableViewRowAction *action2 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"取消置顶" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            NSLog(@"取消置顶");
            int originIndex = -1;
            int index = -1;
            for (int i = 0; i < self.conversations.count; i++) {
                CustomerConversation *conv = [self.conversations objectAtIndex:i];
                if (!conv.top) {
                    index = i;
                    NSAssert(originIndex != -1, @"");
                    break;
                }
                if (conv == cc) {
                    originIndex = i;
                }
            }
            
            NSAssert(originIndex != -1, @"");
            if (index == -1) {
                index = (int)self.conversations.count;
            }
            
            [self.conversations removeObjectAtIndex:originIndex];
            [self.conversations insertObject:cc atIndex:index - 1];
            
            cc.top = NO;
            [ConversationDB setTop:cc.customerID appID:cc.customerAppID top:NO];
            
            [self.tableview reloadData];
        }];
        return @[action1, action2];
    } else {
        UITableViewRowAction *action2 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"置顶" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            NSLog(@"置顶");
            int originIndex = -1;
            for (int i = 0; i < self.conversations.count; i++) {
                CustomerConversation *conv = [self.conversations objectAtIndex:i];
                if (conv == cc) {
                    originIndex = i;
                }
            }
            
            NSAssert(originIndex != -1, @"");
   
            if (originIndex > 0) {
                [self.conversations removeObjectAtIndex:originIndex];
                [self.conversations insertObject:cc atIndex:0];
            }
            
            cc.top = YES;
            [ConversationDB setTop:cc.customerID appID:cc.customerAppID top:YES];
            
            [self.tableview reloadData];
        }];
        return @[action1, action2];
    }


}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    CustomerConversation *con = [self.conversations objectAtIndex:indexPath.row];
    if (con.type == CONVERSATION_CUSTOMER_SERVICE) {
        
        if (con.customerID == self.currentUID && con.customerAppID == APPID) {
            XWMessageViewController *msgController = [[XWMessageViewController alloc] init];
            msgController.peerName = @"小微客服";
            msgController.currentUID = self.currentUID;
            msgController.storeID = XIAOWEI_STORE_ID;
            msgController.sellerID = XIAOWEI_SELLER_ID;
            msgController.appID = APPID;
            msgController.isShowUserName = NO;
            msgController.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:msgController animated:YES];
        } else {
            CustomerSupportViewController *msgController = [[CustomerSupportViewController alloc] init];
            msgController.customerAppID = con.customerAppID;
            msgController.customerID = con.customerID;
            msgController.customerName = con.name;
            msgController.customerAvatar = con.avatarURL;
            msgController.currentUID = self.currentUID;
            msgController.storeID = self.storeID;
            msgController.isShowUserName = NO;
            msgController.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:msgController animated:YES];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark CustomerMessageObserver
-(void)onCustomerMessage:(CustomerMessage*)msg {
    ICustomerMessage *cm = [[ICustomerMessage alloc] init];
    
    cm.sender = msg.customerID;
    cm.receiver = msg.storeID;
    
    cm.customerAppID = msg.customerAppID;
    cm.customerID = msg.customerID;
    cm.storeID = msg.storeID;
    cm.sellerID = msg.sellerID;
    cm.timestamp = msg.timestamp;
    cm.isSupport = NO;
    cm.isOutgoing = (msg.customerAppID == APPID && msg.customerID == self.currentUID);
    
    cm.rawContent = msg.content;
    
    [self onNewCustomerMessage:cm];
}

-(void)onCustomerSupportMessage:(CustomerMessage*)msg {
    ICustomerMessage *cm = [[ICustomerMessage alloc] init];
    
    cm.sender = msg.customerID;
    cm.receiver = msg.storeID;
    
    cm.customerAppID = msg.customerAppID;
    cm.customerID = msg.customerID;
    cm.storeID = msg.storeID;
    cm.sellerID = msg.sellerID;
    cm.timestamp = msg.timestamp;
    cm.isSupport = YES;
    cm.isOutgoing = (msg.sellerID == self.currentUID);
    cm.rawContent = msg.content;
    
    [self onNewCustomerMessage:cm];
}

- (int)findCustomerConversation:(ICustomerMessage*)msg {
    int index = -1;
    for (int i = 0; i < [self.conversations count]; i++) {
        CustomerConversation *con = [self.conversations objectAtIndex:i];
        if (con.type == CONVERSATION_CUSTOMER_SERVICE &&
            con.customerID == msg.customerID &&
            con.customerAppID == msg.customerAppID) {
            index = i;
            break;
        }
    }
    return index;
}

- (void)updateCustomerConversation:(ICustomerMessage*)msg index:(int)index {
    CustomerConversation *con = [self.conversations objectAtIndex:index];
    con.message = msg;
    
    [self updateConversationDetail:con];
    
    if (msg.isIncomming) {
        con.newMsgCount += 1;
        [ConversationDB setNewCount:con.newMsgCount uid:con.customerID appID:con.customerAppID];
        [self setNewOnTabBar];
    }
    
    if (index != 0) {
        //置顶
        if (con.top) {
            [self.conversations removeObjectAtIndex:index];
            [self.conversations insertObject:con atIndex:0];
            [self.tableview reloadData];
        } else {
            int insert = 0;
            for (int i = 0; i < self.conversations.count; i++) {
                CustomerConversation *cc = (CustomerConversation*)[self.conversations objectAtIndex:i];
                if (!cc.top) {
                    insert = i;
                    break;
                }
            }
            
            if (insert < index) {
                [self.conversations removeObjectAtIndex:index];
                [self.conversations insertObject:con atIndex:insert];
                [self.tableview reloadData];
            }
        }
    }

}

- (void)newCustomerConversation:(ICustomerMessage*)msg {
    CustomerConversation *con = [[CustomerConversation alloc] init];
    con.type = CONVERSATION_CUSTOMER_SERVICE;
    con.cid = msg.customerID;
    con.customerID = msg.customerID;
    con.customerAppID = msg.customerAppID;
    con.message = msg;
    
    con.isXiaoWei = (con.customerID == self.currentUID && APPID == con.customerAppID);
    
    [self updateConversationName:con];
    [self updateConversationDetail:con];

    if (msg.isIncomming) {
        con.newMsgCount += 1;
        [ConversationDB setNewCount:con.newMsgCount uid:con.customerID appID:con.customerAppID];
        [self setNewOnTabBar];
    }
    int index = 0;
    for (int i = 0; i < self.conversations.count; i++) {
        CustomerConversation *cc = (CustomerConversation*)[self.conversations objectAtIndex:i];
        if (!cc.top) {
            index = i;
            break;
        }
    }
    [self.conversations insertObject:con atIndex:index];
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
    NSArray *array = [NSArray arrayWithObject:path];
    [self.tableview insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationMiddle];
}

- (void)onNewCustomerMessage:(ICustomerMessage*)msg {
    int index = [self findCustomerConversation:msg];
    if (index != -1) {
        [self updateCustomerConversation:msg index:index];
    } else {
        [self newCustomerConversation:msg];
    }
}


- (void)newCustomerSupportMessage:(NSNotification*) notification {
    ICustomerMessage *msg = notification.object;
    NSLog(@"new message:%lld, %lld", msg.sender, msg.receiver);
    [self onNewCustomerMessage:msg];
}

- (void)clearCustomerSupportNewState:(NSNotification*) notification {
    id obj = notification.userInfo;
    int64_t uid = [[obj objectForKey:@"uid"] longLongValue];
    int64_t appid = [[obj objectForKey:@"appid"] longLongValue];
    
    for (int i = 0; i < [self.conversations count]; i++) {
        CustomerConversation *con = [self.conversations objectAtIndex:i];
        if (con.type == CONVERSATION_CUSTOMER_SERVICE &&
            con.customerID == uid &&
            con.customerAppID == appid) {
            con.newMsgCount = 0;
            [ConversationDB setNewCount:0 uid:con.customerID appID:con.customerAppID];
            break;
        }
    }
}


- (void)newCustomerMessage:(NSNotification*) notification {
    ICustomerMessage *msg = notification.object;
    NSLog(@"new message:%lld, %lld", msg.sender, msg.receiver);
    [self onNewCustomerMessage:msg];
}

- (void)clearCustomerNewState:(NSNotification*) notification {
    id obj = notification.userInfo;
    int64_t uid = [[obj objectForKey:@"uid"] longLongValue];
    int64_t appid = [[obj objectForKey:@"appid"] longLongValue];
    
    for (int i = 0; i < [self.conversations count]; i++) {
        CustomerConversation *con = [self.conversations objectAtIndex:i];
        if (con.type == CONVERSATION_CUSTOMER_SERVICE &&
            con.customerID == uid &&
            con.customerAppID == appid) {
            con.newMsgCount = 0;
            [ConversationDB setNewCount:0 uid:con.customerID appID:con.customerAppID];
            break;
        }
    }
}

//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state {
    if (state == STATE_CONNECTING) {
        self.navigationItem.title = @"连接中...";
    } else if (state == STATE_CONNECTED) {
        self.navigationItem.title = @"对话";
    } else if (state == STATE_CONNECTFAIL) {
        
    } else if (state == STATE_UNCONNECTED) {
        
    }
}

#pragma mark SystemMessageObserver
-(void)onSystemMessage:(NSString*)sm {
    NSLog(@"system message:%@", sm);
    
    const char *utf8 = [sm UTF8String];
    NSData *data = [NSData dataWithBytes:utf8 length:strlen(utf8)];
    NSDictionary *d = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];

    NSDictionary *dict = [d objectForKey:@"login"];
    if (!dict) {
        return;
    }

    Profile *profile = [Profile instance];
#if TARGET_IPHONE_SIMULATOR
    NSString *deviceID = @"7C8A8F5B-E5F4-4797-8758-05367D2A4D61";
#else
    NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#endif
    
    int platform = [[dict objectForKey:@"platform"] intValue];
    if (platform == PLATFORM_IOS && [[dict objectForKey:@"device_id"] isEqualToString:deviceID]) {
        return;
    }
    
    int timestamp = [[dict objectForKey:@"timestamp"] intValue];
    if (profile.loginTimestamp > timestamp) {
        return;
    }
    
    NSLog(@"login another place");
    [self logout];
}

//保证单点登录, 和settingviewcontroller unregister实现一样
- (void)logout {
    NSLog(@"quit...");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"user.logout" object:nil];
    
    Token *token = [Token instance];
    token.accessToken = @"";
    token.refreshToken = @"";
    token.expireTimestamp = 0;
    [token save];
    
    Profile *profile = [Profile instance];
    profile.uid = 0;
    profile.name = @"";
    profile.storeID = 0;
    profile.avatar = @"";
    profile.loginTimestamp = 0;
    [profile save];
    
    [[IMService instance] sendUnreadCount:0];
    [[IMService instance] stop];

    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    LoginViewController *ctrl = [[LoginViewController alloc] init];
    ctrl.hint = YES;
    [UIApplication sharedApplication].keyWindow.rootViewController = ctrl;
}

#pragma mark - function
-(void) resetConversationsViewControllerNewState{
    BOOL shouldClearNewCount = YES;
    for (Conversation *conv in self.conversations) {
        if (conv.newMsgCount > 0) {
            shouldClearNewCount = NO;
            break;
        }
    }
    
    if (shouldClearNewCount) {
        [self clearNewOnTarBar];
    }
    
}

- (void)setNewOnTabBar {
    
}

- (void)clearNewOnTarBar {
    
}


- (void)appWillResignActive {
    NSLog(@"app will resign active");
    int c = 0;
    for (Conversation *conv in self.conversations) {
        c += conv.newMsgCount;
    }
    NSLog(@"unread count:%d", c);
    [[IMService instance] sendUnreadCount:c];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:c];
}


- (void)onUserLogout:(NSNotification*) notification {
    [super onUserLogout:notification];
    [[IMService instance] removeConnectionObserver:self];
    [[IMService instance] removeCustomerMessageObserver:self];
    [[IMService instance] removeSystemMessageObserver:self];
}

#pragma mark MessageViewControllerUserDelegate
//从本地获取用户信息, IUser的name字段为空时，显示identifier字段
- (IUser*)getUser:(int64_t)uid appID:(int64_t)appID {
    User *user = [User load:uid appID:appID];

    IUser *u = [[IUser alloc] init];
    u.uid = uid;
    if (user.name.length > 0) {
        u.name = user.name;
    }
    u.avatarURL = user.avatarURL;
    u.identifier = [NSString stringWithFormat:@"匿名(%lld)", uid];
    u.timestamp = user.timestamp;
    return u;
}

//从服务器获取用户信息
- (void)asyncGetUser:(int64_t)uid appID:(int64_t)appID cb:(void(^)(IUser*))cb {
    if ([Token instance].isAccessTokenExpired) {
        return;
    }
    
    AFHTTPSessionManager *manager = [API newSessionManager];
    NSString *url = [NSString stringWithFormat:@"customers/%lld/%lld", appID, uid];
    [manager GET:url
      parameters:nil
        progress:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             NSLog(@"response:%@", responseObject);
             NSString *name = [responseObject objectForKey:@"name"];
             NSString *avatar = [responseObject objectForKey:@"avatar"];
             if (name.length > 0) {
                 User *user = [[User alloc] init];
                 user.appID = appID;
                 user.uid = uid;
                 user.name = name;
                 user.avatarURL = avatar ? avatar : @"";
                 user.timestamp = (int)time(NULL);
                 [User save:user];
                 
                 IUser *u = [[IUser alloc] init];
                 u.uid = uid;
                 if (user.name.length > 0) {
                     u.name = user.name;
                 }
                 u.avatarURL = avatar ? avatar : @"";
                 u.identifier = [NSString stringWithFormat:@"匿名(%lld)", uid];
                 cb(u);
             }
         }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSLog(@"failure");
         }
     ];
}

@end
