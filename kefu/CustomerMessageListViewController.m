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
#import "MessageConversationCell.h"
#import "LevelDB.h"
#import "AFNetworking.h"
#import "CustomerConversation.h"
#import <gobelieve/IMHttpAPI.h>
#import <gobelieve/IMService.h>
#import "AppDB.h"
#import "SettingViewController.h"
#import "Token.h"
#import "Config.h"

//RGB颜色
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
//RGB颜色和不透明度
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f \
alpha:(a)]



#define kConversationCellHeight         60

@interface CustomerMessageListViewController()<UITableViewDelegate, UITableViewDataSource,
TCPConnectionObserver, CustomerMessageObserver, MessageViewControllerUserDelegate>
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
        self.userDelegate = self;
    }
    return self;
}

-(void)dealloc {
    NSLog(@"CustomerMessageListViewController dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(NSString*)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    Token *token = [Token instance];
    
    NSString *path = [self getDocumentPath];
    NSString *customerPath = [NSString stringWithFormat:@"%@/%lld/customer", path, token.uid];
    [[CustomerSupportMessageDB instance] setDbPath:customerPath];
    
    [IMHttpAPI instance].accessToken = token.accessToken;
    [IMService instance].uid = token.uid;
    [IMService instance].token = token.accessToken;
    [[IMService instance] start];
    
    self.currentUID = token.uid;
    self.storeID = token.storeID;
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
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(newCustomerMessage:) name:LATEST_CUSTOMER_MESSAGE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(onUserLogout:) name:@"user.logout" object:nil];
    
    id<ConversationIterator> iterator =  [[CustomerSupportMessageDB instance] newConversationIterator];
    Conversation * conversation = [iterator next];
    while (conversation) {
        [self.conversations addObject:conversation];
        conversation = [iterator next];
    }
    
    for (Conversation *conv in self.conversations) {
        [self updateConversationName:conv];
        [self updateConversationDetail:conv];
    }

    NSArray *sortedArray = [self.conversations sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        Conversation *c1 = obj1;
        Conversation *c2 = obj2;
        
        int t1 = c1.timestamp;
        int t2 = c2.timestamp;
        
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
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.refreshTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_event_handler(self.refreshTimer, ^{
        [wself refreshAccessToken];
    });
    
    [self startRefreshTimer];
}


-(void)prepareTimer {
    Token *token = [Token instance];
    int now = (int)time(NULL);
    if (now >= token.expireTimestamp - 1) {
        dispatch_time_t w = dispatch_walltime(NULL, 0);
        dispatch_source_set_timer(self.refreshTimer, w, DISPATCH_TIME_FOREVER, 0);
    } else {
        dispatch_time_t w = dispatch_walltime(NULL, (token.expireTimestamp - now - 1)*NSEC_PER_SEC);
        dispatch_source_set_timer(self.refreshTimer, w, DISPATCH_TIME_FOREVER, 0);
    }
}

-(void)startRefreshTimer {
    [self prepareTimer];
    dispatch_resume(self.refreshTimer);
}

-(void)refreshAccessToken {
    Token *token = [Token instance];
    if (!token.accessToken) {
        return;
    }
    
    NSString *base = [NSString stringWithFormat:@"%@/", KEFU_API];
    NSURL *baseURL = [NSURL URLWithString:base];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSDictionary *dict = @{@"refresh_token":token.refreshToken};
    
    [manager POST:@"auth/refresh_token"
       parameters:dict
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              NSLog(@"refresh token success:%@", responseObject);
              token.accessToken = [responseObject objectForKey:@"access_token"];
              token.refreshToken = [responseObject objectForKey:@"refresh_token"];
              token.uid = [[responseObject objectForKey:@"uid"] longLongValue];
              token.storeID = [[responseObject objectForKey:@"store_id"] longLongValue];
              token.name = [responseObject objectForKey:@"name"];
              token.expireTimestamp = (int)time(NULL) + [[responseObject objectForKey:@"expires_in"] intValue];
              [token save];
              [self prepareTimer];
              
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSLog(@"refresh token failure");
              
              self.refreshFailCount = self.refreshFailCount + 1;
              int64_t timeout;
              if (self.refreshFailCount > 60) {
                  timeout = 60*NSEC_PER_SEC;
              } else {
                  timeout = (int64_t)self.refreshFailCount*NSEC_PER_SEC;
              }
              
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout), dispatch_get_main_queue(), ^{
                  [self prepareTimer];
              });
              
          }
     ];


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
        IUser *u = [self.userDelegate getUser:conversation.cid];
        if (u.name.length > 0) {
            conversation.name = u.name;
            conversation.avatarURL = u.avatarURL;
        } else {
            conversation.name = u.identifier;
            conversation.avatarURL = u.avatarURL;
            
            [self.userDelegate asyncGetUser:conversation.cid cb:^(IUser *u) {
                conversation.name = u.name;
                conversation.avatarURL = u.avatarURL;
            }];
        }
    }
}

-(void)home:(UIBarButtonItem *)sender {

    [[IMService instance] removeConnectionObserver:self];
    [[IMService instance] removeCustomerMessageObserver:self];
    
    [self.navigationController popViewControllerAnimated:YES];
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

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        Conversation *con = [self.conversations objectAtIndex:indexPath.row];
        if (con.type == CONVERSATION_CUSTOMER_SERVICE) {
            [[CustomerMessageDB instance] clearConversation:con.cid];
        }
        
        [self.conversations removeObject:con];
        
        /*IOS8中删除最后一个cell的时，报一个错误
         [RemindersCell _setDeleteAnimationInProgress:]: message sent to deallocated instance
         在重新刷新tableView的时候延迟一下*/
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableview reloadData];
        });
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    CustomerConversation *con = [self.conversations objectAtIndex:indexPath.row];
    if (con.type == CONVERSATION_CUSTOMER_SERVICE) {
        CustomerSupportViewController *msgController = [[CustomerSupportViewController alloc] init];
        msgController.userDelegate = self.userDelegate;
        msgController.customerAppID = con.customerAppID;
        msgController.customerID = con.customerID;
        msgController.customerName = @"";
        msgController.currentUID = self.currentUID;
        msgController.storeID = self.storeID;
        msgController.isShowUserName = NO;
        msgController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:msgController animated:YES];
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
    cm.isOutgoing = NO;
    
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
        [self setNewOnTabBar];
    }
    
    if (index != 0) {
        //置顶
        [self.conversations removeObjectAtIndex:index];
        [self.conversations insertObject:con atIndex:0];
        [self.tableview reloadData];
    }

}

- (void)newCustomerConversation:(ICustomerMessage*)msg {
    CustomerConversation *con = [[CustomerConversation alloc] init];
    con.type = CONVERSATION_CUSTOMER_SERVICE;
    con.cid = msg.customerID;
    con.customerID = msg.customerID;
    con.customerAppID = msg.customerAppID;
    con.message = msg;
    
    [self updateConversationName:con];
    [self updateConversationDetail:con];
    
    if (self.currentUID == msg.receiver) {
        con.newMsgCount += 1;
        [self setNewOnTabBar];
    }
    
    [self.conversations insertObject:con atIndex:0];
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
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

- (void)newCustomerMessage:(NSNotification*) notification {
    ICustomerMessage *msg = notification.object;
    NSLog(@"new message:%lld, %lld", msg.sender, msg.receiver);
    [self onNewCustomerMessage:msg];
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

- (void)onUserLogout:(NSNotification*) notification {
    [[IMService instance] removeConnectionObserver:self];
    [[IMService instance] removeCustomerMessageObserver:self];
}

#pragma mark MessageViewControllerUserDelegate
//从本地获取用户信息, IUser的name字段为空时，显示identifier字段
- (IUser*)getUser:(int64_t)uid {
    IUser *u = [[IUser alloc] init];
    u.uid = uid;
    u.name = [NSString stringWithFormat:@"uid:%lld", uid];
    u.identifier = u.name;
    return u;
}

//从服务器获取用户信息
- (void)asyncGetUser:(int64_t)uid cb:(void(^)(IUser*))cb {
    
}

@end
