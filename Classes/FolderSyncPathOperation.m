//
//  LoadMetadataSyncPathOperation.m
//  SyncTest
//
//  Created by Jesse Grosjean on 8/7/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "FolderSyncPathOperation.h"
#import "DeleteLocalPathOperation.h"
#import "FolderSyncPathOperation.h"
#import "ApplicationController.h"
#import "DeletePathOperation.h"
#import "GetPathOperation.h"
#import "PutPathOperation.h"
#import "NSSet_Additions.h"
#import "PathController.h"
#import <DropboxSDK/DropboxSDK.h>
#include <sys/stat.h>
#include <dirent.h>

@interface PathController (FolderSyncPathOperationPrivate)
- (NSOperationQueue *)getOperationQueue;
- (NSOperationQueue *)putOperationQueue;
- (NSOperationQueue *)deleteOperationQueue;
- (NSOperationQueue *)folderSyncPathOperationOperationQueue;
@end

@implementation FolderSyncPathOperation

- (id)initWithPath:(NSString *)aLocalPath pathController:(PathController *)aPathController {
	self = [super initWithPath:aLocalPath serverMetadata:nil];
	self.pathController = aPathController;
	pathOperations = [[NSMutableSet alloc] init];
	return self;
}

- (void)dealloc {
	[pathOperations release];
	[childSyncError release];
	[super dealloc];
}

- (BOOL)validateLocalPath {
	if ([pathController.localRoot isEqualToString:localPath]) {
		return YES; // Folder sync path operation is the only operation allowed on local root.
	} else {
		return [super validateLocalPath];
	}
}

@synthesize needsCleanupSync;

- (void)main {
	if (!pathController.isServerReachable) {
		[self finish:[NSError errorWithDomain:NSURLErrorKey code:NSURLErrorNetworkConnectionLost userInfo:nil]];
		return;
	}
	
	[self updatePathActivity:GetPathActivity];
	[self.client loadMetadata:[pathController localPathToServer:localPath] withHash:[self shadowMetadata:NO].lastSyncHash];
}

- (void)start {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
	
	[[NSNotificationCenter defaultCenter] postNotificationName:BeginingFolderSyncNotification object:pathController userInfo:[NSDictionary dictionaryWithObject:localPath forKey:PathKey]];
	
	[super start];
}

- (void)cancel {
	if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(cancel) withObject:nil waitUntilDone:NO];
        return;
    }

	[[[pathOperations copy] autorelease] makeObjectsPerformSelector:@selector(cancel)];
	needsCleanupSync = NO;
	updatedLastSyncHashOnFinish = NO;
	
	if (!loadedMetadata) {
		[super cancel];
	}
}

- (void)finish:(NSError *)error {
	[super finish:error];
	[[NSNotificationCenter defaultCenter] postNotificationName:EndingFolderSyncNotification object:pathController userInfo:[NSDictionary dictionaryWithObject:localPath forKey:PathKey]];
}

- (void)finishIfSyncOperationsAreFinished {
	if ([pathOperations count] == 0 && !schedulingOperations) {
		if (needsCleanupSync) {
			[childSyncError release];
			childSyncError = nil;
			needsCleanupSync = NO;
			[self main];
			return;
		}
		[self finish:childSyncError];
	}
}

#pragma mark -
#pragma mark Folder Sync

- (FolderSyncPathOperation *)folderSyncPathOperation {
	[NSException raise:@"Method should not be called on FolderSyncPathOperation object" format:@" ", nil];
	return nil;
}

- (void)schedulePathOperation:(PathOperation *)aPathOperation onQueue:(NSOperationQueue *)operationQueue {
	aPathOperation.pathController = pathController;
	aPathOperation.folderSyncPathOperation = self;
	[pathOperations addObject:aPathOperation];
	[operationQueue addOperation:aPathOperation];
}

- (void)pathOperationFinished:(PathOperation *)aPathOperation {
	if (aPathOperation == self) return;
	
	NSAssert([pathOperations containsObject:aPathOperation], @"");
	[[self retain] autorelease]; // keep self alive incase aPathOperation.folderSyncPathOperation = nil is last reference to self.
	ShadowMetadata *finishedShadowMetadata = [aPathOperation shadowMetadata:NO];
	
	if (childSyncError == nil && (finishedShadowMetadata.pathState == SyncErrorPathState && finishedShadowMetadata.pathError != nil)) {
		childSyncError = [finishedShadowMetadata.pathError retain];
	}
	aPathOperation.folderSyncPathOperation = nil;
	aPathOperation.pathController = nil;
	[pathOperations removeObject:aPathOperation];
	[self finishIfSyncOperationsAreFinished];
}

- (void)createFolderOnServer {
	[self.client createFolder:[pathController localPathToServer:localPath]];
}


- (void)scheduleFolderSyncOperations {
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSFileManager *fileManager = [NSFileManager defaultManager];
    
	// Restrict file syncing to specific text file types
	NSSet *textFileTypes = [PathController textFileTypes];

	// Map shadow names & attributes
	NSMutableSet *shadowNames = [NSMutableSet set];
	NSMutableDictionary *nameToShadowMetadataLookup = [NSMutableDictionary dictionary];
	for (ShadowMetadata *each in [pathController shadowMetadataForLocalPath:localPath createNewLocalIfNeeded:NO].children) {
		[nameToShadowMetadataLookup setObject:each forKey:each.normalizedName];
		
		if (each.lastSyncDate != nil) {
			[shadowNames addObject:each.normalizedName];
		} else if (each.pathState == SyncErrorPathState) {
			[shadowNames addObject:each.normalizedName];
		}
	}
	
	// Map local names and look for local changes.
	NSMutableDictionary *nameToLocalPathLookup = [NSMutableDictionary dictionary];
	NSMutableDictionary *nameToCaseSensitiveNameLookup = [NSMutableDictionary dictionary];
	NSMutableSet *localTypeChanges = [NSMutableSet set];
	NSMutableSet *localModifieds = [NSMutableSet set];
	NSMutableSet *localNames = [NSMutableSet set];
	
	const char *localPathFileSystemRepresentation = [localPath fileSystemRepresentation];
	char pathBuffer[strlen(localPathFileSystemRepresentation) + FILENAME_MAX + 1];
	DIR *dip = opendir(localPathFileSystemRepresentation);
	struct stat fileInfo;
	struct dirent *dit;	
	
	if (dip != NULL) {
		while ((dit = readdir(dip)) != NULL) {
			if (0 == strcmp(".", dit->d_name) || 0 == strcmp("..", dit->d_name))
				continue;
			
			BOOL localIsDirectory = dit->d_type == DT_DIR;
			NSString *each = [[fileManager stringWithFileSystemRepresentation:dit->d_name length:dit->d_namlen] precomposedStringWithCanonicalMapping];
			
			if (localIsDirectory || [textFileTypes containsObject:[[each pathExtension] lowercaseString]]) {
				NSString *eachPath = [localPath stringByAppendingPathComponent:each];
				NSString *eachNormalizedName = [each lowercaseString];
				
				[nameToCaseSensitiveNameLookup setObject:each forKey:eachNormalizedName];
				[nameToLocalPathLookup setObject:eachPath forKey:eachNormalizedName];
				[localNames addObject:eachNormalizedName];		
				
				ShadowMetadata *eachLocalMetadata = [nameToShadowMetadataLookup objectForKey:eachNormalizedName];
				
				if (eachLocalMetadata) {
					if (eachLocalMetadata.lastSyncIsDirectory != localIsDirectory) {
						[localTypeChanges addObject:each];
					}
					
					if (!localIsDirectory) {
						memset(pathBuffer, '\0', sizeof(pathBuffer));
						strcpy(pathBuffer, localPathFileSystemRepresentation);
						strcat(pathBuffer, "/");
						strcat(pathBuffer, (char*)dit->d_name);
						
						if (0 == lstat(pathBuffer, &fileInfo)) {
							if (eachLocalMetadata) {
								PathState eachPathState = eachLocalMetadata.pathState; 
								if (eachPathState != PermanentPlaceholderPathState && 
									eachPathState != TemporaryPlaceholderPathState &&
									!(eachLocalMetadata.lastSyncDate == nil && eachPathState == SyncErrorPathState)) {
									if ([eachLocalMetadata.lastSyncDate timeIntervalSince1970] != fileInfo.st_mtime) {
										[localModifieds addObject:eachNormalizedName];
									}
								}
							}			
						}
					}
				}
			}
		}
		
		closedir(dip);
	}

	// Map server names & attributes
	NSMutableDictionary *nameToDBMetadataLookup = [NSMutableDictionary dictionary];
	NSMutableSet *serverNames = [NSMutableSet set];
	if (serverMetadata) {
		for (DBMetadata *each in serverMetadata.contents) {
			NSString *normalizedName = each.path.lastPathComponent.normalizedDropboxPath;
			if ([each isDirectory] || [textFileTypes containsObject:[normalizedName pathExtension]]) {
				[nameToDBMetadataLookup setObject:each forKey:normalizedName];
				[serverNames addObject:normalizedName];
			}
		}
	} else {
		[serverNames unionSet:shadowNames];
	}
	
	// Detect and propogate case changes in names
	for (NSString *each in shadowNames) {
		NSString *eachLocalName = [nameToCaseSensitiveNameLookup objectForKey:each];
		NSString *eachShadowName = [[nameToShadowMetadataLookup objectForKey:each] lastSyncName];
		NSString *eachServerName = [[[nameToDBMetadataLookup objectForKey:each] path] lastPathComponent];
		
		if (eachLocalName != nil && eachShadowName != nil && eachServerName != nil) {
			if (![eachLocalName isEqualToString:eachServerName]) {
				if (![eachServerName isEqualToString:eachShadowName]) {
					LogInfo(@"#### Should rename local from: %@ to: %@", eachLocalName, eachServerName, nil);
					// server changed, update local.
				} else {
					LogInfo(@"#### Should rename server from: %@ to: %@", eachServerName, eachLocalName, nil);
					// local changed, update server.
				}
			}
		}
	}	
	
	// Determine adds, deletes
	NSMutableSet *localAdds = [localNames setMinusSet:shadowNames];
	NSMutableSet *deletedLocal = [shadowNames setMinusSet:localNames];
	NSMutableSet *serverAdds = [serverNames setMinusSet:shadowNames];
	NSMutableSet *deletedServer = [shadowNames setMinusSet:serverNames];
	
	// Determine server modifieds and server type changes
	NSMutableSet *serverModifieds = [NSMutableSet set];
	NSMutableSet *serverTypeChanges = [NSMutableSet set];
	for (NSString *each in serverNames) {
		ShadowMetadata *eachShadowMetadata = [nameToShadowMetadataLookup objectForKey:each];
		DBMetadata *eachServerMetadata = [nameToDBMetadataLookup objectForKey:each];
		if (eachShadowMetadata != nil && eachServerMetadata != nil) {
			if (eachShadowMetadata.pathState != PermanentPlaceholderPathState) {
				if (eachShadowMetadata.lastSyncDate == nil && eachShadowMetadata.pathState == SyncErrorPathState) {
                    eachShadowMetadata.clientMTime = eachServerMetadata.clientMtime;
					[serverModifieds addObject:each];
				} else {
                    eachShadowMetadata.clientMTime = eachServerMetadata.clientMtime;
					NSDate *serverModified = eachServerMetadata.lastModifiedDate;
					NSDate *lastSyncDate = eachShadowMetadata.lastSyncDate;
					if (![serverModified isEqualToDate:lastSyncDate]) {
						[serverModifieds addObject:each];
					}
					
					BOOL serverIsDirectory = eachServerMetadata.isDirectory;
					if (serverIsDirectory != eachShadowMetadata.lastSyncIsDirectory) {
						[serverTypeChanges addObject:each];
					}
				}
			}
		}
	}
	
	// Addjust adds and deletes for type changes (if path type changes then delete it and re-add it to resolve)
	[deletedLocal unionSet:localTypeChanges];
	[localAdds unionSet:localTypeChanges];
	[deletedServer unionSet:serverTypeChanges];
	[serverAdds unionSet:serverTypeChanges];
	
	// Resolve conflicting adds (same new filename added to both local and server
	NSMutableSet *conflictAdds = [serverAdds setIntersectingSet:localAdds];
	NSMutableSet *usedNames = [NSMutableSet set];
	[usedNames unionSet:localNames];
	[usedNames unionSet:localAdds];
	[usedNames unionSet:serverAdds];
    

	for (NSString *each in conflictAdds) {
		NSString *fromPath = [nameToLocalPathLookup objectForKey:each];
		NSString *conflictName = [[usedNames conflictNameForNameInNormalizedSet:[fromPath lastPathComponent]] precomposedStringWithCanonicalMapping];
		NSString *toPath = [[fromPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:conflictName];
		NSError *error;
		
		if ([fileManager moveItemAtPath:fromPath toPath:toPath error:&error]) {
			NSString *normalizedConflictName = [conflictName normalizedDropboxPath];
			// create path metadata?
			[localAdds removeObject:each];
			[usedNames addObject:conflictName];
			[localAdds addObject:normalizedConflictName];
			[nameToLocalPathLookup setObject:toPath forKey:normalizedConflictName];
			[pathController enqueuePathChangedNotification:[NSDictionary dictionaryWithObjectsAndKeys:fromPath, FromPathKey, toPath, ToPathKey, nil] changeType:MovedPathsKey];
		} else {
			LogError(@"Failed to move conflicting local add %@", error);
		}
	}
    
    void (^aLogBlock)(void) = ^(void) {
        NSLog(@"shadowNames:%@", shadowNames);
        NSLog(@"nameToShadowMetadataLookup:%@", nameToShadowMetadataLookup);
        NSLog(@"nameToLocalPathLookup:%@", nameToLocalPathLookup);
        NSLog(@"[nameToDBMetadataLookup:%@", nameToDBMetadataLookup);
        NSLog(@"serverNames:%@", serverNames);
        NSLog(@"localAdds:%@", localAdds);
        NSLog(@"deletedLocal:%@", deletedLocal);
        NSLog(@"serverAdds:%@", serverAdds);
        NSLog(@"conflictAdds:%@", conflictAdds);
        NSLog(@"deletedServer:%@", deletedServer);
        NSLog(@"---------------------------------\n\n");
    };
	
	schedulingOperations = YES;
	
	// Schedule Local Delete Operations
	for (NSString *each in [[deletedServer allObjects] sortedArrayUsingFunction:sortInPathOrder context:NULL]) {
		if ([deletedLocal containsObject:each]) {
			[pathController deleteShadowMetadataForLocalPath:[nameToLocalPathLookup objectForKey:each]];
		} else {
            NSString *path = [nameToLocalPathLookup objectForKey:each];
            if (!path) {
                aLogBlock();
            }
			[self schedulePathOperation:[DeleteLocalPathOperation pathOperationWithPath:[nameToLocalPathLookup objectForKey:each] serverMetadata:[nameToDBMetadataLookup objectForKey:each]] onQueue:[pathController deleteOperationQueue]];
		}
	}
	
	// Schedule Server Delete Operations
	for (NSString *each in [[deletedLocal allObjects] sortedArrayUsingFunction:sortInPathOrder context:NULL]) {
		if ([deletedServer containsObject:each]) {
			[pathController deleteShadowMetadataForLocalPath:[nameToLocalPathLookup objectForKey:each]];
		} else {
			[self schedulePathOperation:[DeletePathOperation pathOperationWithPath:[localPath stringByAppendingPathComponent:each] serverMetadata:[nameToDBMetadataLookup objectForKey:each]] onQueue:[pathController deleteOperationQueue]];
		}
	}
	
	// Schedule Get Operations
	NSMutableSet *gets = [NSMutableSet set];
	[gets unionSet:serverAdds];
	[gets unionSet:serverModifieds];
	for (NSString *each in [[gets allObjects] sortedArrayUsingFunction:sortInPathOrder context:NULL]) {
		NSString *eachPath = [nameToLocalPathLookup objectForKey:each];
		DBMetadata *eachServerMetadata = [nameToDBMetadataLookup objectForKey:each];
		BOOL pathNeedsGet = YES;
        
		if (!eachPath) {
			eachPath = [localPath stringByAppendingPathComponent:[eachServerMetadata.path lastPathComponent]];
			
			// expirment
			
			ShadowMetadata *shadowMetadata = [pathController shadowMetadataForLocalPath:eachPath createNewLocalIfNeeded:YES];
			NSError *error = nil;
			
			if (eachServerMetadata.isDirectory) {
				if ([fileManager createDirectoryAtPath:eachPath withIntermediateDirectories:YES attributes:[NSDictionary dictionaryWithObject:eachServerMetadata.lastModifiedDate forKey:NSFileModificationDate] error:&error]) {
					[pathController enqueuePathChangedNotification:eachPath changeType:CreatedPathsKey];
					shadowMetadata.pathState = SyncedPathState;
					shadowMetadata.lastSyncDate = eachServerMetadata.lastModifiedDate;
					shadowMetadata.lastSyncIsDirectory = eachServerMetadata.isDirectory;
				} else {
					shadowMetadata.pathError = error;
					shadowMetadata.pathState = SyncErrorPathState;
					[pathController enqueuePathChangedNotification:eachPath changeType:StateChangedPathsKey];
					LogError(@"Should never get to this error %@", error);
				}
				pathNeedsGet = NO;
			} else {
				if (![fileManager fileExistsAtPath:eachPath]) {
					if ([fileManager createDirectoryAtPath:[eachPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:[NSDictionary dictionaryWithObject:eachServerMetadata.lastModifiedDate forKey:NSFileModificationDate] error:&error]) {
						if ([fileManager createFileAtPath:eachPath contents:nil attributes:[NSDictionary dictionaryWithObject:eachServerMetadata.lastModifiedDate forKey:NSFileModificationDate]]) {
							[pathController enqueuePathChangedNotification:eachPath changeType:CreatedPathsKey];
							shadowMetadata.lastSyncIsDirectory = eachServerMetadata.isDirectory;
							if ([PathController isPermanentPlaceholder:eachPath]) {
								shadowMetadata.lastSyncDate = eachServerMetadata.lastModifiedDate;
								shadowMetadata.pathState = PermanentPlaceholderPathState;
								[pathController enqueuePathChangedNotification:eachPath changeType:StateChangedPathsKey];
								pathNeedsGet = NO;
							} else {
								shadowMetadata.pathState = TemporaryPlaceholderPathState;
							}
						} else {
							shadowMetadata.pathError = error;
							shadowMetadata.pathState = SyncErrorPathState;
							[pathController enqueuePathChangedNotification:eachPath changeType:StateChangedPathsKey];
							pathNeedsGet = NO;
							LogError(@"Should never get to this error %@", error);
						}
					}
				}
			}	
		}
		
		if (pathNeedsGet) {
			[self schedulePathOperation:[GetPathOperation pathOperationWithPath:eachPath serverMetadata:eachServerMetadata] onQueue:[pathController getOperationQueue]];
		}
	}
	
	[pathController saveState];
	
	// Schedule Put Operations
	NSMutableSet *puts = [NSMutableSet set];
	[puts unionSet:localAdds];
	[puts unionSet:localModifieds];
	for (NSString *each in [[puts allObjects] sortedArrayUsingFunction:sortInPathOrder context:NULL]) {
		NSString *eachPath = [nameToLocalPathLookup objectForKey:each];
		DBMetadata *eachServerMetadata = [nameToDBMetadataLookup objectForKey:each];
        if (!eachPath) {
            aLogBlock();
        }
        eachServerMetadata = nil;
		[self schedulePathOperation:[PutPathOperation pathOperationWithPath:eachPath serverMetadata:eachServerMetadata] onQueue:[pathController putOperationQueue]];
	}
	
	schedulingOperations = NO;
	
	[self finishIfSyncOperationsAreFinished];
}

#pragma mark -
#pragma mark DBRestClientDelegate

- (void)restClient:(DBRestClient*)aClient loadedMetadata:(DBMetadata*)aServerMetadata {	
	loadedMetadata = YES;
	
	self.serverMetadata = aServerMetadata;
	
	if (serverMetadata.isDeleted) { // has existed, and is now delted on server
		NSError *error;
		BOOL removedAll;
		
		if ([pathController removeUnchangedItemsAtPath:localPath error:&error removedAll:&removedAll]) {
			[pathController deleteShadowMetadataForLocalPath:localPath];
			[pathController saveState];
			
			if (removedAll) {
				if ([localPath isEqualToString:pathController.localRoot]) {
					if (![[NSFileManager defaultManager] createDirectoryAtPath:localPath withIntermediateDirectories:YES attributes:nil error:&error]) {
						[self finish:error];
						return;
					}
				}
				self.createShadowMetadataOnFinish = NO;
				[self finish];
			} else {
				[self createFolderOnServer];
			}
		} else {
			[self finish:error];
		}
	} else {
		[self scheduleFolderSyncOperations];
	}
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path {	
	loadedMetadata = YES;

	LogInfo(@"Metadata Unchanged %@", [pathController localPathToServer:localPath]);
	self.serverMetadata = nil;
	[self scheduleFolderSyncOperations];
}

- (void)restClient:(DBRestClient*)aClient loadMetadataFailedWithError:(NSError*)error {
	loadedMetadata = YES;
	
	if ([error code] == 404) { // has never existed on server.
		[self createFolderOnServer];
		return;
	}
	[self retryWithError:error];
}

- (void)restClient:(DBRestClient*)aClient createdFolder:(DBMetadata *)aServerMetadata {
	self.serverMetadata = aServerMetadata;
	[self scheduleFolderSyncOperations];
}

- (void)restClient:(DBRestClient*)aClient createFolderFailedWithError:(NSError*)error {
	[self retrySelector:@selector(createFolderOnServer) withError:error];
}

@end

@implementation PathController (FolderSyncPathOperationPrivate)

- (NSOperationQueue *)getOperationQueue {
	return getOperationQueue;
}

- (NSOperationQueue *)putOperationQueue {
	return putOperationQueue;
}

- (NSOperationQueue *)deleteOperationQueue {
	return deleteOperationQueue;
}

- (NSOperationQueue *)folderSyncPathOperationOperationQueue {
	return folderSyncPathOperationOperationQueue;
}

@end