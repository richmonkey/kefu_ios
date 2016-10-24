//
//  XWCustomerOutbox.h
//  kefu
//
//  Created by houxh on 16/10/24.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Outbox.h"

@interface XWCustomerOutbox  : Outbox
+(XWCustomerOutbox*)instance;
@end
