//
//  Tree.m
//  Documents
//
//  Created by Jesse Grosjean on 5/18/09.
//  Copyright Hog Bay Software 2009 . All rights reserved.
//

#import "Tree.h"
#import "Tag.h"
#import "Section.h"
#import "RootSection.h"
#import "DiffMatchPatch.h"
#import "NSString_Additions.h"
#import "TreeUndoManager.h"
#import "TaskPaperSection.h"

#import "ApplicationController.h"
#import "ApplicationViewController.h"

@interface Patch (TreePrivate)
- (void)setPatches:(NSArray *)aPatches;
@end

@interface TrackedLocation (TreePrivate)
- (void)setTree:(Tree *)aTree;
@end

@implementation Tree
@synthesize delegate, skipSave;

#pragma mark Class Methods

+ (void)initialize {
	if (self == [Tree class]) {
	}
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
	return [super automaticallyNotifiesObserversForKey:key];
}

#pragma mark Init

- (id)init {
	return [self initWithPatchHistory:nil textContent:nil];
}

- (id)initWithPatchHistory:(NSArray *)anArray textContent:(NSString *)aString {
	if (!anArray) anArray = [NSArray array];
	
	if (self = [super init]) {
		insertedSections = [[NSMutableSet alloc] init];
		updatedSections = [[NSMutableSet alloc] init];
		deletedSections = [[NSMutableSet alloc] init];
		uniqueIDsToSections = [[NSMutableDictionary alloc] init];
		trackedLocations = [[NSMutableDictionary alloc] init];
		self.textContent = aString;
        [commitedTextContent autorelease];
		commitedTextContent = [self.textContent retain];
		commitedTextContentPatches = [anArray mutableCopy];
		[self commitCurrentPatch:NSLocalizedString(@"External Changes", nil)];
		undoManager = [[TreeUndoManager alloc] init];
		[undoManager setGroupsByEvent:NO];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoManagerWillRedoChangeNotification:) name:NSUndoManagerWillRedoChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoManagerWillUndoChangeNotification:) name:NSUndoManagerWillUndoChangeNotification object:nil];
	}
	
	return self;
}

#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[undoManager release];
	[rootSection release];
	[insertedSections release];
	[updatedSections release];
	[deletedSections release];
	[uniqueIDsToSections release];
	[textContent release];
    [uncommitedTextContentPatch release];
	[commitedTextContent release];
	[commitedTextContentPatches release];
	[trackedLocations release];
	[super dealloc];
}

#pragma mark Properties

- (NSArray *)allTagNames {
	NSMutableSet *allTagNames = [NSMutableSet set];
	for (Section *section in self.enumeratorOfSubtreeSections) {
		for (Tag *tag in section.tags) {
			[allTagNames addObject:tag.name];
		}
	}
	return [[allTagNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

@synthesize undoManager;

#pragma mark Sections (Reading)

- (RootSection *)rootSection {
	return rootSection;
}

- (Section *)firstSection {
	return rootSection.firstChild;
}

- (Section *)lastSection {
	return rootSection.lastChild.leftmostDescendantOrSelf;
}

- (NSEnumerator *)topLevelSections {
	return rootSection.enumeratorOfChildren;
}

- (NSEnumerator *)enumeratorOfSubtreeSections {
	return rootSection.descendants;
}

- (Section *)valueInSectionsWithID:(NSString *)uniqueID {
	return [uniqueIDsToSections objectForKey:uniqueID];
}

- (Section *)firstSubtreeSectionMatchingPredicate:(NSPredicate *)predicate {
	for (Section *each in self.enumeratorOfSubtreeSections) {
		if (predicate == nil || [predicate evaluateWithObject:each]) {
			return each;
		}
	}
	return nil;
}

- (NSMutableArray *)subtreeSectionsMatchingPredicate:(NSPredicate *)predicate {
	return [self subtreeSectionsMatchingPredicate:predicate includeAncestors:NO includeDescendants:NO];
}

- (NSMutableArray *)subtreeSectionsMatchingPredicate:(NSPredicate *)predicate includeAncestors:(BOOL)includeAncestors includeDescendants:(BOOL)includeDescendants {
	if (predicate == nil) {
		return [NSMutableArray arrayWithArray:[self.enumeratorOfSubtreeSections allObjects]];
	}
	
	NSMutableSet *includedAncestors = includeAncestors ? [NSMutableSet set] : nil;
	NSMutableArray *matchingSections = [NSMutableArray array];
	Section *eachSection = [self.rootSection treeOrderNext];

	@try {
		// Wrap in try block because some searches, such as 'matches "["' throw exceptions when run.
		while (eachSection) {
			if ([predicate evaluateWithObject:eachSection]) {
				if (includeAncestors) {
					for (Section *eachAncestor in [[eachSection.ancestors allObjects] reverseObjectEnumerator]) {
						if (![includedAncestors containsObject:eachAncestor]) {
							if (eachAncestor != eachSection && ![eachAncestor isRoot]) {
								[matchingSections addObject:eachAncestor];
								[includedAncestors addObject:eachAncestor];
							}
						}
					}
				}
				
				[includedAncestors addObject:eachSection];
				[matchingSections addObject:eachSection];
				
				if (includeDescendants) {
					[matchingSections addObjectsFromArray:[eachSection.descendants allObjects]];
					eachSection = [matchingSections lastObject];
				}
			}
			eachSection = [eachSection treeOrderNext];
		}
	} @catch (NSException * e) {
		NSLog([e description], nil);
		return [NSMutableArray array];
	}
	
	return matchingSections;
}

#pragma mark Sections (Changing)

- (void)beginChangingSections {
	changingSections++;
	[textContent release];
	textContent = nil;
}

- (void)endChangingSections {
	changingSections--;
	[textContent release];
	textContent = nil;
	if (changingSections == 0) {		
        if (uncommitedTextContentPatch == nil && undoManager != nil) {
            uncommitedTextContentPatch = [[Patch alloc] init];
			[undoManager beginUndoGrouping];
            //NSLog(@"beginUndoGrouping");
			[undoManager registerUndoWithTarget:self selector:@selector(undoPatch:) object:uncommitedTextContentPatch];
        }
        
		[[NSNotificationCenter defaultCenter] postNotificationName:TreeChanged object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[[insertedSections copy] autorelease], InsertedSectionsKey, [[updatedSections copy] autorelease], UpdatedSectionsKey, [[deletedSections copy] autorelease], DeletedSectionsKey, nil]];
		

		[insertedSections removeAllObjects];
		[updatedSections removeAllObjects];
		[deletedSections removeAllObjects];
        
        //Show Badge number
        [self updateIconBadgeNumberCount];
	}
    if (delegate) {
        if (skipSave) {
            skipSave = NO;
        } else {
            [delegate saveToDisk];
        }
    }
}

- (void)updateCount:(NSNumber *)number {
    [UIApplication sharedApplication].applicationIconBadgeNumber = [number integerValue];
}

- (void)countUndone {
    NSArray *undoneEntries = [self subtreeSectionsMatchingPredicate:[NSPredicate predicateWithFormat:@"type == %i AND not (ANY tags.name = \"done\")", TaskPaperSectionTypeTask]];
    [self performSelectorOnMainThread:@selector(updateCount:) withObject:[NSNumber numberWithInteger:[undoneEntries count]] waitUntilDone:NO];
}

- (void)updateIconBadgeNumberCount {
    if (APP_VIEW_CONTROLLER.iconBadgeNumberEnabled) {
        [self performSelectorInBackground:@selector(countUndone) withObject:nil];
    } else {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
}

- (void)addSubtreeSectionsObject:(Section *)aSection {
	[self insertSubtreeSection:aSection before:nil];
}

- (void)insertSubtreeSection:(Section *)insertedSection before:(Section *)beforeSection {
	[rootSection insertSubtreeSection:insertedSection before:beforeSection];
}

- (void)insertSubtreeSection:(Section *)insertedSection after:(Section *)afterSection {
	[rootSection insertSubtreeSection:insertedSection after:afterSection];
}

- (void)removeSubtreeSectionsObject:(Section *)removedSection {
	[rootSection removeSubtreeSection:removedSection includeChildren:YES];
}

- (void)removeSubtreeSectionsObject:(Section *)removedSection includeChildren:(BOOL)includeChildren {
	[rootSection removeSubtreeSection:removedSection includeChildren:includeChildren];
}

- (void)sectionUpdated:(Section *)section {
	[self sectionUpdated:section range:NSMakeRange(NSNotFound, 0) string:nil];
}

- (void)sectionUpdated:(Section *)aSection range:(NSRange)aRange string:(NSString *)aString {
	if (![deletedSections containsObject:aSection]) {
		if (![insertedSections containsObject:aSection]) {
            [self beginChangingSections];
            [updatedSections addObject:aSection];
            [self endChangingSections];
		}
	}
}

#pragma mark Locations

- (NSArray *)trackedLocationsFor:(Section *)aSection {
	return [trackedLocations objectForKey:aSection.uniqueID];
}

- (void)addTrackedLocation:(TrackedLocation *)aTrackedLocation {
	NSMutableArray *locations = [trackedLocations objectForKey:aTrackedLocation.sectionID];
	if (!locations) {
		locations = [NSMutableArray arrayWithObject:aTrackedLocation];
		[trackedLocations setObject:locations forKey:aTrackedLocation.sectionID];
	} else {
		[locations addObject:aTrackedLocation];
	}
	[aTrackedLocation setTree:self];
}

- (void)removeTrackedLocation:(TrackedLocation *)aTrackedLocation {
	NSMutableArray *locations = [trackedLocations objectForKey:aTrackedLocation.sectionID];
	if (locations) {
		[locations removeObject:aTrackedLocation];
		if ([locations count] == 0) {
			[trackedLocations removeObjectForKey:aTrackedLocation.sectionID];
		}
	}
	[aTrackedLocation setTree:nil];
}

#pragma mark Text API

- (NSString *)textContent {
	if (!textContent) {
		textContent = [[Section sectionsToString:rootSection.descendants includeTags:YES] retain];
	}
	return textContent;
}

- (void)setTextContent:(NSString *)newTextContents {
	[self beginChangingSections];
	[rootSection performSelector:@selector(setTree:) withObject:nil];
	[rootSection autorelease];
	rootSection = [[Section rootSectionFromString:newTextContents] retain];
	[rootSection performSelector:@selector(setTree:) withObject:self];
	[self endChangingSections];
}

@synthesize commitedTextContent;
@synthesize commitedTextContentPatches;

- (NSUInteger)textContentOffsetForSection:(Section *)aSection {
	NSUInteger offset = 0;
	for (Section *each in self.enumeratorOfSubtreeSections) {
		if (each == aSection) {
			return offset;
		} else {
			offset += each.selfStringLength;
		}
	}
	return NSNotFound;
}

- (void)replaceTextContentCharactersInRange:(NSRange)aRange withString:(NSString *)aString {
	[rootSection replaceSubtreeCharactersInRange:aRange withString:aString];
}

- (NSArray *)calculatePatchFromCurrentTextToNewText:(NSString *)newText {
	DiffMatchPatch *dmp = [[[DiffMatchPatch alloc] init] autorelease];
	return [dmp patch_makeFromOldString:self.textContent andNewString:newText];
}


- (NSArray *)applyPatch:(NSMutableArray *)diffs actionName:(NSString *)actionName {
	[self beginChangingSections];
	DiffMatchPatch *dmp = [[[DiffMatchPatch alloc] init] autorelease];
	NSArray *results = [dmp patch_apply:diffs toString:self.textContent delegate:self selector:@selector(replaceTextContentCharactersInRange:withString:)];
	[self endChangingSections];
	[self commitCurrentPatch:actionName];
	return results;
}

- (void)commitCurrentPatch:(NSString *)actionName {
	if (uncommitedTextContentPatch) {
        NSMutableArray *patches = [[[[DiffMatchPatch alloc] init] autorelease] patch_makeFromOldString:commitedTextContent andNewString:self.textContent];
        [uncommitedTextContentPatch setDiffs:patches];
		if ([patches count] > 0) {
			[commitedTextContentPatches addObject:uncommitedTextContentPatch];
			if (actionName) {
                //NSLog(@"setActionName:%@", actionName);
				[[self undoManager] setActionName:actionName];
			}
		}
		[undoManager endUndoGrouping];
        //NSLog(@"endUndoGrouping: %@", actionName);
		[commitedTextContent autorelease];
		commitedTextContent = [self.textContent retain];
		[uncommitedTextContentPatch release];
		uncommitedTextContentPatch = nil;		
	}
}

- (void)undoPatch:(Patch *)patch {	
    NSMutableArray *reversedPatches = [NSMutableArray arrayWithCapacity:[patch.diffs count]];
	for (Patch *each in patch.diffs) {
		[reversedPatches addObject:[each reverse]];
	}
    
    
	[self applyPatch:reversedPatches actionName:nil];
}

- (void)undoManagerWillUndoChangeNotification:(NSNotification *)aNotification {
	if ([aNotification object] == undoManager) {
		[self commitCurrentPatch:nil];
	}
}

- (void)undoManagerWillRedoChangeNotification:(NSNotification *)aNotification {
	if ([aNotification object] == undoManager) {
		[self commitCurrentPatch:nil];
	}
}


@end

@implementation TrackedLocation

+ (id)trackedLocationWithSection:(Section *)section offset:(NSUInteger)offset {
	return [[[TrackedLocation alloc] initWithSection:section offset:offset] autorelease];
}

- (id)initWithSection:(Section *)section offset:(NSUInteger)offset {
	if (self = [super init]) {
		self.sectionID = section.uniqueID;
		self.sectionOffset = offset;
	}
	return self;
}

- (void)dealloc {
	[sectionID release];
	tree = nil;
	[super dealloc];
}

- (void)setTree:(Tree *)aTree {
	tree = aTree;
}

- (Section *)section {
	return [tree valueInSectionsWithID:self.sectionID];
}

@synthesize sectionID;

- (void)setSectionID:(NSString *)newSectionID {
	Tree *savedTreeReference = tree;
	[tree removeTrackedLocation:self];
	[sectionID release];
	sectionID = [newSectionID retain];
	[savedTreeReference addTrackedLocation:self];
}

@synthesize sectionOffset;

- (void)setSectionOffset:(NSUInteger)offset {
	sectionOffset = offset;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<TrackedLocation line=\"%@\" offset=%i>", self.section.selfString, sectionOffset];
}

@end


NSString *TreeChanged= @"TreeChanged";
NSString *InsertedSectionsKey = @"InsertedSectionsKey";
NSString *UpdatedSectionsKey = @"UpdatedSectionsKey";
NSString *DeletedSectionsKey = @"DeletedSectionsKey";