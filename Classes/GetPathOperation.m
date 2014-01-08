//
//  GetPathOperation.m
//  SyncTest
//
//  Created by Jesse Grosjean on 8/10/10.
//

#import "GetPathOperation.h"
#import "NSFileManager_Additions.h"
#import "DeleteLocalPathOperation.h"
#import "FolderSyncPathOperation.h"
#import "ShadowMetadataTextBlob.h"
#import "ApplicationController.h"
#import "NSString_Additions.h"
#import "PutPathOperation.h"
#import "PathController.h"
#import "DiffMatchPatch.h"
#import "ShadowMetadata.h"


@implementation GetPathOperation

- (void)removeTempDownloadPath {
	if (tempDownloadPath) {
		[[NSFileManager defaultManager] removeItemAtPath:tempDownloadPath error:NULL];
		[tempDownloadPath release];
		tempDownloadPath = nil;
	}
}

- (void)dealloc {
	[self removeTempDownloadPath];
	[super dealloc];
}

- (void)main {
	NSAssert(serverMetadata != nil, @"%@", self);
	
	if (!pathController.isServerReachable) {
		[self finish:[NSError errorWithDomain:NSURLErrorKey code:NSURLErrorNetworkConnectionLost userInfo:nil]];
		return;
	}
	
	[self updatePathActivity:GetPathActivity];
	tempDownloadPath = [[[NSFileManager defaultManager] tempDirectoryUnusedPath] retain];
	NSString *serverPath = [pathController localPathToServer:localPath];
	[self.client loadFile:serverPath intoPath:tempDownloadPath];
}

- (void)retryWithError:(NSError *)error {
	[self removeTempDownloadPath];
	[super retryWithError:error];
}

#pragma mark -
#pragma mark DBRestClientDelegate

- (void)restClient:(DBRestClient*)aClient loadedFile:(NSString*)destPath {
	NSAssert([destPath isEqual:tempDownloadPath], @"%@", self);
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObject:serverMetadata.lastModifiedDate forKey:NSFileModificationDate];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;

	if (![fileManager setAttributes:attributes ofItemAtPath:tempDownloadPath error:&error]) {
		[self finish:error];
		return;
	}

	BOOL localExists = [fileManager fileExistsAtPath:localPath];

	if (localExists) {
		DiffMatchPatch *dmp = [[[DiffMatchPatch alloc] init] autorelease];
		ShadowMetadata *shadowMetadata = [self shadowMetadata:NO];
		NSString *shadowContent = shadowMetadata.lastSyncText.text;
		NSString *serverContent = [NSString myStringWithContentsOfFile:tempDownloadPath usedEncoding:NULL error:NULL];
		NSString *localContent = [NSString myStringWithContentsOfFile:localPath usedEncoding:NULL error:NULL];
		//NSString *serverContent = [NSString stringWithContentsOfFile:tempDownloadPath encoding:NSUTF8StringEncoding error:NULL];
		//NSString *localContent = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:NULL];
		
		if (shadowContent != nil && serverContent != nil && localContent != nil) {
			//NSMutableArray *localChanges = [dmp patchMakeText1:shadowContent text2:localContent];
			NSMutableArray *localChanges = [dmp patch_makeFromOldString:shadowContent andNewString:localContent];
			NSString *newLocalContent = nil;

			if ([localChanges count] > 0) {
				NSArray *patchResults = [dmp patch_apply:localChanges toString:serverContent];
				//NSArray *patchResults = [dmp patchApply:localChanges text:serverContent];
				NSString *patchResultsText = [patchResults objectAtIndex:0];
				BOOL patchApplied = YES;
				
				for (NSNumber *each in [patchResults objectAtIndex:1]) {
					if (![each boolValue]) {
						patchApplied = NO;
					}
				}

				newLocalContent = patchResultsText;

				if (!patchApplied) {
					NSString *conflictPath = [fileManager conflictPathForPath:localPath error:&error];
					
					if (!conflictPath) {
						[self finish:error];
						return;
					} else {
						if ([localContent writeToFile:conflictPath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
							[pathController enqueuePathChangedNotification:conflictPath changeType:CreatedPathsKey];
						} else {
							[self finish:error];
							return;
						}
					}
				}
			} else {
				newLocalContent = serverContent;
			}			
			
			if (![localContent isEqualToString:newLocalContent]) {
				if ([newLocalContent writeToFile:tempDownloadPath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
					self.folderSyncPathOperation.needsCleanupSync = YES;
				} else {
					[self finish:error];
					return;
				}
			}
		}
		
		[fileManager removeItemAtPath:localPath error:NULL];
	} else {
		if (![fileManager createDirectoryAtPath:[localPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error]) {
			[self finish:error];
			return;
		}
	}
	
	if ([fileManager copyItemAtPath:tempDownloadPath toPath:localPath error:&error]) {
		if (localExists) {
			[pathController enqueuePathChangedNotification:localPath changeType:ModifiedPathsKey];
		} else {
			[pathController enqueuePathChangedNotification:localPath changeType:CreatedPathsKey];
		}
		
		//[self shadowMetadata:YES].lastSyncText.text = [NSString stringWithContentsOfFile:tempDownloadPath encoding:NSUTF8StringEncoding error:NULL];
		[self shadowMetadata:YES].lastSyncText.text = [NSString myStringWithContentsOfFile:tempDownloadPath usedEncoding:NULL error:NULL];
		[self finish];
	} else {
		[self finish:error];
	}
}

- (void)restClient:(DBRestClient*)aClient loadFileFailedWithError:(NSError*)error {
	if (error.code == 404) {
		[self deleteLocalPath];
	} else {
		[self retryWithError:error];
	}
}

@end
