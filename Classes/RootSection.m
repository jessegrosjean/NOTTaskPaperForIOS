//
//  RootSection.m
//  Documents
//
//  Created by Jesse Grosjean on 6/3/09.
//  Copyright 2009 Hog Bay Software. All rights reserved.
//

#import "RootSection.h"
#import "Tree.h"


@interface Section (RootSectionPrivate)
- (void)setParent:(Section *)newParent;
- (void)setPreviousSibling:(Section *)section;
- (void)setNextSibling:(Section *)section;
- (void)setTree:(Tree *)newTree;
- (void)fixTreeParentFromSection:(Section *)possibleParent;
@end

@interface Tree (RootSectionPrivate)
- (void)setSection:(Section *)aSection forID:(NSString *)uniqueID;
- (void)removeSectionForID:(NSString *)uniqueID;
@end

@implementation RootSection

+ (void)parent:(Section *)newParent removeChild:(Section *)aChild {
	Section *oldParent = aChild->parent;
	
	oldParent->countOfChildren--;
	
	aChild.previousSibling.nextSibling = aChild.nextSibling;
	aChild.nextSibling.previousSibling = aChild.previousSibling;
	
	if (aChild == oldParent->firstChild) {
		oldParent->firstChild = aChild.nextSibling;
	}
	
	if (aChild == oldParent->lastChild) {
		oldParent->lastChild = aChild.previousSibling;
	}
	
	aChild->nextSibling = nil;
	aChild->previousSibling = nil;
	
	[aChild setParent:nil];
}

+ (void)parent:(Section *)newParent insertChild:(Section *)aChild afterSibling:(Section *)afterSibling {
	if (aChild->parent) {
		[self parent:aChild->parent removeChild:aChild];
	}
	
	newParent->countOfChildren++;
	
	if (afterSibling) {
		aChild->previousSibling = afterSibling;
		aChild->nextSibling = afterSibling->nextSibling;
		afterSibling->nextSibling.previousSibling = aChild;
		afterSibling->nextSibling = aChild;
	} else {
		aChild->previousSibling = nil;
		aChild->nextSibling = newParent->firstChild;
		newParent->firstChild.previousSibling = aChild;
	}
	
	if (aChild->previousSibling == nil) {
		newParent->firstChild = aChild;
	}
	
	if (aChild->nextSibling == nil) {
		newParent->lastChild = aChild;
	}
	
	[aChild setParent:newParent];	
}

- (id)init {
	if (self = [super init]) {
		level = -1;
	}
	return self;
}

- (void)setLevel:(NSInteger)newLevel includeChildren:(BOOL)includeChildren {
	[NSException raise:@"Can't set level on root" format:@""];
}

- (void)setSelfString:(NSString *)newSectionString {
	// Do nothing, this should only get called when reading a string.
}

- (RootSection *)root {
	return self;
}

- (BOOL)isRoot {
	return YES;
}

- (void)replaceSubtreeCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
	[tree beginChangingSections];
	
	Section *firstTouchedSection = nil;
	NSMutableArray *touchedSections = [NSMutableArray array];
	NSUInteger maxRange = NSMaxRange(aRange);
	NSRange eachRange = NSMakeRange(0, 0);
	NSRange localRange = NSMakeRange(NSNotFound, 0);
	
	// 1. Find touched sections
	for (Section *each in self.descendants) {
		eachRange.length = each.selfStringLength;
		if (eachRange.location <= maxRange) {
			if (NSMaxRange(eachRange) > aRange.location) {
				if (localRange.location == NSNotFound) {
					localRange = aRange;
					localRange.location -= eachRange.location;
				}
				[touchedSections addObject:each];
				if (!firstTouchedSection) {
					firstTouchedSection = each;
				}
			}
		} else {
			break;
		}
		eachRange.location += eachRange.length;
	}
	
	// 2. Determine insert location.
	Section *insertBefore = [[touchedSections lastObject] treeOrderNext];
	
	if (!firstTouchedSection) {
		localRange.location = 0;
	}
	
	// 3. Delete old sections
	for (Section *each in touchedSections) {
		[self removeSubtreeSection:each includeChildren:NO];
		//[each.parent removeChildrenObject:each];
	}
	
	// 4. Calculate and insert new sections.
	NSMutableString *editedString = [Section sectionsToString:[touchedSections objectEnumerator] includeTags:YES];
	[editedString replaceCharactersInRange:localRange withString:aString];
	NSMutableArray *newSections = [Section sectionsFromString:editedString];
	
	for (Section *each in newSections) {
		[self insertSubtreeSection:each before:insertBefore];
	}
	
	[tree endChangingSections];
}

- (void)insertSubtreeSection:(Section *)insertedSection before:(Section *)beforeSection {
	NSAssert(self.root == self, @"");
	
	if (!beforeSection) {
		[self insertSubtreeSection:insertedSection after:lastChild.leftmostDescendantOrSelf];
	} else {
		[self insertSubtreeSection:insertedSection after:beforeSection.treeOrderPrevious];
	}
}

- (void)insertSubtreeSection:(Section *)insertedSection after:(Section *)afterSection {
	NSAssert(insertedSection->parent == nil, @"");
	
	[tree beginChangingSections];
		
	// 1. Save reference to first section that may be effected by this insertion.
	Section *firstEffected = afterSection != nil ? afterSection.treeOrderNext : tree.firstSection;
		
	// 2. Just insert at after section level... may be wrong location. Just get into tree so that fixTreeParent can be called.
	//[RootSection parent:afterSection != nil ? afterSection->parent : self insertChild:insertedSection afterSibling:afterSection];

	// 2. Inset as first child of afterSection. This will get it in the right tree order, fixTreeParent will fix the level if needed.
	[RootSection parent:afterSection != nil ? afterSection : self insertChild:insertedSection afterSibling:nil];
	
	// 3. Fix location if needed.
	[insertedSection fixTreeParentFromSection:insertedSection.treeOrderPrevious];

	// 4. Fix existing nodes that now should be parented to inserted subtree.
	Section *possibleReparentParent = insertedSection.leftmostDescendantOrSelf;
	Section *eachEffected = firstEffected;
	
	while (eachEffected != nil && eachEffected.level > insertedSection->level) {
		Section *nextEffected = eachEffected.treeOrderNextSkippingInterior;
		//Section *nextEffected = eachEffected.treeOrderNext;
		[eachEffected fixTreeParentFromSection:possibleReparentParent];
		possibleReparentParent = eachEffected;
		eachEffected = nextEffected;
	}

	// 5. Add to tree.
	[insertedSection setTree:tree];
	[insertedSection retain];
	
	[tree endChangingSections];
}

- (void)removeSubtreeSection:(Section *)removedSection includeChildren:(BOOL)includeChildren {
	[self removeSubtreeSection:removedSection includeChildren:includeChildren fixLocations:YES];
}

- (void)removeSubtreeSection:(Section *)removedSection includeChildren:(BOOL)includeChildren fixLocations:(BOOL)fixLocations {
	[tree beginChangingSections];
	
	Section *removedSectionTreeOrderPrevious = removedSection.treeOrderPrevious;
	NSArray *effectedLocations = nil;
	
	if (includeChildren) {
		// Collect all effected locations.
		for (Section *each in [removedSection descendantsWithSelf]) {
			NSArray *trackedLocations = [tree trackedLocationsFor:each];
			if (trackedLocations) {
				if (effectedLocations == nil) effectedLocations = [NSMutableArray array];
				[(id)effectedLocations addObjectsFromArray:trackedLocations];
			}
		}
		
		// Remove section and all children.
		[RootSection parent:removedSection->parent removeChild:removedSection];
		[removedSection setTree:nil];	
		[removedSection autorelease];
	} else {
		// 1. Save valid references.
		Section *validStart = removedSectionTreeOrderPrevious;
		Section *eachChild = removedSection.firstChild;
		Section *eachPreviousChild = nil;
		BOOL hasChildren = NO;
		
		if (!validStart) validStart = tree.rootSection;
		
		// 2. Locations		
		effectedLocations = [[[tree trackedLocationsFor:removedSection] copy] autorelease];
		
		// 3. Remove, removed, also temporarily removes all children from tree.
		[RootSection parent:removedSection->parent removeChild:removedSection];
		[removedSection setTree:nil];	
		[removedSection autorelease];
		
		// 4. Reparent each child of removed section to tree order previous section.
		// And add eachChild back to tree.
		while (eachChild) {
			Section *next = eachChild.nextSibling;
			[RootSection parent:validStart insertChild:eachChild afterSibling:eachPreviousChild];
			eachPreviousChild = eachChild;
			[eachChild setTree:tree];
			eachChild = next;
			hasChildren = YES;
		}
		
		// 5. Fix tree parent of each child of removed if needed.		
		if (hasChildren) {
			Section *lastEffected = eachPreviousChild;
			Section *possibleReparentParent = validStart;
			Section *eachEffected = validStart.treeOrderNext;
			
			while (eachEffected) {
				Section *eachEffectedNext = eachEffected.nextSibling;
				[eachEffected fixTreeParentFromSection:possibleReparentParent];
				if (eachEffected == lastEffected) {
					eachEffected = nil;
				} else {
					possibleReparentParent = eachEffected;
					eachEffected = eachEffectedNext;
				}
			}
		}
	}	
	
	// 6. Update effected locations to point to valid sections in tree.
	if (fixLocations && effectedLocations != nil) {
		Section *locationsNewSection = removedSectionTreeOrderPrevious;
		NSUInteger locationsNewOffset;
		
		if (locationsNewSection) {
			locationsNewOffset = [locationsNewSection selfStringLength] - 1;
		} else {
			locationsNewSection = tree.firstSection;
			if (!locationsNewSection) {
				locationsNewSection = tree.rootSection;
			}
			locationsNewOffset = 0;
		}
		
		for (TrackedLocation *each in effectedLocations) {
			each.sectionID = locationsNewSection.uniqueID;
			each.sectionOffset = locationsNewOffset;
		}
	}
	
	[tree endChangingSections];
}

@end

@implementation Section (RootSectionPrivate)

- (void)setParent:(Section *)newParent {
	parent = newParent;
}

- (void)setPreviousSibling:(Section *)section {
	previousSibling = section;
}

- (void)setNextSibling:(Section *)section {
	nextSibling = section;
}

- (void)setTree:(Tree *)newTree {
	if (tree) {
		[tree removeSectionForID:uniqueID];
	}
	
	tree = newTree;
	
	if (tree) {
		[tree setSection:self forID:uniqueID];
	}
	
	Section *eachChild = firstChild;
	while (eachChild) {
		[eachChild setTree:tree];
		eachChild = eachChild->nextSibling;
	}
}

- (void)fixTreeParentFromSection:(Section *)possibleParent {
	Section *root = self.root;
	Section *possiblePreviousSibling = nil;
	
	while (possibleParent) {
		if (possibleParent == root) {
			break;
		} else if (possibleParent->level < level) {
			break;
		} else {
			possiblePreviousSibling = possibleParent;
			possibleParent = possibleParent->parent;
		}
	}
	
	if (possibleParent != nil && possibleParent != parent) {
		[RootSection parent:possibleParent insertChild:self afterSibling:possiblePreviousSibling];
	}
}

@end

@implementation Tree (RootSectionPrivate)


- (void)setSection:(Section *)aSection forID:(NSString *)uniqueID {
	[self beginChangingSections];
	[uniqueIDsToSections setObject:aSection forKey:uniqueID];
	[insertedSections addObject:aSection];
	[updatedSections removeObject:aSection];
	[self endChangingSections];
}

- (void)removeSectionForID:(NSString *)uniqueID {
	[self beginChangingSections];
	Section *removedSection = [uniqueIDsToSections objectForKey:uniqueID];
	[deletedSections addObject:removedSection];
	[updatedSections removeObject:removedSection];
	[insertedSections removeObject:removedSection];
	[uniqueIDsToSections removeObjectForKey:uniqueID];
	[self endChangingSections];
}

@end
