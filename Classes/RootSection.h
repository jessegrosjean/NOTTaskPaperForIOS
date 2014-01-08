//
//  RootSection.h
//  Documents
//
//  Created by Jesse Grosjean on 6/3/09.
//  Copyright 2009 Hog Bay Software. All rights reserved.
//

#import "Section.h"


@interface RootSection : Section {

}

+ (void)parent:(Section *)newParent removeChild:(Section *)aChild;
+ (void)parent:(Section *)newParent insertChild:(Section *)aChild afterSibling:(Section *)afterSibling;
- (void)replaceSubtreeCharactersInRange:(NSRange)aRange withString:(NSString *)aString;
- (void)insertSubtreeSection:(Section *)insertedSection before:(Section *)beforeSection;
- (void)insertSubtreeSection:(Section *)insertedSection after:(Section *)afterSection;
- (void)removeSubtreeSection:(Section *)removedSection includeChildren:(BOOL)includeChildren;
- (void)removeSubtreeSection:(Section *)removedSection includeChildren:(BOOL)includeChildren fixLocations:(BOOL)fixLocations;

@end
