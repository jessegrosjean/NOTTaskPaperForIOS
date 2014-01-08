//
//  Section.m
//  Documents
//
//  Created by Jesse Grosjean on 5/18/09.
//

#import "Section.h"
#import "RootSection.h"
#import "Tag.h"
#import "Tree.h"
#import "TaskPaperSection.h"
#import "RegexKitLite.h"
#import "NSObject_Additions.h"
#import "NSString_Additions.h"

@interface TreeOrderEnumerator : NSEnumerator {
	Section *current;
	Section *end;
}
- (id)initWithStart:(Section *)aStart end:(Section *)anEnd;
@end

@interface SiblingEnumerator : NSEnumerator {
	Section *current;
}
- (id)initWithStart:(Section *)aSection;
@end

@interface AncestorEnumerator : NSEnumerator {
	Section *current;
}
- (id)initWithStart:(Section *)aSection;
@end

@implementation Section

#pragma mark Class Methods

+ (void)initialize {
	if (self == [Section class]) {
	}
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
	if ([key isEqualToString:@"content"]) {
		return NO;
	} else if ([key isEqualToString:@"level"]) {
		return NO;
	}
	return [super automaticallyNotifiesObserversForKey:key];
}

static Class sectionClass = nil;

+ (Class)sectionClass {
	if (!sectionClass) {
		sectionClass = [TaskPaperSection class];
	}
	return sectionClass;
}

+ (void)setSectionClass:(Class)aClass {
	sectionClass = aClass;
}

+ (Section *)sectionWithString:(NSString *)aString {
	return [[[[self sectionClass] alloc] initWithString:aString] autorelease];
}

+ (NSArray *)commonAncestorsForSections:(NSEnumerator *)sections {
	NSArray *sectionsArray = [sections allObjects];
	NSMutableArray *result = [NSMutableArray arrayWithArray:sectionsArray];
	
	for (Section *each in sectionsArray) {
		Section *eachParent = each.parent;
		
		while (eachParent) {
			if ([result containsObject:eachParent]) {
				[result removeObject:each];
				break;
			} else {
				eachParent = eachParent.parent;
			}
		}
	}
	
	return result;	
}

#pragma mark Init

- (id)initWithString:(NSString *)aString {
	if (self = [super init]) {
		static NSUInteger uniqueIDFactory = 0;
		uniqueID = [[NSString stringWithFormat:@"n%i", uniqueIDFactory++] retain];
		self.selfString = aString;
	}
	return self;
}

- (id)init {
	return [self initWithString:@""];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ %i %@", [super description], level, content, nil];
}

#pragma mark Dealloc

- (void)dealloc {
	[uniqueID release];
	[content release];
	tree = nil;
	[tags release];
	[selfString release];
	parent = nil;
	
	Section *each = firstChild;
	while (each) {
		Section *next = each.nextSibling;
		[each release];
		each = next;
	}
	
	[super dealloc];
}

#pragma mark Attributes

@synthesize tree;
@synthesize uniqueID;
@synthesize type;

- (void)setType:(NSUInteger)newType {
	if (type != newType) {
		[tree beginChangingSections];
		type = newType;
		[self noteSelfStringChanged];
		[tree endChangingSections];
	}
}

- (NSString *)typeAsString {
	return nil;
}

- (BOOL)isBlank {
	return [content length] == 0;
}

@synthesize level;

- (void)setLevel:(NSInteger)newLevel {
	[self setLevel:newLevel includeChildren:YES];
}

- (void)setLevel:(NSInteger)newLevel includeChildren:(BOOL)includeChildren {
	if (level != newLevel) {
		NSUInteger oldLevel = level;
		RootSection *root = self.root;
		Section *savedPreviousSection = self.treeOrderPrevious;
		
		if (root == nil && includeChildren == NO) {
			[NSException raise:@"Can't set level without including children unless connected to root." format:@""];
		}
		
		[root removeSubtreeSection:self includeChildren:includeChildren fixLocations:NO]; // remove is temporary, so don't reparent locations.

		[self willChangeValueForKey:@"level"];
		level = newLevel;
		[self didChangeValueForKey:@"level"];
		
		if (includeChildren) {
			NSInteger delta = newLevel - oldLevel;
			for (Section *eachChild in self.enumeratorOfChildren) {
				[eachChild setLevel:eachChild.level + delta includeChildren:YES];
			}
		}
		
		[root insertSubtreeSection:self after:savedPreviousSection];				
	}
}

- (NSString *)levelAsString {
	return [NSString stringWithFormat:@"%i", level];
}

- (NSInteger)index {
	NSUInteger index = 0;
	Section *each = self.previousSibling;
	while (each) {
		index++;
		each = each.previousSibling;
	}
	return index;
}

- (NSString *)indexAsString {
	return [NSString stringWithFormat:@"%i", self.index];
}

@synthesize content;

- (void)setContent:(NSString *)newContent { 
	// Assign content without validation.
	[content autorelease];
	content = [newContent retain];
	// Then reparse entire string with validation.
	NSMutableString *string = [NSMutableString string];
	[self writeSelfToString:string includeTags:YES];
	self.selfString = string;
}

- (void)replaceContentInRange:(NSRange)aRange withString:(NSString *)aString {
	[self.tree beginChangingSections];
	self.content = [content stringByReplacingCharactersInRange:aRange withString:aString];
	[self.tree sectionUpdated:self range:aRange string:aString];
	[self.tree endChangingSections];
}

#pragma mark SelfString 

- (NSUInteger)selfStringLength {
	return [self.selfString length];
}

- (NSString *)selfString {
	if (!selfString) {
		NSMutableString *mustableString = [[NSMutableString alloc] init];
		[self writeSelfToString:mustableString includeTags:YES];
		selfString = mustableString;
	}
	return selfString;
}

- (void)setSelfString:(NSString *)newSectionString {
	[self subclassResponsibilityForSelector:@selector(setSelfString:)];
}

- (void)noteSelfStringChanged {
	[selfString release];
	selfString = nil;
	[tree sectionUpdated:self];
}

#pragma mark Tags

- (NSArray *)tags {
	if (!tags) {
		tags = [[Tag parseTagsInString:content] retain];
	}
	return tags;
}

- (Tag *)tagWithOnlyName:(NSString *)name {
    NSArray *parsedTags = [Tag parseTagsInString:[NSString stringWithFormat:@"@%@", name]];
    for (Tag *parsedTag in parsedTags) {
        for (Tag *each in self.tags) {
            if ([each.name isEqualToString:parsedTag.name]) {
                return each;
            }
        }
    }
    return nil;
}

- (Tag *)tagWithName:(NSString *)name {
	return [self tagWithName:name createIfNeccessary:NO];
}

- (Tag *)tagWithName:(NSString *)name createIfNeccessary:(BOOL)createIfNeccessary {
    NSArray *parsedTags = [Tag parseTagsInString:[NSString stringWithFormat:@"@%@", name]];
    for (Tag *parsedTag in parsedTags) {
        for (Tag *each in self.tags) {
            if ([each.name isEqualToString:parsedTag.name] && [each.value isEqualToString:parsedTag.value]) {
                return each;
            }
        }
    }

	if (createIfNeccessary) {
        NSArray *parsedTags = [Tag parseTagsInString:[NSString stringWithFormat:@"@%@", name]];
        for (Tag *tag in parsedTags) {
            [self addTag:tag];            
        }
        if (parsedTags && parsedTags.count > 1) {
            return [parsedTags objectAtIndex:0];
        }
	}
	
	return nil;
}

- (void)addTag:(Tag *)tag {
	self.content = [tag contentByAddingTag:self.content];
}

- (void)removeTag:(Tag *)tag {
	self.content = [tag contentByRemovingTag:self.content];
}

#pragma mark Tree

- (BOOL)isRoot {
	return NO;
}

- (RootSection *)root {
	return parent.root;
}

- (Section *)treeOrderPrevious {
	if (previousSibling) {
		return previousSibling.leftmostDescendantOrSelf;
	} else {
		if (parent.isRoot) {
			return nil;
		} else {
			return parent;
		}
	}
}

- (Section *)treeOrderNext {
	if (firstChild) return firstChild;
	if (nextSibling) return nextSibling;
	Section *p = parent;
	while (p) {
		if (p->nextSibling)
			return p->nextSibling;
		p = p->parent;
	}
	return nil;
}

- (Section *)treeOrderNextSkippingInterior {
	if (nextSibling) return nextSibling;
	return [parent treeOrderNextSkippingInterior];
}

- (NSIndexPath *)treeIndexPath {
	NSUInteger treeIndexPath[level + 1];
	NSUInteger pathCount = 0;
	NSUInteger i = level;
	Section *each = self;
	
	while (each != nil && ![each isRoot]) {
		Section *eachParent = each->parent;
		NSUInteger index = 0;
		
		if (eachParent) {
			Section *eachSibling = eachParent->firstChild;
			while (eachSibling != each) {
				eachSibling = eachSibling->nextSibling;
				index++;
			}
		}
		
		treeIndexPath[i] = index;
		each = eachParent;
		pathCount++;
		i--;
	}
	
	return [NSIndexPath indexPathWithIndexes:&treeIndexPath[(level + 1) - pathCount] length:pathCount];
}

#pragma mark Ancestors

- (BOOL)isAncestor:(Section *)section {
	Section *each = parent;
	while (each != nil) {
		if (each == section) {
			return YES;
		}
		each = each.parent;
	}
	return NO;
}

- (NSEnumerator *)ancestors {
	return [[[AncestorEnumerator alloc] initWithStart:parent] autorelease];
}

- (NSEnumerator *)ancestorsWithSelf {
	return [[[AncestorEnumerator alloc] initWithStart:self] autorelease];
}

- (Section *)rootLevelAncestor {
	if (parent == nil) {
		return self;
	} else {
		return parent.rootLevelAncestor;
	}
}

#pragma mark Headers

- (NSUInteger)headerType {
	[self subclassResponsibilityForSelector:@selector(headerType:)];
	return NSNotFound;
}

- (Section *)topLevelHeader {
	NSUInteger headerType = self.headerType;
	Section *each = self;
	while (each) {
		if (each.level == 0 && each.type == headerType) {
			return each;
		}
		each = each.parent;
	}
	return nil;
}

- (Section *)containingHeader {
	return parent.headerOrSelf;
}

- (Section *)headerOrSelf {
	NSUInteger headerType = self.headerType;
	Section *each = self;
	while (each) {
		if (each.type == headerType) {
			return each;
		}
		each = each.parent;
	}
	return nil;
}

#pragma mark Decendents

- (BOOL)isDecendent:(Section *)section {
	return [self isAncestor:section];
}

- (NSEnumerator *)descendants {
	return [[[TreeOrderEnumerator alloc] initWithStart:firstChild end:lastChild.leftmostDescendantOrSelf] autorelease];
}

- (NSEnumerator *)descendantsWithSelf {
	return [[[TreeOrderEnumerator alloc] initWithStart:self end:lastChild != nil ? lastChild.leftmostDescendantOrSelf : self] autorelease];
}

- (NSString *)descendantsAsString {
	return [Section sectionsToString:self.descendants includeTags:YES];
}

- (Section *)leftmostDescendantOrSelf {
	if (lastChild) return lastChild.leftmostDescendantOrSelf;
	return self;
}

- (Section *)rightmostDescendantOrSelf {
	if (firstChild) return firstChild.rightmostDescendantOrSelf;
	return self;
}

#pragma mark Children

@synthesize parent;
@synthesize previousSibling;
@synthesize nextSibling;
@synthesize firstChild;
@synthesize lastChild;
@synthesize countOfChildren;

- (NSEnumerator *)enumeratorOfChildren {
	if (countOfChildren > 0) {
		return [[[SiblingEnumerator alloc] initWithStart:firstChild] autorelease];
	}
	return nil;
}

- (Section *)memberOfChildren:(Section *)aChild {
	return aChild.parent == self ? aChild : nil;
}

- (void)addChildrenObject:(Section *)aChild {
	[self insertChildrenObject:aChild after:lastChild]; // end of list
}

- (void)insertChildrenObject:(Section *)aChild before:(Section *)beforeChild {
	if (!beforeChild) {
		[self insertChildrenObject:aChild after:lastChild];
	} else {
		[self insertChildrenObject:aChild after:beforeChild.previousSibling];
	}
}

- (void)insertChildrenObject:(Section *)aChild after:(Section *)afterChild {
	Section *oldParent = [aChild parent];
	
	if (oldParent) {
		[oldParent removeChildrenObject:aChild];
	}
		
	aChild.level = self.level + 1;

	RootSection *root = self.root;
	if (root) {
		[root insertSubtreeSection:aChild after:afterChild != nil ? afterChild.leftmostDescendantOrSelf : self];
	} else {
		[RootSection parent:self insertChild:aChild afterSibling:afterChild];
		[aChild retain];
	}
}

- (void)removeChildrenObject:(Section *)aChild {
	RootSection *root = self.root;
	if (root) {
		[root removeSubtreeSection:aChild includeChildren:YES];
	} else {
		[RootSection parent:self removeChild:aChild];
		[aChild autorelease];
	}
}

- (void)removeFromParent {
	[parent removeChildrenObject:self];
}

#pragma mark Read / Write Strings

+ (RootSection *)rootSectionFromString:(NSString *)string {
	NSMutableArray *parsedSections = [NSMutableArray array];
	NSRange sectionRange = NSMakeRange(0, 0);
	NSUInteger length = string != nil ? [string length] : 0;
	Section *each;
	
	while (NSMaxRange(sectionRange) < length) {
		sectionRange = [string paragraphRangeForRange:sectionRange];
		each = [Section sectionWithString:[string substringWithRange:NSMakeRange(sectionRange.location, sectionRange.length)]];
		[parsedSections addObject:each];
		sectionRange = NSMakeRange(NSMaxRange(sectionRange), 0);
	}
	
	if (string != nil && [parsedSections count] == 0) {
		[parsedSections addObject:[Section sectionWithString:@""]];
	}
	
	RootSection *rootSection = [[[RootSection alloc] init] autorelease];
		
	for (Section *each in parsedSections) {
		[rootSection insertSubtreeSection:each before:nil]; // enshure added to end.
	}

	return rootSection;
}

+ (NSMutableArray *)sectionsFromString:(NSString *)string {
	Section *rootSection = [self rootSectionFromString:string];
	NSMutableArray *topLevelChildren = [NSMutableArray array];
	
	for (Section *each in [rootSection enumeratorOfChildren]) {
		[topLevelChildren addObject:each];
	}
	
	[topLevelChildren makeObjectsPerformSelector:@selector(removeFromParent)];
	
	return topLevelChildren;
}

+ (NSMutableString *)sectionsToString:(NSEnumerator *)sections includeTags:(BOOL)includeTags {
	NSMutableString *string = [NSMutableString string];
	
	for (Section *each in sections) {
		[each writeSelfToString:string includeTags:includeTags];
	}
	
	return string;
}

+ (NSString *)validateSectionString:(NSString *)aString {
	NSRange sectionRange = [aString paragraphRangeForRange:NSMakeRange(0, 0)];
	if (sectionRange.length > 0) {
		if (sectionRange.length != [aString length]) {
			[NSException raise:@"Bad Section String" format:@"Provided section string contains more then one line."];
		}
        if ([aString characterAtIndex:NSMaxRange(sectionRange) - 1] == '\n') {
            int secondIndex = NSMaxRange(sectionRange) - 2;
            if (secondIndex > 0 && secondIndex < [aString length] && [aString characterAtIndex:NSMaxRange(sectionRange) - 2] == '\r') {
                sectionRange.length -= 1;                                
            }
			sectionRange.length -= 1;
			aString = [aString substringWithRange:sectionRange];
		} if ([aString characterAtIndex:NSMaxRange(sectionRange) - 1] == '\r') {
            sectionRange.length -= 1;
			aString = [aString substringWithRange:sectionRange];
        }
	}
	return aString;
}


- (void)writeSelfToString:(NSMutableString *)aString includeTags:(BOOL)includeTags {
	[self subclassResponsibilityForSelector:@selector(writeSelfToString:includeTags:)];
}

//- (NSString *)writeSelfToDOMElement:(DOMElement *)element theme:(TreeViewTheme *)theme {
//	[self subclassResponsibilityForSelector:@selector(writeSelfToDOMElement:theme:)];
//	return nil;
//}

@end


@implementation TreeOrderEnumerator

- (id)initWithStart:(Section *)aStart end:(Section *)anEnd {
	if (self = [super init]) {
		current = [aStart retain];
		end = [anEnd retain];
	}
	return self;
}

- (void)dealloc {
	[current release];
	[end release];
	[super dealloc];
}

- (id)nextObject {
	id result = current;
	current = [current.treeOrderNext retain];
	[result autorelease];
	
	if (result == end) {
		[current release];
		current = nil;
		[end release];
		end = nil;
	}
	
	return result;
}

@end

@implementation SiblingEnumerator

- (id)initWithStart:(Section *)aSection {
	if (self = [super init]) {
		current = [aSection retain];
	}
	return self;
}

- (void)dealloc {
	[current release];
	[super dealloc];
}

- (id)nextObject {
	id result = current;
	current = [current.nextSibling retain];
	return [result autorelease];
}

@end

@implementation AncestorEnumerator

- (id)initWithStart:(Section *)aSection {
	if (self = [super init]) {
		current = [aSection retain];
	}
	return self;
}

- (void)dealloc {
	[current release];
	[super dealloc];
}

- (id)nextObject {
	id result = current;
	current = [current.parent retain];
	return [result autorelease];
}

@end