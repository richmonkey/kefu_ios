//
//  Config.h
//  kefu
//
//  Created by houxh on 16/4/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#ifndef Config_h
#define Config_h


#ifndef DEBUG

//外网
#define APPID 1670
#define IM_API @"http://api.gobelieve.io"
#define IM_HOST @"imnode.gobelieve.io"
#define KEFU_API @"http://api.kefu.gobelieve.io"

#else

//内网
#define APPID 1453
#define IM_API @"http://192.168.1.103"
#define IM_HOST @"192.168.1.103"
#define KEFU_API @"http://192.168.1.103:60001"

#endif


#endif /* Config_h */
