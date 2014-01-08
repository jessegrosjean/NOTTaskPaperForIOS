//
//  PutPathOperation.m
//  SyncTest
//
//  Created by Jesse Grosjean on 8/10/10.
//

#import "PutPathOperation.h"
#import "NSFileManager_Additions.h"
#import "ShadowMetadataTextBlob.h"
#import "FolderSyncPathOperation.h"
#import "ApplicationController.h"
#import "PathController.h"
#import "ShadowMetadata.h"


@implementation PutPathOperation

- (void)removeTempUploadPath {
	if (tempUploadPath) {
		[[NSFileManager defaultManager] removeItemAtPath:tempUploadPath error:NULL];
		[tempUploadPath release];
		tempUploadPath = nil;
	}
}

- (void)dealloc {
	[self removeTempUploadPath];
	[super dealloc];
}

- (void)main {
	if (!pathController.isServerReachable) {
		[self finish:[NSError errorWithDomain:NSURLErrorKey code:NSURLErrorNetworkConnectionLost userInfo:nil]];
		return;
	}
	
	NSString *serverPath = [pathController localPathToServer:localPath];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error;

	BOOL isDirectory;
	if ([fileManager fileExistsAtPath:localPath isDirectory:&isDirectory]) {
		if (isDirectory) {
			[self updatePathActivity:PutPathActivity];
			[self.client createFolder:serverPath];
		} else {
			tempUploadPath = [[fileManager tempDirectoryUnusedPath] retain];
			if ([fileManager copyItemAtPath:localPath toPath:tempUploadPath error:&error]) {
				[self updatePathActivity:PutPathActivity];
                [self.client uploadFile:[serverPath lastPathComponent] toPath:[serverPath stringByDeletingLastPathComponent] fromPath:tempUploadPath];
			} else {
				[self finish:error];
			}
		}
	} else {
		[self finish];
	}
}

- (void)retryWithError:(NSError *)error {
	[self removeTempUploadPath];
	[super retryWithError:error];
}

#pragma mark -
#pragma mark DBRestClientDelegate

- (void)restClient:(DBRestClient*)aClient createdFolder:(DBMetadata *)aServerMetadata {
	self.serverMetadata = aServerMetadata;
	[self finish];
}

- (void)restClient:(DBRestClient*)aClient createFolderFailedWithError:(NSError*)error {
	[self retryWithError:error];
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
	ShadowMetadata *shadowMetadata = [self shadowMetadata:YES];
	
	shadowMetadata.pathState = SyncedPathState;
	[pathController enqueuePathChangedNotification:localPath changeType:StateChangedPathsKey];
	shadowMetadata.lastSyncIsDirectory = NO;
	shadowMetadata.lastSyncName = [localPath lastPathComponent];
	shadowMetadata.lastSyncDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:srcPath error:NULL] fileModificationDate];
	shadowMetadata.lastSyncText.text = [NSString stringWithContentsOfFile:srcPath encoding:NSUTF8StringEncoding error:NULL];
	[shadowMetadata.managedObjectContext save:NULL];

	[self.client loadMetadata:[pathController localPathToServer:localPath]];
}

- (void)restClient:(DBRestClient*)aClient uploadFileFailedWithError:(NSError*)error {
	[self retryWithError:error];
}
	
#pragma mark -
#pragma mark DBRestClientDelegate

- (void)restClient:(DBRestClient*)aClient loadedMetadata:(DBMetadata*)aServerMetadata {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	ShadowMetadata *shadowMetadata = [self shadowMetadata:NO];

	self.serverMetadata = aServerMetadata;

	if (shadowMetadata != nil && !shadowMetadata.isDeleted && [fileManager fileExistsAtPath:localPath]) {
		NSDate *lastSyncDate = shadowMetadata.lastSyncDate;
		NSDate *currentDate = [[fileManager attributesOfItemAtPath:localPath error:NULL] fileModificationDate];
		
		if ([lastSyncDate isEqualToDate:currentDate]) {
			[fileManager setAttributes:[NSDictionary dictionaryWithObject:serverMetadata.lastModifiedDate forKey:NSFileModificationDate] ofItemAtPath:localPath error:NULL];
			[pathController enqueuePathChangedNotification:localPath changeType:ModifiedPathsKey];
		}
	}
	
	[self finish];
}

- (void)restClient:(DBRestClient*)aClient loadMetadataFailedWithError:(NSError*)error {
	[self finish:error];
}

@end
