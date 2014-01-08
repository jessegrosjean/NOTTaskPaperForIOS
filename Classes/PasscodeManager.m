//
//  PasscodeManager.m
//  Secretnote
//
//  Created by Kim Young Hoo on 10. 10. 11..
//  Copyright 2010 Codingrobots. All rights reserved.
//

#import "PasscodeManager.h"

#import "SynthesizeSingleton.h"
#import "SFHFKeychainUtils.h"

@implementation PasscodeManager

+ (PasscodeManager *)sharedPasscodeManager {
    static PasscodeManager *manager = nil;
    if (manager == nil) {
        manager = [[PasscodeManager alloc] init];
    }
    return manager;
}


- (NSString *)passcode
{
	if (_passcode.length == 0) {
		return nil;
	}
	return _passcode;
}

- (void)setPasscode:(NSString *)newPasscode
{
	if (_passcode != newPasscode) {
		[newPasscode retain];
		[_passcode release];
		_passcode = newPasscode;
		NSError *error;
		if (newPasscode == nil) {
			[SFHFKeychainUtils storeUsername:@"kPasscode" andPassword:@"" forServiceName:@"PlainText" updateExisting:YES error:&error];
		} else {
			[SFHFKeychainUtils storeUsername:@"kPasscode" andPassword:_passcode forServiceName:@"PlainText" updateExisting:YES error:&error];
		}
	}
}

- (BOOL)hasPasscode;
{
	NSError *error;
	_passcode = [SFHFKeychainUtils getPasswordForUsername:@"kPasscode" andServiceName:@"PlainText" error:&error];
	[_passcode retain];
	return (self.passcode != nil);
}

- (void)dealloc
{
	[_passcode release], _passcode = nil;
	[super dealloc];
}


@end
