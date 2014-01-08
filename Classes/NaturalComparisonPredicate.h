//
//  NaturalComparisonPredicate.h
//  Documents
//
//  Created by Jesse Grosjean on 6/16/09.
//


@interface NaturalComparisonPredicate : NSComparisonPredicate {

}

+ (NSPredicate *)rebuildWithNaturalComprisonPredicates:(NSPredicate *)predicate;

@end
