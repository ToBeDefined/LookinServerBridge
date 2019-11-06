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
    NSLog(@"[*] Lookin Server Bridge Loaded");
}

@end

