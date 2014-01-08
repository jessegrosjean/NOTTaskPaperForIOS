//
//  ShadowMetadata.h
//  SyncTest
//
//  Created by Jesse Grosjean on 8/7/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "PathController.h"

@class ShadowMetadataTextBlob;
@class PathController;
@class PathOperation;
@class ShadowMetadata;


@interface ShadowMetadata : NSManagedObject {
	PathState pathState;
	BOOL lastSyncIsDirectory;
	NSError *pathError;
	NSString *normalizedPath;
}

+ (ShadowMetadata *)shadowMetadataWithNormalizedName:(NSString *)aNormalizedName managedObjectContext:(NSManagedObjectContext *)aManagedObjectContext;

@property(nonatomic, readonly) BOOL isRoot;
@property(nonatomic, readonly) NSString *normalizedName;
@property(nonatomic, readonly) NSString *normalizedPath; // transient
@property(nonatomic, readonly) PathController *pathController; // transient
@property(nonatomic, retain) NSError *pathError; // transient

#pragma mark -
#pragma mark Children

@property(nonatomic, readonly) ShadowMetadata* parent;
@property(nonatomic, retain) NSSet* children;
@property(nonatomic, readonly) NSSet* allDescendantsWithSelf;

#pragma mark -
#pragma mark Last Sync Metadata

@property(nonatomic, assign) PathState pathState;
@property(nonatomic, retain) NSString *lastSyncName;
@property(nonatomic, retain) NSDate *lastSyncDate;
@property(nonatomic, retain) NSString *lastSyncHash;
@property(nonatomic, assign) BOOL lastSyncIsDirectory;
@property(nonatomic, retain) NSDate *clientMTime;
@property(nonatomic, retain) ShadowMetadataTextBlob *lastSyncText;

@end

@interface NSManagedObject (Children)
- (void)addChildrenObject:(ShadowMetadata *)aChild;
- (void)removeChildrenObject:(ShadowMetadata *)aChild;
@end