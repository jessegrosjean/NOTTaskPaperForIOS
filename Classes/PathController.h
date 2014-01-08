//
//  PathController.h
//  SyncTest
//
//  Created by Jesse Grosjean on 8/7/10.
//

#import <CoreData/CoreData.h>
#import <DropboxSDK/DropboxSDK.h>

enum {
	UnsyncedPathState = 1,
	SyncedPathState,
	SyncErrorPathState,
	TemporaryPlaceholderPathState,
	PermanentPlaceholderPathState
};
typedef NSUInteger PathState;

enum {
	NoPathActivity,
	RefreshPathActivity,
	GetPathActivity,
	PutPathActivity
};
typedef NSUInteger PathActivity;

@class Reachability;
@class ShadowMetadata;
@class PathControllerManagedObjectContext;

NSInteger sortInPathOrder(NSString *a, NSString *b, void* context);

@interface PathController : NSObject <DBRestClientDelegate, UIAlertViewDelegate> {
	NSString *localRoot;
	NSString *serverRoot;
	NSString *persistentStorePath;
	NSMutableDictionary *localPathsToNormalizedPaths;
	NSMutableDictionary *normalizedPathsToPathActivity;
	NSMutableDictionary *normalizedPathsToShadowMetadatas;
	NSMutableDictionary *pendingPathChangedNotificationUserInfo;
	NSOperationQueue *getOperationQueue;
	NSOperationQueue *putOperationQueue;
	NSOperationQueue *deleteOperationQueue;
	NSOperationQueue *folderSyncPathOperationOperationQueue;
	DBRestClient *manualLinkClient;
	BOOL autosyncOnLink;
	Reachability *dropboxAPIReachability;
	Reachability *dropboxAPIContentReachability;	
    NSManagedObjectModel *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    PathControllerManagedObjectContext *managedObjectContext;
	UIAlertView *fullSyncAlertView;
}

+ (NSString *)defaultTextFileType;
+ (void)setDefaultTextFileType:(NSString *)newDefaultTextFileType;
+ (NSSet *)textFileTypes;
+ (void)setTextFileTypes:(NSString *)aString;
+ (BOOL)isPermanentPlaceholder:(NSString *)path;
+ (NSError *)documentsFolderCannotBeRenamedError;

#pragma mark -
#pragma mark Init

- (id)init;
- (id)initWithLocalRoot:(NSString *)aLocalRoot serverRoot:(NSString *)aServerRoot persistentStorePath:(NSString *)aPersistentStorePath;

#pragma mark -
#pragma mark Paths

@property(nonatomic, readonly) NSString *localRoot;
@property(nonatomic, retain) NSString *serverRoot;
@property (nonatomic, retain) NSString *openFolderPath;
@property (nonatomic, retain) NSString *openFilePath;

- (NSString *)serverPathToLocal:(NSString *)serverPath;
- (NSString *)localPathToServer:(NSString *)localPath;	
- (NSString *)localPathToNormalized:(NSString *)localPath;

#pragma mark -
#pragma mark Path Modifications

- (BOOL)copyItemAtPath:(NSString *)path error:(NSError **)error;
- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error;
- (BOOL)removeUnchangedItemsAtPath:(NSString *)aLocalPath error:(NSError **)error removedAll:(BOOL *)removedAll;
- (BOOL)pasteItemToPath:(NSString *)path error:(NSError **)error;
- (NSString *)createItemAtPath:(NSString *)path folder:(BOOL)folder error:(NSError **)error;
- (BOOL)moveItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error;
- (void)enqueuePathChangedNotification:(id)value changeType:(NSString *)changeTypeKey;
- (void)postQueuedPathChangedNotifications;

#pragma mark -
#pragma mark Path Syncing

- (BOOL)saveState;
- (BOOL)isSyncInProgress;
- (PathState)stateForPath:(NSString *)localPath;
- (NSError *)errorForPath:(NSString *)localPath;
- (PathActivity)pathActivityForPath:(NSString *)localPath;
- (void)enqueueSyncOperationsForVisiblePaths;
- (void)enqueueFolderSyncPathOperationRequest:(NSString *)localPath;
- (void)cancelSync;

#pragma mark -
#pragma mark Full Sync

- (void)beginFullSync;
- (BOOL)isFullSyncInProgress;

#pragma mark -
#pragma mark Linking

@property(nonatomic, readonly) BOOL isLinked;
@property(nonatomic, readonly) BOOL isServerReachable;
@property(nonatomic, assign) BOOL autosyncOnLink;
@property(nonatomic, assign) BOOL syncAutomatically;
- (void)unlink:(BOOL)discardSessionKeys;

- (ShadowMetadata *)shadowMetadataForLocalPath:(NSString *)localPath createNewLocalIfNeeded:(BOOL)createIfNeeded;


@end

@interface PathController (PrivateInternal)
- (void)setPathActivity:(PathActivity)aPathActivity forPath:(NSString *)aLocalPath;
- (void)deleteShadowMetadataForLocalPath:(NSString *)localPath;
@end

extern NSString *TextFileDefaultExtensionDefaultsKey;
extern NSString *TextFileExtensionsDefaultsKey;
extern NSString *SyncAutomaticallyDefaultsKey;
extern NSString *OpenFilePathKey;
extern NSString *OpenDirectoryPathKey;
extern NSString *ServerRootDefaultsKey;
extern NSString *BeginingFolderSyncNotification;
extern NSString *EndingFolderSyncNotification;
extern NSString *PathControllerLinkedNotification;
extern NSString *PathControllerLinkFailedNotification;

// Path notifications
extern NSString *PathsChangedNotification;
extern NSString *MovedPathsKey;
extern NSString *CreatedPathsKey;
extern NSString *ModifiedPathsKey;
extern NSString *RemovedPathsKey;
extern NSString *StateChangedPathsKey;
extern NSString *ActivityChangedPathsKey;

// Path notification userInfo keys
extern NSString *PathKey;
extern NSString *FromPathKey;
extern NSString *ToPathKey;
