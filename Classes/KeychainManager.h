//
//  KeychainManager.h
//  PlainText
//
//  Created by Young Hoo Kim on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@interface KeychainManager : NSObject {
    NSString *processName;
}

+ (KeychainManager *)sharedKeychainManager;

- (NSString *)valueForKey:(NSString *)key;
- (void)setValue:(NSString *)value forKey:(NSString *)key;

@end
