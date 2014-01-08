//
//  NaturalComparisonPredicate.h
//  Documents
//
//  Created by Jesse Grosjean on 6/16/09.
//  Copyright 2009 Hog Bay Software. All rights reserved.
//


@interface NaturalComparisonPredicate : NSComparisonPredicate {

}

+ (NSPredicate *)rebuildWithNaturalComprisonPredicates:(NSPredicate *)predicate;

@end
