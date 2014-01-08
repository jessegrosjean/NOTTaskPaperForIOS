//
//  SyncPathOperation.h
//  SyncTest
//
//  Created by Jesse Grosjean on 8/7/10.
//

#import <DropboxSDK/DropboxSDK.h>
#import "ShadowMetadata.h"


@class FolderSyncPathOperation;

@interface PathOperation : NSOperation <DBRestClientDelegate> {
	BOOL isExecuting;
	BOOL isFinished;
	BOOL updatedLastSyncHashOnFinish;
	BOOL createShadowMetadataOnFinish;
    BOOL isOperationStarted;
	PathState successPathState;
	DBRestClient *client;
	NSString *localPath;
	DBMetadata *serverMetadata;
	NSUInteger retriesRemaining;
	PathController *pathController;
	FolderSyncPathOperation *folderSyncPathOperation;
}

+ (void)clearShouldFailPaths;
+ (void)addShouldFailPath:(NSString *)aServerPath;
+ (void)removeShouldFailPath:(NSString *)aServerPath;
+ (PathOperation *)pathOperationWithPath:(NSString *)aLocalPath serverMetadata:(DBMetadata *)aServerMetadata;

- (id)initWithPath:(NSString *)aLocalPath serverMetadata:(DBMetadata *)aServerMetadata;

@property (nonatomic, assign, getter=isOperationStarted) BOOL operationStarted;
@property (nonatomic, readonly) BOOL isExecuting;
@property (nonatomic, readonly) BOOL isFinished;
@property (nonatomic, readonly) NSString *localPath;
@property (nonatomic, assign) BOOL createShadowMetadataOnFinish;;
@property (nonatomic, assign) PathState successPathState;
@property (nonatomic, readonly) DBRestClient *client;
@property (nonatomic, retain) DBMetadata *serverMetadata;
@property (nonatomic, retain) PathController *pathController;
@property (nonatomic, retain) FolderSyncPathOperation *folderSyncPathOperation;

- (ShadowMetadata *)shadowMetadata:(BOOL)createIfNeccessary;
- (void)updatePathActivity:(PathActivity)pathActivity;
- (BOOL)validateLocalPath;
- (void)deleteLocalPath;

- (void)finish;
- (void)retryWithError:(NSError *)error;
- (void)retrySelector:(SEL)aSelector withError:(NSError *)error;
- (void)finish:(NSError *)error;
@end
