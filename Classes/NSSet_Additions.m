//
//  NSSet_Additions.m
//  PlainText
//
//  Created by Jesse Grosjean on 6/9/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "NSSet_Additions.h"
#import <DropboxSDK/DropboxSDK.h>


@implementation NSSet (Additions)

- (NSMutableSet *)setMinusSet:(NSSet *)aSet {
	NSMutableSet *result = [[self mutableCopy] autorelease];
	[result minusSet:aSet];
	return result;
}

- (NSMutableSet *)setIntersectingSet:(NSSet *)aSet {
	NSMutableSet *result = [[self mutableCopy] autorelease];
	[result intersectSet:aSet];
	return result;
}

- (NSMutableSet *)setFilteredUsingPredicate:(NSPredicate *)aPredicate {
	NSMutableSet *result = [[self mutableCopy] autorelease];
	[result filterUsingPredicate:aPredicate];
	return result;
}

- (NSString *)conflictNameForNameInNormalizedSet:(NSString *)name {
	return [self conflictNameForNameInNormalizedSet:name includeMessage:YES];
}

- (NSString *)conflictNameForNameInNormalizedSet:(NSString *)name includeMessage:(BOOL)includeMessage {
	NSString *base = [name stringByDeletingPathExtension];
	NSString *extension = [name pathExtension];
	
	if (includeMessage) {
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateFormat:@"yyyy-MM-dd"];
		base = [base stringByAppendingFormat:@" (%@'s conflicted copy %@)", [[UIDevice currentDevice] name], [dateFormatter stringFromDate:[NSDate date]], nil]; // use dropbox style
	}
	
	if ([extension length] > 0) {
		name = [base stringByAppendingPathExtension:extension];
	}
	
	NSUInteger count = 1;
	while ([self containsObject:[name normalizedDropboxPath]]) {
		name = [base stringByAppendingFormat:@" %i", count++];
		if ([extension length] > 0) {
			name = [name stringByAppendingPathExtension:extension];				
		}
	}
	
	return name;
}

@end
