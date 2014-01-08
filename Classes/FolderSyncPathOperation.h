//
//  LoadMetadataSyncPathOperation.h
//  SyncTest
//
//  Created by Jesse Grosjean on 8/7/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "PathOperation.h"


@interface FolderSyncPathOperation : PathOperation {
	BOOL loadedMetadata;
	BOOL needsCleanupSync;
	BOOL schedulingOperations;
	NSError *childSyncError;
	NSMutableSet *pathOperations;
}

- (id)initWithPath:(NSString *)aLocalPath pathController:(PathController *)aPathController;

@property (nonatomic, assign) BOOL needsCleanupSync;

- (void)pathOperationFinished:(PathOperation *)aPathOperation;

@end