//
//  PasscodeManager.h
//  Secretnote
//
//  Created by Kim Young Hoo on 10. 10. 11..
//  Copyright 2010 Codingrobots. All rights reserved.
//

@interface PasscodeManager : NSObject {

	NSString *_passcode;
}

+ (PasscodeManager *)sharedPasscodeManager;

@property (nonatomic, retain) NSString *passcode;

- (BOOL)hasPasscode;

@end
