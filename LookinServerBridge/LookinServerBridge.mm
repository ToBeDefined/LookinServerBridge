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


///
/// 1. copy LookinServer.framework to /usr/lib/LookinServer.framework
/// 2. cd /usr/lib/LookinServer.framework/
/// 3. chmod 777 LookinServer
/// 4. cd /Library/Frameworks/
/// 5. ln -s /usr/lib/LookinServer.framework LookinServer.framework
///
static void *_lookin_server_handle = NULL;
__attribute__((constructor(0)))
static void _constructor(int argc, const char *argv[]) {
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
    
    if (_lookin_server_handle != NULL) {
        dlclose(_lookin_server_handle);
        _lookin_server_handle = NULL;
    }
    // 其他正常情况, 加载 LookinServer
    _lookin_server_handle = dlopen("/Library/Frameworks/LookinServer.framework/LookinServer", RTLD_GLOBAL | RTLD_NOW);
    NSLog(@"[+] LS: Loaded for '%@'.", bundleID);
}

__attribute__((destructor(0)))
static void _destructor(int argc, const char *argv[]) {
    if (_lookin_server_handle != NULL) {
        dlclose(_lookin_server_handle);
        _lookin_server_handle = NULL;
        NSString *bundleID = [NSBundle.mainBundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleIdentifierKey];
        NSLog(@"[-] LS: Close for '%@'.", bundleID);
    }
}
