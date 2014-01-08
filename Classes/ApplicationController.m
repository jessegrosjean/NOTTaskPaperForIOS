//
//  ApplicationController.m
// PlainText
//
//  Created by Jesse Grosjean on 6/24/10.
//

#import "ApplicationController.h"
#import "ApplicationViewController.h"
#import "NSFileManager_Additions.h"
#import "PasscodeViewController.h"
#import "PasscodeManager.h"
#import "ApplicationView.h"
#import "PathController.h"
#import "PathModel.h"
#include <sys/stat.h>
#include <dirent.h>
#import "KeychainManager.h"
#import "SettingsViewController.h" 

@implementation ApplicationController

+ (void)initialize {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [NSNumber numberWithBool:YES], FirstLaunch,
															 [NSNumber numberWithBool:YES], RemoveAdsDefaultsKey,
															 [NSNumber numberWithFloat:1.0], ScreenBrightnessDefaultsKey,
#if defined(WRITEROOM) || defined(TASKPAPER)
                                                             [NSNumber numberWithInteger:PasscodeTimeoutImmediately], PasscodeTimeoutDefaultsKey,
#endif
															 nil]];
}

#pragma mark -
#pragma mark Memory management

- (id)init {
	self = [super init];
	pathController = [[PathController alloc] initWithLocalRoot:nil serverRoot:nil persistentStorePath:nil];
	return self;
}

- (void)dealloc {
	[pathController release];
	[applicationViewController release];
    [window release];
    [super dealloc];
}

- (void)simulateMemoryWarning {
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"UISimulatedMemoryWarningNotification", NULL, NULL, true);
}

- (void)beginSimulateMemoryWarnings {
	//[self performSelector:@selector(beginSimulateMemoryWarnings) withObject:nil afterDelay:((float) rand() / (float) RAND_MAX) * 1];
	//[self simulateMemoryWarning];
}

- (CGFloat)brightness {
	return [[NSUserDefaults standardUserDefaults] floatForKey:ScreenBrightnessDefaultsKey];
}

- (void)setBrightness:(CGFloat)brightness {
	if (brightness == 1) {
		[screenDimmerWindow release];
		screenDimmerWindow = nil;
	} else {
		if (!screenDimmerWindow) {
			screenDimmerWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
			screenDimmerWindow.userInteractionEnabled = NO;
            //screenDimmerWindow.windowLevel = 10000000;
            //screenDimmerWindow.windowLevel = UIWindowLevelAlert - 1;
			screenDimmerWindow.hidden = NO;
			//[screenDimmerWindow makeKeyAndVisible];
		}
		screenDimmerWindow.backgroundColor = [UIColor colorWithWhite:0 alpha:1.0 - brightness];
	}
	[[NSUserDefaults standardUserDefaults] setFloat:brightness forKey:ScreenBrightnessDefaultsKey];
}

- (BOOL)isIOS32OrLater {
	return [[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)];
}

- (BOOL)isIOS4OrLater {
	return [[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)];
}

- (BOOL)removeAdsEnabled {
	return [[NSUserDefaults standardUserDefaults] boolForKey:RemoveAdsDefaultsKey];
}

- (void)setRemoveAdsEnabled:(BOOL)enabled {
	[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:RemoveAdsDefaultsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:RemoveAdsChangedNotification object:self];
}

@synthesize window;
@synthesize applicationViewController;
@synthesize pathController;

#pragma mark -
#pragma mark Application lifecycle

- (NSString *)loadBundleFile:(NSString *)filename {
	NSString *sourcePath = [[NSBundle mainBundle] pathForResource:[filename stringByDeletingPathExtension] ofType:[filename pathExtension]];
	NSString *destinationPath = [[[NSFileManager defaultManager] documentDirectory] stringByAppendingPathComponent:filename];
	if ([[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:NULL]) {
		return destinationPath;
	}
	return nil;
}

- (void)closePasscodeScreenIfPasscodeEnabled {
    if ([self.applicationViewController.modalViewController isKindOfClass:[PasscodeViewController class]]) {
        [self.applicationViewController.modalViewController dismissModalViewControllerAnimated:NO];
    }
}

- (void)showPasscodeScreenIfPasscodeEnabled {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:PasscodeEnableDefaultsKey]) {
        if ([[PasscodeManager sharedPasscodeManager] hasPasscode]) {
            if (![self.applicationViewController.modalViewController isKindOfClass:[PasscodeViewController class]])  {
                PasscodeViewController *passcodeViewController = [[[PasscodeViewController alloc] initWithNibName:@"PasscodeViewController" bundle:nil] autorelease];
                passcodeViewController.viewState = PasscodeCheck;
                if (IS_IPAD) passcodeViewController.view.backgroundColor = [UIColor colorWithRed:224.0/255.0 green:227.0/255.0 blue:232.0/255.0 alpha:1.0];
                if ([SettingsViewController showing]) {
                    [self.applicationViewController dismissModalViewControllerAnimated:NO];
                }
                [self.applicationViewController presentModalViewController:passcodeViewController animated:NO];
                UIImageView *splashView = [[[UIImageView alloc] initWithFrame:window.bounds] autorelease];
                splashView.image = [UIImage imageNamed:@"Default.png"];
                [window addSubview:splashView];
                [window bringSubviewToFront:splashView];
                [UIView beginAnimations:nil context:splashView];
                [UIView setAnimationDuration:0.1];
                [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:window cache:YES];
                [UIView setAnimationDelegate:self];
                [UIView setAnimationDidStopSelector:@selector(startupAnimationDone:finished:context:)];
                splashView.alpha = 0.0;
                [UIView commitAnimations];
            }
        }
    }
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions { 
	[self beginSimulateMemoryWarnings];
	   
	if (NSClassFromString(@"UIMenuItem")) {
		UIMenuController *menuController = [UIMenuController sharedMenuController];
		if ([menuController respondsToSelector:@selector(setMenuItems:)]) {
			[menuController setMenuItems:[NSArray arrayWithObjects:
										  [[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Word Count", nil) action:@selector(showWordCount:)] autorelease],
										  [[[UIMenuItem alloc] initWithTitle:@"…" action:@selector(showInfo:)] autorelease],
										  nil]];
		}
	}
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString *lastLaunchVersion = [defaults objectForKey:LastLaunchedVersionKey];
    
	if (![lastLaunchVersion isEqualToString:currentVersion]) {
		if (!lastLaunchVersion) {
            if (![PATH_CONTROLLER isLinked]) {
#ifdef TASKPAPER
                NSString *destinationPath = [self loadBundleFile:@"Hello.taskpaper"];
#else
                NSString *destinationPath = [self loadBundleFile:@"Hello.txt"];
#endif
                if (destinationPath != nil && IS_IPAD) {
                    pathController.openFilePath = destinationPath;
                }
#ifdef TASKPAPER
                [self loadBundleFile:@"Tips & Tricks.taskpaper"];
#else
                [self loadBundleFile:@"Tips & Tricks.txt"];
#endif
            }
		}
		[defaults setObject:currentVersion forKey:LastLaunchedVersionKey];	
	}   
			
	NSString *openFolderPath = pathController.openFolderPath;
	NSString *openDocumentPath = pathController.openFilePath;

	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	applicationViewController = [ApplicationViewController alloc];
	applicationViewController = [applicationViewController init]; // hack so APP_VIEW_CONTROLLER works
	//applicationViewController.wantsFullScreenLayout = YES;
	applicationViewController.view; // load early.
	window.backgroundColor = [UIColor blackColor];//[APP_VIEW_CONTROLLER paperColor];
	
	[UIView setAnimationsEnabled:NO];
	applicationViewController.showStatusBar = applicationViewController.showStatusBar;
	[UIView setAnimationsEnabled:YES];
	
	if ([window respondsToSelector:@selector(setRootViewController:)]) {
		window.rootViewController = applicationViewController;
	} else {
		[window addSubview:applicationViewController.view];
	}

	[applicationViewController.view layoutSubviews];
        
	if (openFolderPath) {
		if (![applicationViewController openItem:openFolderPath animated:NO]) {
			[applicationViewController openItem:[fileManager documentDirectory] animated:NO];
		}
	} else {
		[applicationViewController openItem:[fileManager documentDirectory] animated:NO];
	}

	if (openDocumentPath) {
		[applicationViewController openItem:openDocumentPath animated:NO];
	}
		
	[window makeKeyAndVisible];
	[self setBrightness:[self brightness]];
	
#ifdef WRITEROOM // Fade in writeroom since color might not match startup color.
	UIImageView *splashView = [[[UIImageView alloc] initWithFrame:window.bounds] autorelease];
	splashView.image = [UIImage imageNamed:@"Default.png"];
	[window addSubview:splashView];
	[window bringSubviewToFront:splashView];
	[UIView beginAnimations:nil context:splashView];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:window cache:YES];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(startupAnimationDone:finished:context:)];
	splashView.alpha = 0.0;
	[UIView commitAnimations];
#endif
    
    [self showPasscodeScreenIfPasscodeEnabled];
    if ([self.applicationViewController.modalViewController isKindOfClass:[PasscodeViewController class]])  {
        [((PasscodeViewController *)self.applicationViewController.modalViewController).hiddenTextField becomeFirstResponder];
    }
    
    NSURL *launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
	NSInteger majorVersion = 
    [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] integerValue];
	if (launchURL && majorVersion < 4) {
		// Pre-iOS 4.0 won't call application:handleOpenURL; this code is only needed if you support
		// iOS versions 3.2 or below
		[self application:application handleOpenURL:launchURL];
		return NO;
	}

	return YES;
}

- (void)startupAnimationDone:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	[(UIView*)context removeFromSuperview];
}

- (BOOL)append:(NSString *)text toFile:(NSString *)path encoding:(NSStringEncoding)enc;
{
    BOOL result = YES;
    NSFileHandle* fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!fh) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        fh = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    if (!fh) return NO;
    @try {
        [fh seekToEndOfFile];
        [fh writeData:[text dataUsingEncoding:enc]];
    }
    @catch (NSException * e) {
        result = NO;
    }
    [fh closeFile];
    return result;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	if ([url isFileURL]) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *readOnlyInboxPath = [url path];
		NSString *localRoot = [PATH_CONTROLLER localRoot];
		NSString *destinationPath = [fileManager conflictPathForPath:[localRoot stringByAppendingPathComponent:[readOnlyInboxPath lastPathComponent]] includeMessage:NO error:NULL];
		NSError *error;
		
		if ([fileManager copyItemAtPath:readOnlyInboxPath toPath:destinationPath error:&error]) {
			[fileManager removeItemAtPath:readOnlyInboxPath error:NULL];
			if ([[fileManager contentsOfDirectoryAtPath:[fileManager readOnlyInboxDirectory] error:NULL] count] == 0) { // try to hide Inbox folder.
				[fileManager removeItemAtPath:[fileManager readOnlyInboxDirectory] error:NULL];
			}
			[APP_VIEW_CONTROLLER openItem:destinationPath animated:NO];
		} else {
			LogError(@"Copy from Inbox failed %@", error);
		}
		return YES;
	} else {
        if ([[DBSession sharedSession] handleOpenURL:url]) {
            if ([[DBSession sharedSession] isLinked]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:DropboxLoginSuccessNotification object:nil];
                [PATH_CONTROLLER performSelector:@selector(loginSuccess)];
            } else {
                [PATH_CONTROLLER performSelector:@selector(loginFailed)];                
            }
            return YES;
        }
        NSString *urlString = [url absoluteString];
        
        if ([urlString hasPrefix:[NSString stringWithFormat:@"%@://create", [url scheme]]]) {
            NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
            [formatter setDateFormat:@"yyyy-MM-dd HHmmss"];
            
            NSString *newFilePath = [[PATH_CONTROLLER localRoot] stringByAppendingPathComponent:[NSString stringWithFormat:@"Untitled-%@", [formatter stringFromDate:[NSDate date]]]];
            newFilePath = [newFilePath stringByAppendingPathExtension:[PathController defaultTextFileType]];
                        
            NSString *query = [url query];
            NSString *body = @"";
            if ([query hasPrefix:@"body="]) {
                body = [[query substringFromIndex:5] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            }
            [self append:body toFile:newFilePath encoding:NSUTF8StringEncoding];
            [APP_VIEW_CONTROLLER openItem:[PATH_CONTROLLER localRoot] animated:NO];
            [APP_VIEW_CONTROLLER openItem:newFilePath animated:NO];

            return YES;
        }
        
        if ([urlString isEqualToString:[NSString stringWithFormat:@"%@://new", [url scheme]]]
            || [urlString isEqualToString:[NSString stringWithFormat:@"%@://new/", [url scheme]]]) {
            [APP_VIEW_CONTROLLER newFile:nil];
            return YES;
        }
        
        if ([urlString hasPrefix:[NSString stringWithFormat:@"%@://search/", [url scheme]]]) {
            [APP_VIEW_CONTROLLER openItem:[PATH_CONTROLLER localRoot] animated:NO];
            [APP_VIEW_CONTROLLER search:[url lastPathComponent]];
            return YES;
        }
        
        if ([urlString hasPrefix:[NSString stringWithFormat:@"%@://open", [url scheme]]] ||
            [urlString hasPrefix:[NSString stringWithFormat:@"%@://new/", [url scheme]]]) {
            NSString *openPath = [url path];
            NSArray *pathComponents = [openPath pathComponents];
            NSString *lastContainingPath = [PATH_CONTROLLER localRoot];
            NSString *lastPathInURL = [url lastPathComponent];
            
            if ([pathComponents count] > 2) { //Find last directory
                for (int i = 1; i < [pathComponents count] - 1; i++) {
                    lastContainingPath = [lastContainingPath stringByAppendingPathComponent:[pathComponents objectAtIndex:i]];
                }
            }
            
            if ([urlString hasPrefix:[NSString stringWithFormat:@"%@://new/", [url scheme]]]) {
                NSString *containingPath = [PATH_CONTROLLER localRoot];
                [APP_VIEW_CONTROLLER openItem:containingPath animated:NO];
                for (int i = 1; i < [pathComponents count] - 1; i++) {
                    containingPath = [containingPath stringByAppendingPathComponent:[pathComponents objectAtIndex:i]];
                    [APP_VIEW_CONTROLLER openItem:containingPath animated:NO];
                }
                NSString *newFilePath = [lastContainingPath stringByAppendingPathComponent:[url lastPathComponent]];
                if ([[newFilePath pathExtension] isEqualToString:@""]) {
                    newFilePath = [newFilePath stringByAppendingPathExtension:[PathController defaultTextFileType]];
                }
                
                NSString *query = [url query];
                NSString *body = @"";
                if ([query hasPrefix:@"body="]) {
                    body = [[query substringFromIndex:5] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                }
                [self append:body toFile:newFilePath encoding:NSUTF8StringEncoding];
                [APP_VIEW_CONTROLLER openItem:newFilePath animated:NO];
                return YES;
            }
            
            //To avoid insensitive problem, doesn't open file direct but find same file name in last directory
            NSDirectoryEnumerator *directoryEnum = [[NSFileManager defaultManager] enumeratorAtPath:lastContainingPath];
            NSString *file;
            [directoryEnum skipDescendents];
            while (file = [directoryEnum nextObject]) {
                if ([[file uppercaseString] isEqualToString:[lastPathInURL uppercaseString]]) {
                    NSString *containingPath = [PATH_CONTROLLER localRoot];
                    [APP_VIEW_CONTROLLER openItem:containingPath animated:NO];
                    for (int i = 1; i < [pathComponents count] - 1; i++) {
                        containingPath = [containingPath stringByAppendingPathComponent:[pathComponents objectAtIndex:i]];
                        [APP_VIEW_CONTROLLER openItem:containingPath animated:NO];
                    }
                    NSString *query = [url query];
                    if ([query hasPrefix:@"append="]) {
                        NSString *line = [NSString stringWithFormat:@"\n%@", [[query substringFromIndex:7] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                        [self append:line toFile:[lastContainingPath stringByAppendingPathComponent:file] encoding:NSUTF8StringEncoding];
                    } 
                    [APP_VIEW_CONTROLLER openItem:[lastContainingPath stringByAppendingPathComponent:file] animated:NO];
                    return YES;
                }
                [directoryEnum skipDescendents];
            }
            
            //If fail, do it again with default file type setting
            if ([[lastPathInURL pathExtension] isEqualToString:@""]) {
                lastPathInURL = [lastPathInURL stringByAppendingPathExtension:[PathController defaultTextFileType]];
                directoryEnum = [[NSFileManager defaultManager] enumeratorAtPath:lastContainingPath];
                [directoryEnum skipDescendents];
                while (file = [directoryEnum nextObject]) {
                    if ([[file uppercaseString] isEqualToString:[lastPathInURL uppercaseString]]) {
                        NSString *containingPath = [PATH_CONTROLLER localRoot];
                        [APP_VIEW_CONTROLLER openItem:containingPath animated:NO];
                        for (int i = 1; i < [pathComponents count] - 1; i++) {
                            containingPath = [containingPath stringByAppendingPathComponent:[pathComponents objectAtIndex:i]];
                            [APP_VIEW_CONTROLLER openItem:containingPath animated:NO];
                        }
                        NSString *query = [url query];
                        if ([query hasPrefix:@"append="]) {
                            NSString *line = [NSString stringWithFormat:@"\n%@", [[query substringFromIndex:7] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                            [self append:line toFile:[lastContainingPath stringByAppendingPathComponent:file] encoding:NSUTF8StringEncoding];
                        }
                        [APP_VIEW_CONTROLLER openItem:[lastContainingPath stringByAppendingPathComponent:file] animated:NO];
                        return YES;
                    }
                    [directoryEnum skipDescendents];
                }
            }

        }
        return NO;
	}
}

- (void)applicationWillResignActive:(UIApplication *)application {
	[APP_VIEW_CONTROLLER saveState];
}

- (void)checkForFinishedBackgroundSync {
	if (![PATH_CONTROLLER isSyncInProgress] || reenteringForeground) {
		[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
		LogDebug(@"Finished background sync", nil);

	} else {
		[self performSelector:@selector(checkForFinishedBackgroundSync) withObject:nil afterDelay:0];
	}
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	LogDebug(@"Start applicationDidEnterBackground", nil);

#ifdef TASKPAPER
    [APP_VIEW_CONTROLLER hideKeyboard];
#endif
	[APP_VIEW_CONTROLLER saveState];
    if ([PATH_CONTROLLER syncAutomatically]) {
        [PATH_CONTROLLER enqueueSyncOperationsForVisiblePaths];
    }
	
	if ([[UIDevice currentDevice] isMultitaskingSupported]) {
		reenteringForeground = NO;
		backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:NULL];
		[self performSelector:@selector(checkForFinishedBackgroundSync) withObject:nil afterDelay:0];	
	}
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:LastTimeGoneDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self showPasscodeScreenIfPasscodeEnabled];

	LogDebug(@"Finished applicationDidEnterBackground", nil);
}
	 
- (void)applicationWillEnterForeground:(UIApplication *)application {
	LogDebug(@"applicationWillEnterForeground", nil);
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:PasscodeEnableDefaultsKey]) {
        NSDate *lastTimeGone = [[NSUserDefaults standardUserDefaults] valueForKey:LastTimeGoneDefaultsKey];
        if (lastTimeGone) {
            NSDate *now = [NSDate date];
            NSTimeInterval interval = [now timeIntervalSinceDate:lastTimeGone];
            NSTimeInterval keyInterval = 0;
            NSUInteger passcodeTimeoutKeyValue = [[NSUserDefaults standardUserDefaults] integerForKey:PasscodeTimeoutDefaultsKey];
            switch (passcodeTimeoutKeyValue) {
                case 0:
                    break;
                case 1:
                    keyInterval = 60000 * 1;
                    break;
                case 2:
                    keyInterval = 60000 * 5;
                    break;
                case 3:
                    keyInterval = 60000 * 15;
                    break;
                default:
                    break;
            }
            if (keyInterval != 0 && interval < keyInterval) {
                [self closePasscodeScreenIfPasscodeEnabled];
            }
        }
    }
    
    if ([self.applicationViewController.modalViewController isKindOfClass:[PasscodeViewController class]])  {
        [((PasscodeViewController *)self.applicationViewController.modalViewController).hiddenTextField becomeFirstResponder];
    }
    
	reenteringForeground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	LogDebug(@"applicationDidBecomeActive", nil);

	if ([PATH_CONTROLLER syncAutomatically]) {
		[PATH_CONTROLLER enqueueSyncOperationsForVisiblePaths];
	}
}

- (void)application:(UIApplication *)application willChangeStatusBarFrame:(CGRect)newStatusBarFrame {
}

- (void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)oldStatusBarFrame {
	[APP_VIEW_CONTROLLER.view setNeedsLayout];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	LogInfo(@"Application will terminate started...");
	
	[APP_VIEW_CONTROLLER saveState];
	[PATH_CONTROLLER enqueueSyncOperationsForVisiblePaths];
		
	if (![self isIOS4OrLater] || ![[UIDevice currentDevice] isMultitaskingSupported]) {
		NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
		while ([runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
			if (![PATH_CONTROLLER isSyncInProgress]) {
				break;
			}
		}
	}
		
	LogInfo(@"Application will terminate finished...");
}

#pragma mark -
#pragma mark HTNotifierDelegate

- (UIViewController *)rootViewControllerForNotice {
	return applicationViewController;
}

@end

NSString *LastLaunchedVersionKey = @"LastLaunchedVersionKey";
NSString *RemoveAdsDefaultsKey = @"RemoveAdsDefaultsKey";
NSString *RemoveAdsChangedNotification = @"RemoveAdsChangedNotification";
NSString *ScreenBrightnessDefaultsKey = @"ScreenBrightnessDefaultsKey";
NSString *PasscodeEnableDefaultsKey = @"PasscodeEnableDefaultsKey";
NSString *PasscodeTimeoutDefaultsKey = @"PasscodeTimeoutDefaultsKey";
NSString *LastTimeGoneDefaultsKey = @"LastTimeGoneDefaultsKey";
NSString *DropboxLoginSuccessNotification = @"DropboxLoginSuccessNotification";
NSString *FirstLaunch = @"FirstLaunch";
