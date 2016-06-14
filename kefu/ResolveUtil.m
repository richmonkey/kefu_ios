//
//  ResolveUtil.m
//  kefu
//
//  Created by houxh on 16/4/24.
//  Copyright © 2016年 beetle. All rights reserved.
//


#include <resolv.h>
#include <arpa/inet.h>
#include <string.h>

#import "ResolveUtil.h"


static void setup_dns_server(res_state res, const char *dns_server);
static void query_ip(res_state res, const char *host, char ip[]);


static void query_ip(res_state res, const char *host, char ip[]) {
    u_char answer[NS_PACKETSZ];
    int len = res_nquery(res, host, ns_c_in, ns_t_a, answer, sizeof(answer));
    
    ns_msg handle;
    ns_initparse(answer, len, &handle);
    
    if(ns_msg_count(handle, ns_s_an) > 0) {
        int count = ns_msg_count(handle, ns_s_an);
        NSLog(@"msg count:%d", count);
        
        ns_rr rr;
        for (int i = 0; i < count; i++) {
            if(ns_parserr(&handle, ns_s_an, i, &rr) == 0) {
                NSLog(@"answer type:%d", ns_rr_type(rr));
                if(ns_rr_type(rr) == ns_t_a){
                    strcpy(ip, inet_ntoa(*(struct in_addr *)ns_rr_rdata(rr)));
                    break;
                }
            }
        }
    }
}

static void setup_dns_server(res_state res, const char *dns_server) {
    res_ninit(res);
    struct in_addr addr;
    inet_aton(dns_server, &addr);
    
    res->nsaddr_list[0].sin_addr = addr;
    res->nsaddr_list[0].sin_family = AF_INET;
    res->nsaddr_list[0].sin_port = htons(NS_DEFAULTPORT);
    res->nscount = 1;
}


@implementation ResolveUtil

+ (NSString *)resolveHost:(NSString *)host usingDNSServer:(NSString *)dnsServer {
    
    struct __res_state res;
    char ip[64];
    memset(ip, '\0', sizeof(ip));
    
    setup_dns_server(&res, [dnsServer cStringUsingEncoding:NSASCIIStringEncoding]);
    
    query_ip(&res, [host cStringUsingEncoding:NSUTF8StringEncoding], ip);
    
    return [[NSString alloc] initWithCString:ip encoding:NSASCIIStringEncoding];
}

@end

