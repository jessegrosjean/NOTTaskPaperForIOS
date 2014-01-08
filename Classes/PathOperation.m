//
//  SyncPathOperation.m
//  SyncTest
//
//  Created by Jesse Grosjean on 8/7/10.
//

#import "PathOperation.h"
#import "ShadowMetadataTextBlob.h"
#import "FolderSyncPathOperation.h"
#import "ApplicationController.h"
#import "PathController.h"
#import "ShadowMetadata.h"

#define RETRY_COUNT 3

@implementation PathOperation
@synthesize operationStarted;

static NSMutableSet *shouldFailPathsForUnitTesting = nil;

+ (void)clearShouldFailPaths {
	[shouldFailPathsForUnitTesting removeAllObjects];
}

+ (void)addShouldFailPath:(NSString *)aServerPath {
	if (!shouldFailPathsForUnitTesting) {
		shouldFailPathsForUnitTesting = [[NSMutableSet alloc] init];
	}
	[shouldFailPathsForUnitTesting addObject:aServerPath];
}

+ (void)removeShouldFailPath:(NSString *)aServerPath {
	[shouldFailPathsForUnitTesting removeObject:aServerPath];
}

+ (PathOperation *)pathOperationWithPath:(NSString *)aLocalPath serverMetadata:(DBMetadata *)aServerMetadata {
	return [[[[self class] alloc] initWithPath:aLocalPath serverMetadata:aServerMetadata] autorelease];
}

- (id)initWithPath:(NSString *)aLocalPath serverMetadata:(DBMetadata *)aServerMetadata {
	self = [super init];
	successPathState = SyncedPathState;
	localPath = [aLocalPath retain];
	serverMetadata = [aServerMetadata retain];
	retriesRemaining = RETRY_COUNT;
	createShadowMetadataOnFinish = YES;
	updatedLastSyncHashOnFinish = YES;
	NSAssert(localPath != nil, @"%@", self);
	return self;
}

- (void)dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[pathController release];
	[folderSyncPathOperation release];
	[localPath release];
	[serverMetadata release];
	client.delegate = nil;
	[client release];
	[super dealloc];
}

- (NSString *)description {
	return [[super description] stringByAppendingFormat:@" %@", [pathController localPathToNormalized:localPath]];
}

- (BOOL)isConcurrent {
    return YES;
}

@synthesize isExecuting;
@synthesize isFinished;
@synthesize localPath;
@synthesize createShadowMetadataOnFinish;
@synthesize successPathState;
@synthesize client;

- (DBRestClient *)client {
	if (!client) {
		client = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
		client.delegate = self;
	}
	return client;
}

@synthesize serverMetadata;
@synthesize pathController;

- (void)setPathController:(PathController *)aPathController {
	[pathController autorelease];
	pathController = [aPathController retain];
	
	if (pathController != nil && ![self validateLocalPath]) {
		// Disconnect from path controller so no dammage can be done.
		[pathController autorelease];
		pathController = nil;
	}
}

@synthesize folderSyncPathOperation;

- (void)start {
    [self setOperationStarted:YES];
    
	if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
		
	if (self.isCancelled) {
		[self finish];
	} else {
		[self willChangeValueForKey:@"isExecuting"];
		isExecuting = YES;
		[self didChangeValueForKey:@"isExecuting"];
		LogInfo(@"Executing %@", self);
		
		if ([shouldFailPathsForUnitTesting containsObject:[pathController localPathToServer:localPath]]) {
			[self performSelector:@selector(finish:) withObject:[NSError errorWithDomain:@"unittesting" code:0 userInfo:nil] afterDelay:0.5];
		} else {
			[self main];
		}
	}
}

- (void)cancel {
	if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(cancel) withObject:nil waitUntilDone:NO];
        return;
    }
	
	if (self.isExecuting) {
		return;
	} else if ([pathController stateForPath:localPath] == TemporaryPlaceholderPathState) {
		[[NSFileManager defaultManager] removeItemAtPath:localPath error:NULL];
	}
	
	[super cancel];
	[client cancelAllRequests];
	LogInfo(@"Canceled %@", self);	
	[self finish];
}

- (ShadowMetadata *)shadowMetadata:(BOOL)createIfNeccessary {
	return [pathController shadowMetadataForLocalPath:localPath createNewLocalIfNeeded:createIfNeccessary];
}

- (void)updatePathActivity:(PathActivity)pathActivity {
	[pathController setPathActivity:pathActivity forPath:localPath];
}

- (BOOL)validateLocalPath {
	NSString *localRoot = pathController.localRoot;
	
	NSAssert(localRoot != nil, @"Path Controller local root is nil %@", pathController);
	
	if ([localRoot rangeOfString:localPath].location == 0 || [localPath rangeOfString:localRoot].location != 0) {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Path validate failed, please report this problem to Hog Bay Software.", nil), NSLocalizedDescriptionKey, nil];
		[self finish:[NSError errorWithDomain:@"DeletePathOperation" code:1 userInfo:userInfo]];
		LogError(@"PathOperation created with invalid local path %@", self);
		return NO;
	} else {
		return YES;
	}
}

- (void)deleteLocalPath {
	BOOL removedAll;
	NSError *error = nil;
	
	if (![pathController removeUnchangedItemsAtPath:localPath error:&error removedAll:&removedAll]) {
		[self finish:error];
	} else {
		[pathController deleteShadowMetadataForLocalPath:localPath];
		self.createShadowMetadataOnFinish = NO;
		if (!removedAll) {
			self.folderSyncPathOperation.needsCleanupSync = YES;
		}		
		[self finish];
	}
}

- (void)finish {
	[self finish:nil];
}

- (void)retryWithError:(NSError *)error {
	[self retrySelector:@selector(main) withError:error];
}

- (void)retrySelector:(SEL)aSelector withError:(NSError *)error {
	if (retriesRemaining > 0) {
		retriesRemaining--;
		LogInfo(@"Retry #%i %@", RETRY_COUNT - retriesRemaining, self);
		NSTimeInterval delay = (RETRY_COUNT - retriesRemaining) * 0.5;
		[self performSelector:aSelector withObject:nil afterDelay:delay];
	} else {
		[self finish:error];
	}
}

- (void)updatedShadowMetadata:(NSError *)error {
	ShadowMetadata *shadowMetadata = [self shadowMetadata:createShadowMetadataOnFinish];	
	
	if (error) {
		if (!shadowMetadata.isDeleted) {
			shadowMetadata.pathError = error;
			shadowMetadata.pathState = SyncErrorPathState;
		}
		[pathController enqueuePathChangedNotification:localPath changeType:StateChangedPathsKey];
		LogError(@"Finishing With Error %@ %@", self, error);
	} else {
		if (!shadowMetadata.isDeleted) {
			if (serverMetadata) {
				shadowMetadata.lastSyncName = [localPath lastPathComponent];
				if (updatedLastSyncHashOnFinish) {
					if (![shadowMetadata.lastSyncHash isEqualToString:serverMetadata.hash]) {
						shadowMetadata.lastSyncHash = serverMetadata.hash;
					}
				}
                shadowMetadata.clientMTime = serverMetadata.clientMtime;
				shadowMetadata.lastSyncDate = serverMetadata.lastModifiedDate;
				shadowMetadata.lastSyncIsDirectory = serverMetadata.isDirectory;
			}
			shadowMetadata.pathState = successPathState;
			shadowMetadata.pathError = nil;
			[pathController enqueuePathChangedNotification:localPath changeType:StateChangedPathsKey];
		}
		LogInfo(@"Finishing %@", self);
	}
	
	[pathController saveState];
}

- (void)finish:(NSError *)error {
    if (![self isOperationStarted]) {
        return;
    }
    
	LogDebug(@"Finish 1");
	client.delegate = nil;
	[client autorelease];
	client = nil;

	LogDebug(@"Finish 2");
	if (!self.isCancelled) {
		LogDebug(@"Finish 3");
		[self updatedShadowMetadata:error];
	}

	LogDebug(@"Finish 4");
	[self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    isExecuting = NO;
    isFinished = YES;
	LogDebug(@"Finish 5");
	[self updatePathActivity:NoPathActivity];
	LogDebug(@"Finish 6");
	[folderSyncPathOperation pathOperationFinished:self];
	LogDebug(@"Finish 7");
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end
