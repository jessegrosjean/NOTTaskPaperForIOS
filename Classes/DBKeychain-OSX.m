//
//  DBKeychain-OSX.m
//  DropboxSDK
//
//  Created by Brian Smith on 4/8/12.
//  Copyright (c) 2012 Dropbox, Inc. All rights reserved.
//

#import "DBKeychain.h"

#import "DBLog.h"

// Whether we think there are credentials stored in the keychain
static NSString *kDBLinkedUserDefaultsKey = @"DropboxLinked";

static char *kDBServiceName;
static char *kDBAccountName = "Dropbox";
static SecKeychainItemRef itemRef;

@implementation DBKeychain

+ (void)initialize {
	if ([self class] != [DBKeychain class]) return;
	NSString *keychainId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
	if (![keychainId length]) {
		keychainId = [[NSBundle mainBundle] bundleIdentifier];
	}
	NSInteger len = [keychainId lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;
	kDBServiceName = malloc(len);
	[keychainId getCString:kDBServiceName maxLength:len encoding:NSUTF8StringEncoding];
}

+ (NSDictionary *)credentials {
	if (![[[NSUserDefaults standardUserDefaults] objectForKey:kDBLinkedUserDefaultsKey] boolValue]) {
		return nil;
	}

	UInt32 dataLen = 0;
	void *pData = NULL;
	OSStatus status = SecKeychainFindGenericPassword(NULL,
													 (int32_t)strlen(kDBServiceName), kDBServiceName,
													 (int32_t)strlen(kDBAccountName), kDBAccountName,
													 &dataLen, &pData, &itemRef);

	NSDictionary *ret = nil;
	if (status == noErr) {
		NSData *data = [NSData dataWithBytes:pData length:dataLen];
		ret = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	} else if (status != errSecItemNotFound) {
		DBLogWarning(@"DropboxSDK: error reading stored credentials (%d)", status);
	}

	status = SecKeychainItemFreeContent(NULL, pData);
	return ret;
}

+ (void)setCredentials:(NSDictionary *)credentials {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:credentials];

	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kDBLinkedUserDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self credentials]; // Make sure itemRef is set if credentials hasn't been called yet

	OSStatus status = noErr;
	if (!itemRef) {
		status = SecKeychainAddGenericPassword(NULL, (int32_t)strlen(kDBServiceName), kDBServiceName,
											   (int32_t)strlen(kDBAccountName), kDBAccountName,
											   (int32_t)[data length], [data bytes], &itemRef);
	} else {
		status = SecKeychainItemModifyAttributesAndData(itemRef, NULL, (int32_t)[data length], [data bytes]);
	}

	if (status != noErr) {
		DBLogWarning(@"DropboxSDK: error setting stored credentials (%d)", status);
	}
}

+ (void)deleteCredentials {
	OSStatus status = SecKeychainItemDelete(itemRef);
	itemRef = NULL;

	if (status == noErr) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kDBLinkedUserDefaultsKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	} else {
		DBLogWarning(@"DropboxSDK: error deleting stored credentials (%d)", status);
	}
}

@end
