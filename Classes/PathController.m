//
//  PathController.m
//  SyncTest
//
//  Created by Jesse Grosjean on 8/7/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "PathController.h"
#import "DeleteLocalPathOperation.h"
#import "FolderSyncPathOperation.h"
#import "NSFileManager_Additions.h"
#import "ShadowMetadataTextBlob.h"
#import "ApplicationController.h"
#import "NSString_Additions.h"
#import "GetPathOperation.h"
#import "PutPathOperation.h"
#import "NSSet_Additions.h"
#import "ShadowMetadata.h"
#import "Reachability.h"

#import "KeychainManager.h"

NSInteger sortInPathOrder(NSString *a, NSString *b, void* context) {
    return [a compare:b options:NSNumericSearch | NSCaseInsensitiveSearch];
}

@interface PathControllerManagedObjectContext : NSManagedObjectContext {
	PathController *pathController;
}
@property(nonatomic, assign) PathController *pathController;
@end

@implementation PathController

#pragma mark -
#pragma mark Initialization

+ (void)initialize {
	
#ifdef WRITEROOM
	NSString *CONSUMERKEY = @"NEEDS A DROPBOX API KEY";
	NSString *CONSUMERSECRET = @"NEEDS A DROPBOX API SECRET";
#elif defined(TASKPAPER)
	NSString *CONSUMERKEY = @"NEEDS A DROPBOX API KEY";
	NSString *CONSUMERSECRET = @"NEEDS A DROPBOX API SECRET";
#endif

    DBSession* session = 
    [[DBSession alloc] initWithAppKey:CONSUMERKEY appSecret:CONSUMERSECRET root:kDBRootDropbox];
	[DBSession setSharedSession:session];
    [session release];
    
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithBool:YES], SyncAutomaticallyDefaultsKey,
#ifndef TASKPAPER
                                                             @"txt", TextFileDefaultExtensionDefaultsKey,
															 @"css,ft,html,taskpaper,txt,xml", TextFileExtensionsDefaultsKey,
#else
                                                             @"taskpaper", TextFileDefaultExtensionDefaultsKey,
                                                             @"ft,taskpaper,txt", TextFileExtensionsDefaultsKey,
#endif
															 [@"/" stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]], ServerRootDefaultsKey,
															 nil]];
    
    NSString *serverRoot = [[KeychainManager sharedKeychainManager] valueForKey:ServerRootDefaultsKey];
    if (serverRoot == nil) {
        [[KeychainManager sharedKeychainManager] setValue:[[NSUserDefaults standardUserDefaults] stringForKey:ServerRootDefaultsKey] forKey:ServerRootDefaultsKey];
    } else {
        [[NSUserDefaults standardUserDefaults] setValue:[[KeychainManager sharedKeychainManager] valueForKey:ServerRootDefaultsKey] forKey:ServerRootDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    NSString *fileTypes = [[KeychainManager sharedKeychainManager] valueForKey:TextFileExtensionsDefaultsKey];
    if (fileTypes == nil) {
        [[KeychainManager sharedKeychainManager] setValue:[[NSUserDefaults standardUserDefaults] stringForKey:TextFileExtensionsDefaultsKey] forKey:TextFileExtensionsDefaultsKey];
    } else {
        [[NSUserDefaults standardUserDefaults] setValue:[[KeychainManager sharedKeychainManager] valueForKey:TextFileExtensionsDefaultsKey] forKey:TextFileExtensionsDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

static NSSet *textFileTypes = nil;
static NSString *textFileDefaultType = nil;

+ (NSString *)defaultTextFileType {
    if (!textFileDefaultType) {
        textFileDefaultType = [[[NSUserDefaults standardUserDefaults] stringForKey:TextFileDefaultExtensionDefaultsKey] retain];
    }
    return textFileDefaultType;
}

+ (void)setDefaultTextFileType:(NSString *)newDefaultTextFileType {
    if (![newDefaultTextFileType isEqualToString:textFileDefaultType]) {
        [textFileDefaultType release];
        textFileDefaultType = [newDefaultTextFileType retain];
        [[NSUserDefaults standardUserDefaults] setObject:textFileDefaultType forKey:TextFileDefaultExtensionDefaultsKey];
        if (![textFileTypes containsObject:textFileDefaultType]) {
            NSString *textFileTypesString = [[NSUserDefaults standardUserDefaults] stringForKey:TextFileExtensionsDefaultsKey];
            NSString *newTextFileTypesString = [NSString stringWithFormat:@"%@,%@", textFileTypesString, textFileDefaultType];
            [PathController setTextFileTypes:newTextFileTypesString];
        }
    }
}

+ (NSSet *)textFileTypes {
	if (!textFileTypes) {
		NSString *textFileTypesString = [[NSUserDefaults standardUserDefaults] stringForKey:TextFileExtensionsDefaultsKey];
		textFileTypes = [[NSSet setWithArray:[textFileTypesString componentsSeparatedByString:@","]] retain];
	}
	return textFileTypes;
}

+ (void)setTextFileTypes:(NSString *)extensionsString {
	[textFileTypes autorelease];
	textFileTypes = nil;
	
	NSMutableArray *cleanedExtensions = [NSMutableArray array];
	for (NSString *each in [extensionsString componentsSeparatedByString:@","]) {
		each = [each stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		each = [each lowercaseString];
		if (![cleanedExtensions containsObject:each]) {
			[cleanedExtensions addObject:each];
		}
	}
	
	if (![cleanedExtensions containsObject:[self defaultTextFileType]]) {
		[cleanedExtensions insertObject:[self defaultTextFileType] atIndex:0];
	}
		
	[cleanedExtensions sortUsingSelector:@selector(compare:)];
		
	[[NSUserDefaults standardUserDefaults] setObject:[cleanedExtensions componentsJoinedByString:@","] forKey:TextFileExtensionsDefaultsKey];
	[[KeychainManager sharedKeychainManager] setValue:[[NSUserDefaults standardUserDefaults] stringForKey:TextFileExtensionsDefaultsKey] forKey:TextFileExtensionsDefaultsKey];
}

+ (BOOL)isPermanentPlaceholder:(NSString *)path {
	NSString *pathExtension = [path pathExtension];
	if ([[self textFileTypes] containsObject:[pathExtension lowercaseString]]) {
		return NO;
	}	
	return YES;
}

+ (NSError *)documentsFolderCannotBeRenamedError {
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  NSLocalizedString(@"The Documents folder can't be renamed. You can rename all files and non-synced folders.", nil),
							  NSLocalizedDescriptionKey, nil];
	return [NSError errorWithDomain:@"" code:1 userInfo:userInfo];
}

+ (NSError *)syncedFoldersCannotBeRenamedError {
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  NSLocalizedString(@"Synced folders cannot be renamed from this app. You should rename then on Dropbox.com or with another Dropbox client that supports renaming.", nil),
							  NSLocalizedDescriptionKey, nil];
	return [NSError errorWithDomain:@"" code:1 userInfo:userInfo];
}

#pragma mark -
#pragma mark Init

- (id)init {
	self = [self initWithLocalRoot:nil serverRoot:nil persistentStorePath:nil];
	return self;
}

- (void)initManagedObjectContext {
	NSError *error;
	NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ShadowMetadata" ofType:@"momd"]];
	NSURL *storeURL = [NSURL fileURLWithPath:persistentStorePath];
	managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
		abort();
	}    
	managedObjectContext = [[PathControllerManagedObjectContext alloc] init];
	[managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
	[managedObjectContext setUndoManager:nil];
	managedObjectContext.pathController = self;
		
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShadowMetadata" inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:entity];
	for (ShadowMetadata *each in [managedObjectContext executeFetchRequest:fetchRequest error:NULL]) {
		[normalizedPathsToShadowMetadatas setObject:each forKey:each.normalizedPath];
	}
}

- (id)initWithLocalRoot:(NSString *)aLocalRoot serverRoot:(NSString *)aServerRoot persistentStorePath:(NSString *)aPersistentStorePath {
	self = [super init];	
	autosyncOnLink = YES;
	localPathsToNormalizedPaths = [[NSMutableDictionary alloc] init];
	normalizedPathsToPathActivity = [[NSMutableDictionary alloc] init];
	normalizedPathsToShadowMetadatas = [[NSMutableDictionary alloc] init];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (!aLocalRoot) aLocalRoot = [fileManager documentDirectory];
	BOOL isDirectory;
	NSError *error;
	
	if (![fileManager fileExistsAtPath:aLocalRoot isDirectory:&isDirectory] || !isDirectory) {
		if (![fileManager createDirectoryAtPath:aLocalRoot withIntermediateDirectories:YES attributes:nil error:&error]) {
			LogError(@"Failed to create local directory for %@ %@", self, error);
			[self release];
			return nil;
		}
	}
	
	localRoot = aLocalRoot;
	if (!localRoot) localRoot = [fileManager documentDirectory];
	localRoot = [[localRoot precomposedStringWithCanonicalMapping] retain];
	
	getOperationQueue = [[NSOperationQueue alloc] init];
	getOperationQueue.maxConcurrentOperationCount = 6;
	putOperationQueue = [[NSOperationQueue alloc] init];
	putOperationQueue.maxConcurrentOperationCount = 3;
	deleteOperationQueue = [[NSOperationQueue alloc] init];
	deleteOperationQueue.maxConcurrentOperationCount = 3;
	folderSyncPathOperationOperationQueue = [[NSOperationQueue alloc] init];
	folderSyncPathOperationOperationQueue.maxConcurrentOperationCount = 1;

    
	if (!aServerRoot) aServerRoot = [[KeychainManager sharedKeychainManager] valueForKey:ServerRootDefaultsKey];
	if (!aServerRoot) aServerRoot = @"/";
	self.serverRoot = aServerRoot;

	if (!aPersistentStorePath) aPersistentStorePath = [[[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent:@"ShadowMetadata.sqlite"] retain];
	persistentStorePath = [aPersistentStorePath retain];
	
	dropboxAPIReachability = [[Reachability reachabilityWithHostName:kDBDropboxAPIHost] retain];
	[dropboxAPIReachability startNotifier];
	dropboxAPIContentReachability = [[Reachability reachabilityWithHostName:kDBDropboxAPIContentHost] retain];
	[dropboxAPIContentReachability startNotifier];

	[self initManagedObjectContext];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginingSyncNotification:) name:BeginingFolderSyncNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endingSyncNotification:) name:EndingFolderSyncNotification object:self];
	
	return self;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	LogDebug(@"Dealloc %@", self);
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[DBSession sharedSession].delegate = nil;
	manualLinkClient.delegate = nil;
	[localPathsToNormalizedPaths release];
	[normalizedPathsToPathActivity release];
	[normalizedPathsToShadowMetadatas release];
	[pendingPathChangedNotificationUserInfo release];
	[dropboxAPIReachability stopNotifier];
	[dropboxAPIReachability release];
	[dropboxAPIContentReachability stopNotifier];
	[dropboxAPIContentReachability release];	
	[manualLinkClient release];
	[localRoot release];
	[serverRoot release];
	[persistentStorePath release];
	[getOperationQueue cancelAllOperations];
	[getOperationQueue release];
	[putOperationQueue cancelAllOperations];
	[putOperationQueue release];
	[deleteOperationQueue cancelAllOperations];
	[deleteOperationQueue release];
	[folderSyncPathOperationOperationQueue cancelAllOperations];
	[folderSyncPathOperationOperationQueue release];
 	[managedObjectModel release];
	[managedObjectContext release];
    [persistentStoreCoordinator release];
	[super dealloc];
}

- (void)reachabilityChanged:(NSNotification *)aNotification {
	if (self.isServerReachable) {
		if (self.syncAutomatically) {
			[self enqueueSyncOperationsForVisiblePaths];
		}
	}
}

- (void)beginingSyncNotification:(NSNotification *)aNotification {
	if ([self isFullSyncInProgress]) {
		NSString *folderName = [[[aNotification userInfo] objectForKey:PathKey] lastPathComponent];
		NSString *messageTemplate = NSLocalizedString(@"\"%@\"", nil);
		[fullSyncAlertView setMessage:[NSString stringWithFormat:messageTemplate, folderName]];
	}
}

- (void)endingSyncNotification:(NSNotification *)aNotification {
	UIApplication *application = [UIApplication sharedApplication];
	
	if ([self isFullSyncInProgress]) {
		NSString *path = [[aNotification userInfo] objectForKey:PathKey];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *pathContents = [fileManager contentsOfDirectoryAtPath:path error:nil];
		for (NSString *each in pathContents) {
			NSString *eachPath = [path stringByAppendingPathComponent:each];
			BOOL isDirectory;
			
			if ([fileManager fileExistsAtPath:eachPath isDirectory:&isDirectory] && isDirectory) {
				[self enqueueFolderSyncPathOperationRequest:eachPath];
			}
		}
	}

	if (self.isSyncInProgress) {
		return;
	}

	[fullSyncAlertView dismissWithClickedButtonIndex:0 animated:YES];
	[fullSyncAlertView release];
	fullSyncAlertView = nil;

	[application setNetworkActivityIndicatorVisible:NO];		
}

#pragma mark -
#pragma mark Paths

@synthesize localRoot;
@synthesize serverRoot;

- (void)setServerRoot:(NSString *)aRoot {
	NSAssert(serverRoot == nil || !self.isLinked, @"Shouldn't be linked when changing server root");
	
	aRoot = [aRoot stringByReplacingOccurrencesOfString:@"\\" withString:@""];
	aRoot = [aRoot stringByReplacingOccurrencesOfString:@";" withString:@""];
	aRoot = [@"/" stringByAppendingPathComponent:aRoot];
	
	[serverRoot release];
	serverRoot = [[aRoot precomposedStringWithCanonicalMapping] retain];
}

- (NSString *)openFolderPath {
	NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:OpenDirectoryPathKey];
	if (path) {
		path = [serverRoot stringByAppendingPathComponent:path];
		return [self serverPathToLocal:path];
	}
	return nil;
}

- (void)setOpenFolderPath:(NSString *)aPath {
	if (aPath) {
		aPath = [self localPathToServer:aPath];
		aPath = [aPath stringByReplacingCharactersInRange:NSMakeRange(0, [serverRoot length]) withString:@""];
		[[NSUserDefaults standardUserDefaults] setObject:aPath forKey:OpenDirectoryPathKey];
		if (!IS_IPAD) {
			self.openFilePath = nil;
		}
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:OpenDirectoryPathKey];
	}
}

- (NSString *)openFilePath {
	NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:OpenFilePathKey];
	if (path) {
		path = [serverRoot stringByAppendingPathComponent:path];
		return [self serverPathToLocal:path];
	}
	return nil;
}

- (void)setOpenFilePath:(NSString *)aPath {
	if (aPath) {
		aPath = [self localPathToServer:aPath];
		aPath = [aPath stringByReplacingCharactersInRange:NSMakeRange(0, [serverRoot length]) withString:@""];
		[[NSUserDefaults standardUserDefaults] setObject:aPath forKey:OpenFilePathKey];
		if (!IS_IPAD) {
			self.openFolderPath = nil;
		}
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:OpenFilePathKey];
	}
}

- (NSString *)serverPathToLocal:(NSString *)serverPath {
	serverPath = [serverPath precomposedStringWithCanonicalMapping];
	NSString *s = [serverPath substringFromIndex:[serverRoot length]];
	return [localRoot stringByAppendingPathComponent:s];
}

- (NSString *)localPathToServer:(NSString *)localPath {
	localPath = [localPath precomposedStringWithCanonicalMapping];
	if ([localPath rangeOfString:localRoot].location == 0) {
		NSString *p = [localPath substringFromIndex:[self.localRoot length]];
		return [serverRoot stringByAppendingPathComponent:p];
	}
	return localPath;
}

- (NSString *)localPathToNormalized:(NSString *)localPath {
	NSString *result = [[localPath stringByReplacingCharactersInRange:NSMakeRange(0, [localRoot length]) withString:@""] normalizedDropboxPath];
	if ([result length] == 0) {
		result = @"/";
	}
	return result;
}

#pragma mark -
#pragma mark Path Modifications

- (BOOL)copyItemAtPath:(NSString *)path error:(NSError **)error {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *dstFolderPath = [fileManager tempDirectoryUnusedPath];
	NSString *dstPath = [dstFolderPath stringByAppendingPathComponent:[path lastPathComponent]];
	
	if ([fileManager createDirectoryAtPath:dstFolderPath withIntermediateDirectories:YES attributes:nil error:error]) {
		if ([fileManager copyItemAtPath:path toPath:dstPath error:error]) {
			[[UIPasteboard generalPasteboard] setURL:[NSURL fileURLWithPath:dstPath]];
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error {	
	if ([[NSFileManager defaultManager] removeItemAtPath:path error:error]) {
		if (self.syncAutomatically) {
			[self enqueueFolderSyncPathOperationRequest:[path stringByDeletingLastPathComponent]];
		}
		[self enqueuePathChangedNotification:path changeType:RemovedPathsKey];
		return YES;
	}
	return NO;
}

- (BOOL)removeUnchangedItemsAtPath:(NSString *)aLocalPath error:(NSError **)error removedAll:(BOOL *)removedAll {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL removedAllResult = NO;
	BOOL isDirectory;
	
	if ([fileManager fileExistsAtPath:aLocalPath isDirectory:&isDirectory]) {
		ShadowMetadata *shadowMetadata = [self shadowMetadataForLocalPath:aLocalPath createNewLocalIfNeeded:NO];
		NSDate *lastSyncDate = shadowMetadata.lastSyncDate;
		
		if (isDirectory) {
			if (lastSyncDate) {
				for (NSString *each in [fileManager contentsOfDirectoryAtPath:aLocalPath error:NULL]) {
					[self removeUnchangedItemsAtPath:[aLocalPath stringByAppendingPathComponent:each] error:error removedAll:removedAll];
				}
				
				if ([[fileManager contentsOfDirectoryAtPath:aLocalPath error:NULL] count] == 0) {
					if ([fileManager removeItemAtPath:aLocalPath error:NULL]) {
						[self enqueuePathChangedNotification:aLocalPath changeType:RemovedPathsKey];
						removedAllResult = YES;
					}
				}
			}
		} else {
			PathState pathState = shadowMetadata.pathState;
			NSDate *lastSyncDate = shadowMetadata.lastSyncDate;
			NSDate *localModified = [[fileManager attributesOfItemAtPath:aLocalPath error:error] fileModificationDate];			
			BOOL isPlaceholder = (pathState == TemporaryPlaceholderPathState || pathState == PermanentPlaceholderPathState);
			
			if (isPlaceholder || (lastSyncDate != nil && [localModified isEqualToDate:lastSyncDate])) {
				if ([fileManager removeItemAtPath:aLocalPath error:NULL]) {
					[self enqueuePathChangedNotification:aLocalPath changeType:RemovedPathsKey];
					removedAllResult = YES;
				}
			}
		}
	} else {
		removedAllResult = YES;
	}
	
	if (removedAll) {
		*removedAll = removedAllResult;
	}
		
	return YES;
}

- (BOOL)pasteItemToPath:(NSString *)path error:(NSError **)error {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *srcPath = [[[UIPasteboard generalPasteboard] URL] path];
	NSString *dstPath = [path stringByAppendingPathComponent:[srcPath lastPathComponent]];
	
	dstPath = [fileManager conflictPathForPath:dstPath includeMessage:NO error:error];
	
	if (dstPath) {
		if ([fileManager copyItemAtPath:srcPath toPath:dstPath error:error]) {
			if (self.syncAutomatically) {
				[self enqueueFolderSyncPathOperationRequest:[path stringByDeletingLastPathComponent]];
			}
			[self enqueuePathChangedNotification:path changeType:CreatedPathsKey];
			return YES;
		}
	}
	
	return NO;
}

- (NSString *)createItemAtPath:(NSString *)path folder:(BOOL)folder error:(NSError **)error {
	// commit editing any path name.
	[APP_VIEW_CONTROLLER becomeFirstResponder]; 
	[APP_VIEW_CONTROLLER resignFirstResponder];
	
	// Post early, or else if newly created file is named the same as last name of above renamed file
	// the view will update (based on filemoved notification) and select the above old file instead of
	// this new file.
	[self postQueuedPathChangedNotifications];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *result = nil;
	
	if (!path) {
		path = [self openFolderPath];
		if (!path) {
			path = [fileManager documentDirectory];
		}
		if (folder) {
			path = [path stringByAppendingPathComponent:NSLocalizedString(@"Untitled Folder", nil)];
		} else {
			path = [path stringByAppendingPathComponent:[NSLocalizedString(@"Untitled", nil) stringByAppendingPathExtension:[PathController defaultTextFileType]]];
		}
		
		path = [fileManager conflictPathForPath:path includeMessage:NO error:error];
	}
	
	if (path) {
		if (folder) {
			if ([fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:error]) {
				result = path;
			}
		} else {
			if ([@"" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:error]) {
				result = path;
			}
		}
	}
	
	if (result) {
		[self enqueuePathChangedNotification:path changeType:CreatedPathsKey];
		return result;
	} else {
		return nil;
	}	
}

- (BOOL)moveItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error {
	if ([fromPath isEqualToString:localRoot] || [toPath isEqualToString:localRoot]) {
		if (*error) {
			*error = [PathController documentsFolderCannotBeRenamedError];
		}
		return NO;
	}
	
	ShadowMetadata *sourceMetadata = [self shadowMetadataForLocalPath:fromPath createNewLocalIfNeeded:NO];
	if (sourceMetadata.lastSyncIsDirectory && sourceMetadata.lastSyncHash != nil) {
		if (*error) {
			*error = [PathController syncedFoldersCannotBeRenamedError];
		}
		return NO;
	}
	
	NSString *fromParent = [fromPath stringByDeletingLastPathComponent];
	NSString *toParent = [toPath stringByDeletingLastPathComponent];
	NSMutableSet *syncPaths = [NSMutableSet setWithObjects:fromParent, toParent, nil];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager my_moveItemAtPath:fromPath toPath:toPath error:error]) {
		[self enqueuePathChangedNotification:[NSDictionary dictionaryWithObjectsAndKeys:fromPath, FromPathKey, toPath, ToPathKey, nil] changeType:MovedPathsKey];
		for (NSString *each in syncPaths) {
			if (self.syncAutomatically) {
				[self enqueueFolderSyncPathOperationRequest:each];
			}
		}

		if ([self.openFolderPath isEqualToString:fromPath]) {
			self.openFolderPath = toPath;
		}
		
		if ([self.openFilePath isEqualToString:fromPath]) {
			self.openFilePath = toPath;
		}
				
		return YES;
	}
	
	return NO;
}

- (void)postQueuedPathChangedNotifications {
	[[NSNotificationCenter defaultCenter] postNotificationName:PathsChangedNotification object:self userInfo:pendingPathChangedNotificationUserInfo];
	[pendingPathChangedNotificationUserInfo autorelease];
	pendingPathChangedNotificationUserInfo = nil;
}


- (void)enqueuePathChangedNotification:(id)value changeType:(NSString *)changeTypeKey {
	if ([value isKindOfClass:[NSDictionary class]]) {
		NSAssert([changeTypeKey isEqualToString:MovedPathsKey], @"%@", self);
	}
	
	if (!pendingPathChangedNotificationUserInfo) {
		pendingPathChangedNotificationUserInfo = [[NSMutableDictionary alloc] init];
		[self performSelector:@selector(postQueuedPathChangedNotifications) withObject:nil afterDelay:0.0];
	}
	
	NSMutableSet *values = [pendingPathChangedNotificationUserInfo objectForKey:changeTypeKey];
	if (!values) {
		values = [NSMutableSet set];
		[pendingPathChangedNotificationUserInfo setObject:values forKey:changeTypeKey];
	}
	
	[values addObject:value];
}

#pragma mark -
#pragma mark Path Syncing

- (BOOL)saveState {
	NSError *error;
	if (![managedObjectContext save:&error]) {
		LogError(@"Failed to save managed object context %@", error);
		return NO;
	}
	return YES;
}

- (BOOL)isSyncInProgress {
	for (NSOperation *each in [folderSyncPathOperationOperationQueue operations]) {
		if (!each.isFinished) {
			return YES;
		}
	}
	return NO;
}

- (PathState)stateForPath:(NSString *)localPath {
	ShadowMetadata *shadowMetadata = [self shadowMetadataForLocalPath:localPath createNewLocalIfNeeded:NO];
	if (shadowMetadata) {
		return shadowMetadata.pathState;
	}
	return UnsyncedPathState;
}

- (NSError *)errorForPath:(NSString *)localPath {
	return [self shadowMetadataForLocalPath:localPath createNewLocalIfNeeded:NO].pathError;
}

- (PathActivity)pathActivityForPath:(NSString *)localPath {
	NSString *normalizedPath = [self localPathToNormalized:localPath];
	NSNumber *pathActivity = [normalizedPathsToPathActivity objectForKey:normalizedPath];
	if (!pathActivity) {
		pathActivity = [NSNumber numberWithInt:NoPathActivity];
		[normalizedPathsToPathActivity setObject:pathActivity forKey:normalizedPath];
	}
	return [pathActivity intValue];
}

- (void)setPathActivity:(PathActivity)aPathActivity forPath:(NSString *)aLocalPath {
	NSString *normalizedPath = [self localPathToNormalized:aLocalPath];
	[normalizedPathsToPathActivity setObject:[NSNumber numberWithInt:aPathActivity] forKey:normalizedPath];
	[self enqueuePathChangedNotification:aLocalPath changeType:ActivityChangedPathsKey];
}

- (void)enqueueSyncOperationsForVisiblePaths {
	NSString *path1 = self.openFolderPath;
	NSString *path2 = [self.openFilePath stringByDeletingLastPathComponent];
	
	if (path1) {
		[self enqueueFolderSyncPathOperationRequest:path1];
	}
	
	if (path2 != nil && ![path1 isEqualToString:path2]) {
		[self enqueueFolderSyncPathOperationRequest:path2];
	}
}

- (void)enqueueFolderSyncPathOperationRequest:(NSString *)localPath {
	NSAssert(localPath != nil, @"%@", self);
		
	if (self.isLinked && self.isServerReachable) {
		localPath = [localPath precomposedStringWithCanonicalMapping];
		
		for (PathOperation *each in [folderSyncPathOperationOperationQueue operations]) {
			if ([each.localPath isEqualToString:localPath]) {
				return;
			}
		}
	
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		[folderSyncPathOperationOperationQueue addOperation:[[[FolderSyncPathOperation alloc] initWithPath:localPath pathController:self] autorelease]];
	}
}

- (void)cancelSync {
	//[getOperationQueue cancelAllOperations];
	//[putOperationQueue cancelAllOperations];
	//[deleteOperationQueue cancelAllOperations];
	[folderSyncPathOperationOperationQueue cancelAllOperations];
	//[self performSelector:@selector(cancelTest) withObject:nil afterDelay:0.1];
}

#pragma mark -
#pragma mark Full Sync

- (void)beginFullSync {
	NSString *errorTitle = nil;
	NSString *errorMessage = nil;
	if (!self.isLinked) {
		errorTitle = NSLocalizedString(@"Dropbox isn't linked", nil);
		errorMessage = NSLocalizedString(@"To sync you must first link to Dropbox in %@'s settings.", nil);
		errorMessage = [NSString stringWithFormat:errorMessage, [[NSProcessInfo processInfo] processName]];
	} else if (!self.isServerReachable) {
		errorTitle = NSLocalizedString(@"Dropbox is unreachable", nil);
		errorMessage = NSLocalizedString(@"To sync you must first have network access to Dropbox.com.", nil);
	} else {
		[self enqueueFolderSyncPathOperationRequest:self.localRoot];
		fullSyncAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Syncing All Folders...", nil) message:@"\n" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:nil];
		[fullSyncAlertView show];
		return;
	}

	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:errorTitle message:errorMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

- (BOOL)isFullSyncInProgress {
	return fullSyncAlertView != nil;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	[self cancelSync];
}

#pragma mark -
#pragma mark Linking

- (BOOL)isLinked {
	return [[DBSession sharedSession] isLinked];
}

- (BOOL)isServerReachable {
	return [dropboxAPIReachability isReachable] && [dropboxAPIContentReachability isReachable];
}

@synthesize autosyncOnLink;

- (BOOL)syncAutomatically {
    return [[NSUserDefaults standardUserDefaults] boolForKey:SyncAutomaticallyDefaultsKey];
}

- (void)setSyncAutomatically:(BOOL)aBool {
	[[NSUserDefaults standardUserDefaults] setBool:aBool forKey:SyncAutomaticallyDefaultsKey];
}

- (void)unlink:(BOOL)discardSessionKeys {
	NSError *error;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *contents = [fileManager contentsOfDirectoryAtPath:localRoot error:&error];
	BOOL removedAll;

	[getOperationQueue cancelAllOperations];
	[putOperationQueue cancelAllOperations];
	[deleteOperationQueue cancelAllOperations];
	[folderSyncPathOperationOperationQueue cancelAllOperations];
	
	for (NSString *each in contents) {
		each = [localRoot stringByAppendingPathComponent:each];	
		[self removeUnchangedItemsAtPath:each error:NULL removedAll:&removedAll];
		[self deleteShadowMetadataForLocalPath:each];
	}	
	
	NSMutableSet *persistentStorePaths = [NSMutableSet set];
	for (NSPersistentStore *each in [persistentStoreCoordinator persistentStores]) {
		[persistentStorePaths addObject:[[persistentStoreCoordinator URLForPersistentStore:each] path]];
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:managedObjectContext];
	
	[managedObjectContext release];
	managedObjectContext = nil;
	[persistentStoreCoordinator release];
	persistentStoreCoordinator = nil;
	[managedObjectModel release];
	managedObjectModel = nil;

	[normalizedPathsToPathActivity removeAllObjects];
	[localPathsToNormalizedPaths removeAllObjects];
	[normalizedPathsToShadowMetadatas removeAllObjects];

	for (NSString *each in persistentStorePaths) {
		[fileManager removeItemAtPath:each error:NULL];
	}

	if (discardSessionKeys) {
		[[DBSession sharedSession] unlinkAll];
	}

	self.openFilePath = nil;
	self.openFolderPath = nil;
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[self initManagedObjectContext];
}

#pragma mark -
#pragma mark Path Metadata

- (ShadowMetadata *)shadowMetadataForLocalPath:(NSString *)localPath createNewLocalIfNeeded:(BOOL)createIfNeeded {
	NSString *normalizedPath = [self localPathToNormalized:localPath];
	ShadowMetadata *shadowMetadata = [normalizedPathsToShadowMetadatas objectForKey:normalizedPath];
	
	if (!shadowMetadata && createIfNeeded) {
		NSString *normalizedName = [normalizedPath lastPathComponent];
		shadowMetadata = [ShadowMetadata shadowMetadataWithNormalizedName:normalizedName managedObjectContext:managedObjectContext];
		
		if (![normalizedName isEqualToString:@"/"]) {
			ShadowMetadata *parent = [self shadowMetadataForLocalPath:[localPath stringByDeletingLastPathComponent] createNewLocalIfNeeded:YES];
			[parent addChildrenObject:shadowMetadata];
		}
		
		[normalizedPathsToShadowMetadatas setObject:shadowMetadata forKey:normalizedPath];
	}
	
	return shadowMetadata;
}

- (void)uncacheShadowMetadata:(ShadowMetadata *)aShadowMetadata {	
	for (ShadowMetadata *each in aShadowMetadata.children) {
		[self uncacheShadowMetadata:each];
	}
	[normalizedPathsToShadowMetadatas removeObjectForKey:aShadowMetadata.normalizedPath];
}

- (void)deleteShadowMetadataForLocalPath:(NSString *)localPath {
	ShadowMetadata *shadowMetadata = [self shadowMetadataForLocalPath:localPath createNewLocalIfNeeded:NO];
	if (shadowMetadata) {
		[self uncacheShadowMetadata:shadowMetadata];
		[managedObjectContext deleteObject:shadowMetadata];
	}
	
	// localPathsToNormalizedPaths; // not getting cleaned out
	// localPathsToPathActivity
}

- (void)loginSuccess {
	[[NSNotificationCenter defaultCenter] postNotificationName:PathControllerLinkedNotification object:self];
	NSString *currentFolder = self.openFolderPath;
	if (!currentFolder) currentFolder = self.localRoot;
	if (self.autosyncOnLink) {
		[self enqueueFolderSyncPathOperationRequest:currentFolder];
	}
}

- (void)loginFailed {
	[getOperationQueue cancelAllOperations];
	[putOperationQueue cancelAllOperations];
	[deleteOperationQueue cancelAllOperations];
	[[NSNotificationCenter defaultCenter] postNotificationName:PathControllerLinkFailedNotification object:self];
}

@end

@implementation PathControllerManagedObjectContext
@synthesize pathController;
@end

NSString *TextFileDefaultExtensionDefaultsKey = @"TextFileDefaultExtensionDefaultsKey";
NSString *TextFileExtensionsDefaultsKey = @"TextFileExtensionsDefaultsKey";
NSString *ServerRootDefaultsKey = @"ServerRootDefaultsKey";
NSString *SyncAutomaticallyDefaultsKey = @"SyncAutomaticallyDefaultsKey";
NSString *OpenFilePathKey = @"OpenFilePathKey";
NSString *OpenDirectoryPathKey = @"OpenDirectoryPathKey";
NSString *PathControllerLinkedNotification = @"PathControllerLinkedNotification";
NSString *PathControllerLinkFailedNotification = @"PathControllerLinkFailedNotification";
NSString *BeginingFolderSyncNotification = @"BeginingFolderSyncNotification";
NSString *EndingFolderSyncNotification = @"EndingFolderSyncNotification";

NSString *PathsChangedNotification = @"PathsChangedNotification";
NSString *MovedPathsKey = @"MovedPathsKey";
NSString *CreatedPathsKey = @"CreatedPathsKey";
NSString *RemovedPathsKey = @"RemovedPathsKey";
NSString *ModifiedPathsKey = @"ModifiedPathsKey";
NSString *StateChangedPathsKey = @"StateChangedPathsKey";
NSString *ActivityChangedPathsKey = @"ActivityChangedPathsKey";
NSString *PathKey = @"PathKey";
NSString *FromPathKey = @"FromPathKey";
NSString *ToPathKey = @"ToPathKey";