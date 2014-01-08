//
//  NSSet_Additions.h
//  PlainText
//
//  Created by Jesse Grosjean on 6/9/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//


@interface NSSet (Additions)
- (NSMutableSet *)setMinusSet:(NSSet *)aSet;
- (NSMutableSet *)setIntersectingSet:(NSSet *)aSet;
- (NSMutableSet *)setFilteredUsingPredicate:(NSPredicate *)aPredicate;
- (NSString *)conflictNameForNameInNormalizedSet:(NSString *)name;
- (NSString *)conflictNameForNameInNormalizedSet:(NSString *)name includeMessage:(BOOL)includeMessage;
@end
