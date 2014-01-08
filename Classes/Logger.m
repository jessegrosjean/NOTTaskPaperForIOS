//
//  Logger.m
//  PlainText
//
//  Created by Jesse Grosjean on 10/8/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "Logger.h"

#define LOG_FORMAT_NO_LOCATION(fmt, lvl, ...) NSLog((@"[%@] " fmt), lvl, ##__VA_ARGS__)
#define LOG_FORMAT_WITH_LOCATION(fmt, lvl, ...) NSLog((@"%s[Line %d] [%@] " fmt), __PRETTY_FUNCTION__, __LINE__, lvl, ##__VA_ARGS__)

@implementation Logger

+ (id)sharedInstance {
	static id sharedInstance = nil;
	if (sharedInstance == nil) {
		sharedInstance = [[self alloc] init];
	}
	return sharedInstance;
}

+ (void)initialize {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithInteger:LogLevelWarn], LogLevelDefaultsKey,
															 [NSNumber numberWithBool:YES], LogLocationDefaultsKey,
															 nil]];
}

- (id)init {
	self = [super init];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	logLevel = [defaults integerForKey:LogLevelDefaultsKey];
	logLocation = [defaults boolForKey:LogLocationDefaultsKey];
	return self;
}

@synthesize logLevel;

- (void)setLogLevel:(LogLevel)aLevel {
	logLevel = aLevel;
	[[NSUserDefaults standardUserDefaults] setInteger:aLevel forKey:LogLevelDefaultsKey];
}

@synthesize logLocation;

- (void)setLogLocation:(BOOL)aBool {
	logLocation = aBool;
	[[NSUserDefaults standardUserDefaults] setBool:aBool forKey:LogLocationDefaultsKey];
}

- (void)log:(NSString *)aString level:(LogLevel)level prettyFunction:(const char *)prettyFunction line:(NSUInteger)line {
	if (level < logLevel) {
		return;
	}
	
	NSString *levelString = nil;
	
	switch (level) {
		case LogLevelDebug:
			levelString = @"DEBUG";
			break;
		case LogLevelInfo:
			levelString = @"INFO";
			break;
		case LogLevelWarn:
			levelString = @"WARN";
			break;
		case LogLevelError:
			levelString = @"ERROR";
			break;
	}
	
	if (logLocation) {
		NSLog(@"[%@] %s(%d) %@", levelString, prettyFunction, line, aString);
	} else {
		NSLog(@"[%@] %@", levelString, aString);
	}
}

@end

NSString *LogLevelDefaultsKey = @"LogLevelDefaultsKey";
NSString *LogLocationDefaultsKey = @"LogLocationDefaultsKey";