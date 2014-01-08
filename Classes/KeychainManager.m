//
//  KeychainManager.m
//  PlainText
//
//  Created by Young Hoo Kim on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KeychainManager.h"
#import "SynthesizeSingleton.h"
#import "SFHFKeychainUtils.h"


@implementation KeychainManager

+ (KeychainManager *)sharedKeychainManager {
    static KeychainManager *manager = nil;
    if (manager == nil) {
        manager = [[KeychainManager alloc] init];
    }
    return manager;
}

- (void)dealloc {
    [processName release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self != nil) {
        processName = [[[NSProcessInfo processInfo] processName] retain];
    }
    return self;
}

- (NSString *)valueForKey:(NSString *)key {
    return [SFHFKeychainUtils getPasswordForUsername:key andServiceName:processName error:nil]; 
}

- (void)setValue:(NSString *)value forKey:(NSString *)key {
    [SFHFKeychainUtils storeUsername:key andPassword:value forServiceName:processName updateExisting:YES error:nil];
}

@end
