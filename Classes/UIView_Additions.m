//
//  UIView_Additions.m
// PlainText
//
//  Created by Jesse Grosjean on 6/30/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "UIView_Additions.h"
#import "NSObject_Additions.h"

/*
@implementation CALayer (Additions)

+ (void)load {
    if (self == [CALayer class]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[CALayer replaceMethod:@selector(display) withMethod:@selector(my_display)];
		[pool release];
    }
}

- (void)my_display {
	if (self.frame.size.height == 21.0000000) {
		NSLog(@"");
	}
	[self my_display];
}

@end
*/

@interface UIView (AdditionsPrivate)
- (UIEdgeInsets)padding;
@end


@implementation UIView (Additions)

- (NSArray *)allMySubviews {
	NSMutableArray *array = [NSMutableArray array];
	[array addObject:self];
	for (UIView *each in self.subviews) {
		[array addObjectsFromArray:[each allMySubviews]];
	}
	return array;
}

- (UIView *)firstSubviewOfClass:(Class)aClass {
	for (UIView *each in self.subviews) {
		if ([each isKindOfClass:aClass]) {
			return each;
		} else {
			UIView *match = [each firstSubviewOfClass:aClass];
			if (match) {
				return match;
			}
		}
	}
	return nil;
}

- (NSString *)descriptionWithSubviews {
	NSMutableString *description = [NSMutableString string];
	UIView *superview = self.superview;
	
	while (superview) {
		[description appendString:@"\t"];
		superview = superview.superview;
	}
	
	[description appendFormat:@"%@", self];
	
	for (UIView *each in self.subviews) {
		[description appendFormat:@"\n%@", [each descriptionWithSubviews]];
	}
	
	return description;
}

- (UIEdgeInsets)ancestorPadding {
	UIView *each = self.superview;
	while (each != nil && ![each respondsToSelector:@selector(padding)]) {
		each = each.superview;
	}
	
	if (each) {
		return [each padding];
	}
	
	return UIEdgeInsetsZero;
}

- (void)my_setVisible:(BOOL)visible animated:(BOOL)animated {
	@try {
		SEL setVisibleAnimated = NSSelectorFromString([@"setVisible:" stringByAppendingString:@"animated:"]);
		NSMethodSignature *setVisibleAnimatedSignature = [[self class] instanceMethodSignatureForSelector:setVisibleAnimated];
		if (setVisibleAnimatedSignature) {
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:setVisibleAnimatedSignature];
			[invocation setSelector:setVisibleAnimated];
			[invocation setTarget:self];
			[invocation setArgument:&visible atIndex:2];
			[invocation setArgument:&animated atIndex:3];
			[invocation invoke];
		}
	} @catch (NSException *e) {
		NSLog(@"Private API go boom %@", e);
	}
}

- (void)removeSelfAndSubviewAnimations {
	[self.layer removeAllAnimations];
	
	for (UIView *each in self.subviews) {
		[each removeSelfAndSubviewAnimations];
	}	
}

@end
