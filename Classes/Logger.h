//
//  Logger.h
//  PlainText
//
//  Created by Jesse Grosjean on 10/8/10.
//

#import <Foundation/Foundation.h>

enum {
	LogLevelDebug = 0,
	LogLevelInfo,
	LogLevelWarn,
	LogLevelError
};
typedef NSUInteger LogLevel;


@interface Logger : NSObject {
	LogLevel logLevel;
	BOOL logLocation;
}

+ (Logger *)sharedInstance;

@property (nonatomic, assign) LogLevel logLevel;
@property (nonatomic, assign) BOOL logLocation;

- (void)log:(NSString *)aString level:(LogLevel)level prettyFunction:(const char *)prettyFunction line:(NSUInteger)line;

@end

#define LOGGER [Logger sharedInstance]
#define LogDebug(...) if ([LOGGER logLevel] <= LogLevelDebug) [LOGGER log:[NSString stringWithFormat:__VA_ARGS__, nil] level:LogLevelDebug prettyFunction:__PRETTY_FUNCTION__ line:__LINE__];
#define LogInfo(...) if ([LOGGER logLevel] <= LogLevelInfo) [LOGGER log:[NSString stringWithFormat:__VA_ARGS__, nil] level:LogLevelInfo prettyFunction:__PRETTY_FUNCTION__ line:__LINE__];
#define LogWarn(...) if ([LOGGER logLevel] <= LogLevelWarn) [LOGGER log:[NSString stringWithFormat:__VA_ARGS__, nil] level:LogLevelWarn prettyFunction:__PRETTY_FUNCTION__ line:__LINE__];
#define LogError(...) if ([LOGGER logLevel] <= LogLevelError) [LOGGER log:[NSString stringWithFormat:__VA_ARGS__, nil] level:LogLevelError prettyFunction:__PRETTY_FUNCTION__ line:__LINE__];

extern NSString *LogLevelDefaultsKey;
extern NSString *LogLocationDefaultsKey;
