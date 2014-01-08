//
//  Section.h
//  Documents
//
//  Created by Jesse Grosjean on 5/18/09.
//  Copyright 2009 Hog Bay Software. All rights reserved.
//


@class RootSection;
@class Tree;
@class Tag;
@class TreeViewTheme;

@interface Section : NSObject {
	Tree *tree;
	NSString *uniqueID;
	NSInteger level;
	NSString *content;
	NSUInteger type;
	NSArray *tags;
	NSString *selfString;
	Section *parent;
	Section *previousSibling;
	Section *nextSibling;
	Section *firstChild;
	Section *lastChild;
	NSUInteger countOfChildren;
}

+ (Class)sectionClass;
+ (void)setSectionClass:(Class)aClass;
+ (Section *)sectionWithString:(NSString *)aString;
+ (NSArray *)commonAncestorsForSections:(NSEnumerator *)sections;

#pragma mark Attributes

@property(readonly) Tree *tree;
@property(readonly) NSString *uniqueID;
@property (nonatomic, assign) NSUInteger type;
@property(readonly) NSString *typeAsString;
@property(readonly) BOOL isBlank;
@property(nonatomic, assign) NSInteger level;
- (void)setLevel:(NSInteger)newLevel includeChildren:(BOOL)includeChildren;
@property(readonly) NSString *levelAsString;
@property(readonly) NSInteger index;
@property(readonly) NSString *indexAsString;
@property(nonatomic, retain) NSString *content;

- (void)replaceContentInRange:(NSRange)aRange withString:(NSString *)aString;

#pragma mark SelfString 

@property(readonly) NSUInteger selfStringLength;
@property(retain) NSString *selfString;
- (void)noteSelfStringChanged;

#pragma mark Tags

@property(readonly) NSArray *tags;
- (Tag *)tagWithName:(NSString *)name;
- (Tag *)tagWithName:(NSString *)name createIfNeccessary:(BOOL)createIfNeccessary;
- (Tag *)tagWithOnlyName:(NSString *)name;
- (void)addTag:(Tag *)tag;
- (void)removeTag:(Tag *)tag;

#pragma mark Tree

@property(readonly) BOOL isRoot;
@property(readonly) RootSection *root;
@property(readonly) Section *treeOrderPrevious;
@property(readonly) Section *treeOrderNext;
@property(readonly) Section *treeOrderNextSkippingInterior;
@property(readonly) NSIndexPath *treeIndexPath;

#pragma mark Ancestors

- (BOOL)isAncestor:(Section *)section;
@property(readonly) NSEnumerator *ancestors;
@property(readonly) NSEnumerator *ancestorsWithSelf;
@property(readonly) Section *rootLevelAncestor;

#pragma mark Headers

@property(readonly) NSUInteger headerType;
@property(readonly) Section *topLevelHeader;
@property(readonly) Section *containingHeader;
@property(readonly) Section *headerOrSelf;

#pragma mark Decendents

- (BOOL)isDecendent:(Section *)section;
@property(readonly) NSEnumerator *descendants;
@property(readonly) NSEnumerator *descendantsWithSelf;
@property(readonly) NSString *descendantsAsString;
@property(readonly) Section *leftmostDescendantOrSelf;
@property(readonly) Section *rightmostDescendantOrSelf;

#pragma mark Children

@property(readonly) Section *parent;
@property(readonly) Section *previousSibling;
@property(readonly) Section *nextSibling;
@property(readonly) Section *firstChild;
@property(readonly) Section *lastChild;
@property(readonly) NSUInteger countOfChildren;
@property(readonly) NSEnumerator *enumeratorOfChildren;

- (id)initWithString:(NSString *)aString;

- (Section *)memberOfChildren:(Section *)aChild;
- (void)addChildrenObject:(Section *)aChild;
- (void)insertChildrenObject:(Section *)insertedChild before:(Section *)beforeChild;
- (void)insertChildrenObject:(Section *)insertedChild after:(Section *)afterChild;
- (void)removeChildrenObject:(Section *)aChild;
- (void)removeFromParent;

#pragma mark Read / Write Strings

+ (RootSection *)rootSectionFromString:(NSString *)string;
+ (NSMutableArray *)sectionsFromString:(NSString *)string;
+ (NSMutableString *)sectionsToString:(NSEnumerator *)sections includeTags:(BOOL)includeTags;
	
+ (NSString *)validateSectionString:(NSString *)aString;
- (void)writeSelfToString:(NSMutableString *)aString includeTags:(BOOL)includeTags;

#if !TARGET_OS_IPHONE
//- (NSString *)writeSelfToDOMElement:(DOMElement *)element theme:(TreeViewTheme *)theme;
#endif

@end