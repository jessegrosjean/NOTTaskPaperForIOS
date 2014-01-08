//
//  UITextView_Additions.m
//  PlainText
//
//  Created by Jesse Grosjean on 10/29/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "UITextView_Additions.h"
#import "NSObject_Additions.h"


@implementation UITextView (Additions)

+ (void)load {
    if (self == [UITableView class]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[pool release];
    }
}

- (void)myMakeSelectionWithPoint:(CGPoint)aPoint {
	id target = self;
	SEL setSelectionWithPoint = NSSelectorFromString([@"setSelection" stringByAppendingString:@"WithPoint:"]);
	NSMethodSignature *methodSignature = [[target class] instanceMethodSignatureForSelector:setSelectionWithPoint];
	
	if (!methodSignature) {
		// Updated for iOS 4.2
        @try {
            target = [self valueForKey:[@"m_w" stringByAppendingString:@"ebView"]];
            methodSignature = [[target class] instanceMethodSignatureForSelector:setSelectionWithPoint];
        } @catch (NSException *e) {
            methodSignature = nil;
        }
	}
	
	if (methodSignature) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
		[invocation setSelector:setSelectionWithPoint];
		[invocation setTarget:target];
		[invocation setArgument:&aPoint atIndex:2];
		[invocation invoke];
	} else {
		self.selectedRange = NSMakeRange([self.text length], 0);
	}
}

- (CGRect)myRectForSelection:(NSRange)aRange {
	SEL rectForSelection = NSSelectorFromString([@"rectFor" stringByAppendingString:@"Selection:"]);
	NSMethodSignature *methodSignature = [[self class] instanceMethodSignatureForSelector:rectForSelection];
	if (methodSignature) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
		[invocation setSelector:rectForSelection];
		[invocation setTarget:self];
		[invocation setArgument:&aRange atIndex:2];
		[invocation invoke];
		CGRect rect;
		[invocation getReturnValue:&rect];
		return rect;
	} else {
		return self.bounds;
	}
}

- (void)myHighlightRange:(NSRange)aRange {
	UIView *v = [self viewWithTag:101];
	if (!v) {
		v = [[UIView alloc] init];
		v.backgroundColor = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.5];
		v.opaque = NO;
		v.tag = 101;
		[self addSubview:v];		
	}
	CGRect r1 = [self myRectForSelection:NSMakeRange(aRange.location, 0)];
	CGRect r2 = [self myRectForSelection:NSMakeRange(NSMaxRange(aRange), 0)];
	v.frame = CGRectUnion(r1, r2);
}

- (UIView *)myGetKeyboardInstance {
	Class keyboardClass = NSClassFromString([@"UIKey" stringByAppendingString:@"boardImpl"]);
	SEL activeInstance = NSSelectorFromString([@"active" stringByAppendingString:@"Instance"]);
	NSMethodSignature *methodSignature = [keyboardClass methodSignatureForSelector:activeInstance];
	id keyboard = nil;
	
	if (methodSignature) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
		[invocation setSelector:activeInstance];
		[invocation setTarget:keyboardClass];
		[invocation invoke];
		[invocation getReturnValue:&keyboard];
	}
	
	return keyboard;
}

- (void)myAcceptAutocorrection {
	Class keyboardClass = NSClassFromString([@"UIKey" stringByAppendingString:@"boardImpl"]);
	SEL activeInstance = NSSelectorFromString([@"active" stringByAppendingString:@"Instance"]);
	NSMethodSignature *methodSignature = [keyboardClass methodSignatureForSelector:activeInstance];
	if (methodSignature) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
		[invocation setSelector:activeInstance];
		[invocation setTarget:keyboardClass];
		[invocation invoke];
		id keyboard = nil;
		[invocation getReturnValue:&keyboard];
		if (keyboard) {
			SEL acceptAutocorrection = NSSelectorFromString([@"accept" stringByAppendingString:@"Autocorrection"]);
			methodSignature = [keyboardClass instanceMethodSignatureForSelector:acceptAutocorrection];
			if (methodSignature) {
				invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
				[invocation setSelector:acceptAutocorrection];
				[invocation setTarget:keyboard];
				[invocation invoke];
			}			
		}
	}
	
	//id keyboard = [ activeInstance];
	//[keyboard acceptAutocorrection];
}

- (void)adjustForTypewriterScrolling {
	CGRect r = [self myRectForSelection:self.selectedRange];
	CGPoint p = [self contentOffset];
	p.y = (NSInteger) (CGRectGetMinY(r) + (r.size.height / 2.0) - (self.bounds.size.height / 2.0));
	[self setContentOffset:p animated:NO];
	
	//[[[self myGetKeyboardInstance] window] setAlpha:0.1];
}

@end