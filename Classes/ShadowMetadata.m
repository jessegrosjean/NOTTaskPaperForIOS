//
//  ShadowMetadata.m
//  SyncTest
//
//  Created by Jesse Grosjean on 8/7/10.
//

#import "ShadowMetadata.h"
#import "ApplicationViewController.h"
#import "ShadowMetadataTextBlob.h"
#import "PathController.h"
#import "PathOperation.h"


@interface PathController (ShadowMetadataPrivate)
- (void)setShadowMetadata:(ShadowMetadata *)aShadowMetadata forNormalizedPath:(NSString *)aNormalizedPath;
@end

@implementation ShadowMetadata

+ (ShadowMetadata *)shadowMetadataWithNormalizedName:(NSString *)aNormalizedName managedObjectContext:(NSManagedObjectContext *)aManagedObjectContext {
	ShadowMetadata *shadowMetadata = [NSEntityDescription insertNewObjectForEntityForName:@"ShadowMetadata" inManagedObjectContext:aManagedObjectContext]; 
	[shadowMetadata setPrimitiveValue:aNormalizedName forKey:@"normalizedName"];
	return shadowMetadata;
}

#pragma mark -
#pragma mark Dealloc

- (void)didTurnIntoFault {
	[pathError release];
	[normalizedPath release];
	[super didTurnIntoFault];
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	[self setPrimitiveValue:[NSEntityDescription insertNewObjectForEntityForName:@"ShadowMetadataTextBlob" inManagedObjectContext:self.managedObjectContext] forKey:@"lastSyncText"];
}

- (void)awakeFromFetch {
	[super awakeFromFetch];
	[self.pathController setShadowMetadata:self forNormalizedPath:self.normalizedPath];
}

- (BOOL)isRoot {
	return self.parent == nil;
}

@dynamic normalizedName;

- (NSString *)normalizedPath {
	if (!normalizedPath) {
		NSString *aPath = nil;
		if (self.parent) {
			aPath = [self.parent.normalizedPath stringByAppendingPathComponent:self.normalizedName];
			//normalizedPath = [[self.parent.normalizedPath stringByAppendingPathComponent:self.normalizedName] retain];
		} else {
			aPath = [@"/" stringByAppendingPathComponent:self.normalizedName];
			//normalizedPath = [[@"/" stringByAppendingPathComponent:self.normalizedName] retain];
		}
		[normalizedPath release];
		normalizedPath = [aPath retain];
	}
	return normalizedPath;
}

- (PathController *)pathController {
	return [(PathControllerManagedObjectContext *)self.managedObjectContext pathController];
}

@synthesize pathError;

- (void)setPathError:(NSError *)anError {
	[pathError autorelease];
	pathError = [anError retain];
}

#pragma mark -
#pragma mark Children

@dynamic parent;
@dynamic children;

- (NSSet* )allDescendantsWithSelf {
	NSMutableSet *results = [NSMutableSet set];
	for (ShadowMetadata *each in self.children) {
		[results unionSet:each.allDescendantsWithSelf];
	}
	[results addObject:self];
	return results;
}

#pragma mark -
#pragma mark Last Sync Metadata

- (PathState)pathState {
	[self willAccessValueForKey:@"pathState"];
	BOOL result = pathState;
	[self didAccessValueForKey:@"pathState"];
	return result;
}

- (void)setPathState:(PathState)newState {
	[self willChangeValueForKey:@"pathState"];
	if (pathState != newState) {
		pathState = newState;
	}
	[self didChangeValueForKey:@"pathState"];
}

@dynamic lastSyncName;
@dynamic lastSyncDate;

- (void)setLastSyncDate:(NSDate *)aDate {
	if (self.lastSyncDate) {
		NSAssert(aDate != nil, @"shouldn't set last sync date to nil if it's already been set.");
	}
	[self willChangeValueForKey:@"lastSyncDate"];
	[self setPrimitiveValue:aDate forKey:@"lastSyncDate"];
	[self didChangeValueForKey:@"lastSyncDate"];	
}

@dynamic lastSyncHash;
@dynamic lastSyncIsDirectory;

- (BOOL)lastSyncIsDirectory {
	[self willAccessValueForKey:@"lastSyncIsDirectory"];
	BOOL result = lastSyncIsDirectory;
	[self didAccessValueForKey:@"lastSyncIsDirectory"];
	return result;
}

- (void)setLastSyncIsDirectory:(BOOL)aBool {
	[self willChangeValueForKey:@"lastSyncIsDirectory"];
	lastSyncIsDirectory = aBool;
	[self didChangeValueForKey:@"lastSyncIsDirectory"];	
}

@dynamic lastSyncText;
@dynamic clientMTime;

@end

@implementation PathController (ShadowMetadataPrivate)

- (void)setShadowMetadata:(ShadowMetadata *)aShadowMetadata forNormalizedPath:(NSString *)aNormalizedPath {
	[normalizedPathsToShadowMetadatas setObject:aShadowMetadata forKey:aNormalizedPath];
}

@end
