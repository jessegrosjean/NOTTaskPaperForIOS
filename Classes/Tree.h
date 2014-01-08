//
//  Tree.h
//  Documents
//
//  Created by Jesse Grosjean on 5/18/09.
//  Copyright Hog Bay Software 2009 . All rights reserved.
//

@class RootSection;
@class TrackedLocation;
@class Section;
@class Patch;

@protocol TreeDelegate;


@interface Tree : NSObject {	
	NSUndoManager *undoManager;
	RootSection *rootSection;
	NSUInteger changingSections;
	NSMutableSet *insertedSections;
	NSMutableSet *updatedSections;
	NSMutableSet *deletedSections;
	NSMutableDictionary *uniqueIDsToSections;
	NSMutableDictionary *trackedLocations;
	NSString *textContent;
    
    id<TreeDelegate> delegate;
    
    Patch *uncommitedTextContentPatch;
	NSString *commitedTextContent;
	NSMutableArray *commitedTextContentPatches;
    
    BOOL skipSave;
}

- (void)updateIconBadgeNumberCount;

- (id)initWithPatchHistory:(NSArray *)anArray textContent:(NSString *)aString;

@property (nonatomic, assign) id<TreeDelegate> delegate;

#pragma mark Properties

@property(readonly, nonatomic) NSArray *allTagNames;
@property(readonly, nonatomic) NSUndoManager *undoManager;

#pragma mark Sections (Reading)

@property(readonly, nonatomic) RootSection *rootSection;
@property(readonly, nonatomic) Section *firstSection;
@property(readonly, nonatomic) Section *lastSection;
@property(readonly, nonatomic) NSEnumerator *topLevelSections;
@property(readonly, nonatomic) NSEnumerator *enumeratorOfSubtreeSections;
@property(assign, nonatomic) BOOL skipSave;

- (Section *)valueInSectionsWithID:(NSString *)uniqueID;
- (Section *)firstSubtreeSectionMatchingPredicate:(NSPredicate *)predicate;
- (NSMutableArray *)subtreeSectionsMatchingPredicate:(NSPredicate *)predicate;
- (NSMutableArray *)subtreeSectionsMatchingPredicate:(NSPredicate *)predicate includeAncestors:(BOOL)includeAncestors includeDescendants:(BOOL)includeDescendants;

#pragma mark Sections (Changing)

- (void)beginChangingSections;
- (void)endChangingSections;
- (void)addSubtreeSectionsObject:(Section *)aSection;
- (void)insertSubtreeSection:(Section *)insertedSection before:(Section *)beforeSection;
- (void)insertSubtreeSection:(Section *)insertedSection after:(Section *)afterSection;
- (void)removeSubtreeSectionsObject:(Section *)removedSection;
- (void)removeSubtreeSectionsObject:(Section *)removedSection includeChildren:(BOOL)includeChildren;
- (void)sectionUpdated:(Section *)aSection;
- (void)sectionUpdated:(Section *)aSection range:(NSRange)aRange string:(NSString *)aString;


#pragma mark Locations

- (NSArray *)trackedLocationsFor:(Section *)aSection;
- (void)addTrackedLocation:(TrackedLocation *)aTrackedLocation;
- (void)removeTrackedLocation:(TrackedLocation *)aTrackedLocation;

#pragma mark Text API
@property (retain, nonatomic) NSString *textContent;
@property (readonly, nonatomic) NSString *commitedTextContent;
@property (readonly, nonatomic) NSArray *commitedTextContentPatches;


- (NSUInteger)textContentOffsetForSection:(Section *)aSection;
- (void)replaceTextContentCharactersInRange:(NSRange)aRange withString:(NSString *)aString;
- (NSArray *)calculatePatchFromCurrentTextToNewText:(NSString *)newText;
- (NSArray *)applyPatch:(NSMutableArray *)diffs actionName:(NSString *)actionName;
- (void)commitCurrentPatch:(NSString *)actionName;


@end

@interface TrackedLocation : NSObject {
	Tree *tree;
	NSString *sectionID;
	NSUInteger sectionOffset;
}

+ (id)trackedLocationWithSection:(Section *)section offset:(NSUInteger)offset;

- (id)initWithSection:(Section *)section offset:(NSUInteger)offset;

@property(readonly, nonatomic) Section *section;
@property(retain, nonatomic) NSString *sectionID;
@property(assign, nonatomic) NSUInteger sectionOffset;

@end

@protocol TreeDelegate

- (void)saveToDisk;

@end

extern NSString *TreeChanged;
extern NSString *InsertedSectionsKey;
extern NSString *UpdatedSectionsKey;
extern NSString *DeletedSectionsKey;