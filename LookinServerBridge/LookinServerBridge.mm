//
//  LookinServerBridge.mm
//  LookinServerBridge
//
//  Created by TBD on 2019/11/5.
//  Copyright (c) 2019 ShenZhen iBOXCHAIN Information Technology Co.,Ltd.. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#if TARGET_OS_SIMULATOR
#error Do not support the simulator, please use the real iPhone Device.
#endif

#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <Foundation/Foundation.h>
#import "CaptainHook/CaptainHook.h"
#include <notify.h> // not required; for examples only

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()


@interface LookinServerBridge : NSObject

@end

@implementation LookinServerBridge

+ (void)load {
    NSLog(@"[*] LS: Loading...");
    NSString *bundleID = [NSBundle.mainBundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleIdentifierKey];
    NSLog(@"[*] LS: Bundle ID: %@", bundleID);
    
    // 排除 springboard
    if ([bundleID.lowercaseString isEqualToString:@"com.apple.springboard"]) {
        NSLog(@"[!] LS: Not Load for SpringBoard.");
        return;
    }
    
    // 排除 APP 自带 LookingServer 的
    uint32_t image_count = _dyld_image_count();
    const char *app_lookin_server = NULL;
    for (uint32_t index = 0; index < image_count; ++index) {
        const char *image_name = _dyld_get_image_name(index);
        if (strstr(image_name, "LookinServer.framework/LookinServer") != NULL) {
            app_lookin_server = image_name;
            break;
        }
    }
    if (app_lookin_server != NULL) {
        NSLog(@"[!] LS: Is Loaded App LS: %s.", app_lookin_server);
        return;
    }
    
    // 其他正常情况, 加载 LookinServer
    dlopen("/Library/Frameworks/LookinServer.framework/LookinServer", RTLD_GLOBAL | RTLD_NOW);
    NSLog(@"[+] LS: Loaded for '%@'.", bundleID);
}

@end

