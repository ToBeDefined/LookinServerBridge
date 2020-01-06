//
//  LookinServerBridge.mm
//  LookinServerBridge
//
//  Created by TBD on 2019/11/5.
// Copyright (c) 2014-2019 ToBeDefined (http://tbd.tech/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
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

@interface _LookinServerBridge : NSObject
@end

@implementation _LookinServerBridge
@end

#define LSLog(tag, fmt, ...) \
do { \
    NSLog(@"[" @#tag @"] ILS: '%@': " fmt, bundleID, ##__VA_ARGS__); \
} while (0)

static void *_lookin_server_handle = NULL;
__attribute__((constructor(0)))
static void _constructor(int argc, const char *argv[]) {

    NSString *bundleID = [NSBundle.mainBundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleIdentifierKey];
    LSLog(*, @"Inject LookinServer Loading...");
    // 排除 SpringBoard
    if ([bundleID.lowercaseString isEqualToString:@"com.apple.springboard"]) {
        LSLog(!, @"Don't Load Inject LookinServer for SpringBoard App.");
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
        LSLog(!, @"App LookinServer is Loaded: %s.", app_lookin_server);
        return;
    }
    
    // 判断是否已经加载
    if (_lookin_server_handle != NULL) {
        LSLog(!, @"Inject LookinServer is Loaded Before.");
        return;
    }
    
    // 其他正常情况, 加载 LookinServer
    NSString *bundlePath = [NSBundle bundleForClass:[_LookinServerBridge class]].bundlePath;
    NSString *lookinServerPath = [bundlePath stringByAppendingPathComponent:@"LookinServer.framework/LookinServer"];
    LSLog(*, @"Inject LookinServer Path: %@", lookinServerPath);
    
    // LookinServer 二进制文件不存在
    if (![NSFileManager.defaultManager fileExistsAtPath:lookinServerPath]) {
        LSLog(!, @"Inject LookinServer Binary Not Found, Copy Fully LookinServer.framework to: %@", bundlePath);
        return;
    }
    
    // 输出 LookinServer 版本号
    NSString *lookinServerInfoPlistPath = [bundlePath stringByAppendingPathComponent:@"LookinServer.framework/Info.plist"];
    BOOL outputVersionSuccess = NO;
    if ([NSFileManager.defaultManager fileExistsAtPath:lookinServerInfoPlistPath]) {
        NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:lookinServerInfoPlistPath];
        NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
        if (version) {
            LSLog(*, @"Inject LookinServer Version (from Info.plist): %@", version);
            outputVersionSuccess = YES;
        }
    }
    if (!outputVersionSuccess) {
        LSLog(!, @"Inject LookinServer Version Not Found");
    }
    
    // 加载
    _lookin_server_handle = dlopen(lookinServerPath.UTF8String, RTLD_GLOBAL | RTLD_LAZY);
    LSLog(+, @"Inject LookinServer Loaded.");
}

__attribute__((destructor(0)))
static void _destructor(int argc, const char *argv[]) {
    NSString *bundleID = [NSBundle.mainBundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleIdentifierKey];
    if (_lookin_server_handle != NULL) {
        dlclose(_lookin_server_handle);
        _lookin_server_handle = NULL;
        LSLog(-, @"Inject LookinServer Closed.");
    }
}

#undef LSLog
