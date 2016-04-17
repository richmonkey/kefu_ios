//
//  CustomerSupportOutbox.h
//  kefu
//
//  Created by houxh on 16/4/17.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <gobelieve/Outbox.h>
@interface CustomerSupportOutbox : Outbox

+(CustomerSupportOutbox*)instance;

@end
