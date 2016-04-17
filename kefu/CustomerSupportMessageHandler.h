//
//  CustomerSupportMessageHandler.h
//  kefu
//
//  Created by houxh on 16/4/16.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <gobelieve/IMService.h>

@interface CustomerSupportMessageHandler : NSObject<IMCustomerMessageHandler>
+(CustomerSupportMessageHandler*)instance;
@end


