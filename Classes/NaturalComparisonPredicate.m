//
//  NaturalComparisonPredicate.m
//  Documents
//
//  Created by Jesse Grosjean on 6/16/09.
//  Copyright 2009 Hog Bay Software. All rights reserved.
//

#import "NaturalComparisonPredicate.h"
#import "NSString_Additions.h"
#import "NSObject_Additions.h"


@implementation NSComparisonPredicate (BlocksMethodReplacements)

/*
+ (void)load {
	if (self == [NSComparisonPredicate class]) {
		[NSComparisonPredicate replaceMethod:@selector(evaluateWithObject:substitutionVariables:) withMethod:@selector(my_evaluateWithObject:substitutionVariables:)];
	}
}

- (BOOL)my_evaluateWithObject:(id)object substitutionVariables:(NSDictionary *)variables {
	NSPredicateOperatorType operatorType = [self predicateOperatorType];
	NSString *leftValue = [[self leftExpression] expressionValueWithObject:object context:nil];
	NSString *rightValue = [[self rightExpression] expressionValueWithObject:object context:nil];
	
	if ([leftValue isKindOfClass:[NSString class]] && [rightValue isKindOfClass:[NSString class]]) {
		NSComparisonResult result = [leftValue naturalCompare:rightValue];
		
		switch (operatorType) {
			case NSEqualToPredicateOperatorType:
				return result == NSOrderedSame;
				
			case NSLessThanPredicateOperatorType:
				return result == NSOrderedAscending;
				
			case NSLessThanOrEqualToPredicateOperatorType:
				return result == NSOrderedAscending || result == NSOrderedSame;
				
			case NSGreaterThanPredicateOperatorType:
				return result == NSOrderedDescending;
				
			case NSGreaterThanOrEqualToPredicateOperatorType:
				return result == NSOrderedDescending || result == NSOrderedSame;
		}
	}
	
	return [self my_evaluateWithObject:object substitutionVariables:variables];
}
*/

@end

@implementation NaturalComparisonPredicate

+ (NSExpression *)rebuildExpressionWithNaturalComprisonPredicates:(NSExpression *)expression {
	NSExpressionType expressionType = [expression expressionType];
	if (expressionType == NSSubqueryExpressionType) {
		//return [NSExpression expressionForSubquery:<#(NSExpression *)expression#> usingIteratorVariable:<#(NSString *)variable#> predicate:<#(id)predicate#>
	} else if (expressionType == NSFunctionExpressionType) {
	}
	return expression;
}

+ (NSPredicate *)rebuildWithNaturalComprisonPredicates:(NSPredicate *)predicate {
	if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
		NSCompoundPredicate *compoundPredicate = (id) predicate;
		NSMutableArray *newSubpredicates = [NSMutableArray arrayWithCapacity:[[compoundPredicate subpredicates] count]];
		
		for (NSPredicate *each in [compoundPredicate subpredicates]) {
			[newSubpredicates addObject:[self rebuildWithNaturalComprisonPredicates:each]];
		}
			
		return [[[NSCompoundPredicate alloc] initWithType:[compoundPredicate compoundPredicateType] subpredicates:newSubpredicates] autorelease];
	} else if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
		NSComparisonPredicate *comparisonPredicate = (id) predicate;
		NSPredicateOperatorType predicateOperatorType = [comparisonPredicate predicateOperatorType];
		NSExpression *leftExpression = [self rebuildExpressionWithNaturalComprisonPredicates:[comparisonPredicate leftExpression]];
		NSExpression *rightExpression = [self rebuildExpressionWithNaturalComprisonPredicates:[comparisonPredicate rightExpression]];

		if (predicateOperatorType == NSEqualToPredicateOperatorType ||
			predicateOperatorType == NSLessThanPredicateOperatorType ||
			predicateOperatorType == NSLessThanOrEqualToPredicateOperatorType ||
			predicateOperatorType == NSGreaterThanPredicateOperatorType ||
			predicateOperatorType == NSGreaterThanOrEqualToPredicateOperatorType) {
			
			return [[[NaturalComparisonPredicate alloc]
					 initWithLeftExpression:leftExpression
					 rightExpression:rightExpression
					 modifier:[comparisonPredicate comparisonPredicateModifier]
					 type:[comparisonPredicate predicateOperatorType]
					 options:[comparisonPredicate options]] autorelease];
		} else {
			return [[[NSComparisonPredicate alloc]
					 initWithLeftExpression:leftExpression
					 rightExpression:rightExpression
					 modifier:[comparisonPredicate comparisonPredicateModifier]
					 type:[comparisonPredicate predicateOperatorType]
					 options:[comparisonPredicate options]] autorelease];
		}
	}
	return predicate;
}

- (BOOL)evaluateWithObject:(id)object substitutionVariables:(NSDictionary *)variables {
	NSPredicateOperatorType operatorType = [self predicateOperatorType];
	NSString *leftValue = [[self leftExpression] expressionValueWithObject:object context:nil];
	NSString *rightValue = [[self rightExpression] expressionValueWithObject:object context:nil];
	
	if ([leftValue isKindOfClass:[NSString class]] && [rightValue isKindOfClass:[NSString class]]) {
		NSComparisonResult result = [leftValue naturalCompare:rightValue];

		switch (operatorType) {
			case NSEqualToPredicateOperatorType:
				return result == NSOrderedSame;
				
			case NSLessThanPredicateOperatorType:
				return result == NSOrderedAscending;
				
			case NSLessThanOrEqualToPredicateOperatorType:
				return result == NSOrderedAscending || result == NSOrderedSame;
				
			case NSGreaterThanPredicateOperatorType:
				return result == NSOrderedDescending;
				
			case NSGreaterThanOrEqualToPredicateOperatorType:
				return result == NSOrderedDescending || result == NSOrderedSame;
                
            default:
                return NO;
		}
	}
	
	return [super evaluateWithObject:object substitutionVariables:variables];
}

@end
