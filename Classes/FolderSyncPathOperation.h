//
//  LoadMetadataSyncPathOperation.h
//  SyncTest
//
//  Created by Jesse Grosjean on 8/7/10.
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