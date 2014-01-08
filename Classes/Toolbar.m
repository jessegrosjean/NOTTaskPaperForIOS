//
//  Toolbar.m
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//

#import "Toolbar.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "BrowserView.h"

@implementation Toolbar

+ (UIView *)flexibleSpace {
	UIView *result = [[[UIView alloc] init] autorelease];
	result.hidden = YES;
	result.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	return result;
}

- (id)init {
	self = [super init];
	self.drawTopDivider = YES;
	return self;
}

- (void)dealloc {
	[toolbarItems release];
	[super dealloc];
}

@synthesize toolbarItems;

- (void)setToolbarItems:(NSArray *)items {
	if (toolbarItems) {
		[toolbarItems makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	
	[toolbarItems autorelease];
	toolbarItems = [items retain];
	
	if (toolbarItems) {
		for (UIButton *each in toolbarItems) {
			[self addSubview:each];
		}
	}
	
	if ([toolbarItems count] > 0) {
		UIButton *left = [toolbarItems objectAtIndex:0];
		leftWidth = left.frame.size.width;
		leftInsets = left.imageEdgeInsets;
		UIButton *right = [toolbarItems lastObject];
		rightWidth = right.frame.size.width;
		rightInsets = right.imageEdgeInsets;
	}
}

- (void)setToolbarItems:(NSArray *)items animated:(BOOL)animated {
	BOOL hadItems = [toolbarItems count] > 0;
	BOOL hasItems = [items count] > 0;
	
	self.toolbarItems = items;
	
	if (animated) {
		CATransition *toolbarAnimation = [CATransition animation];
		[toolbarAnimation setDuration:BROWSER_ANIMATION_DURATION];
		[toolbarAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		
		if (hadItems && hasItems) {
			[toolbarAnimation setType:kCATransitionFade];
		} else if (hadItems) {
			[toolbarAnimation setType:kCATransitionReveal];
			[toolbarAnimation setSubtype:kCATransitionFromBottom];
		} else if (hasItems) {
			[toolbarAnimation setType:kCATransitionMoveIn];
			[toolbarAnimation setSubtype:kCATransitionFromTop];
		} else {
			toolbarAnimation = nil;
		}
		
		if (toolbarAnimation) {
			[self.layer addAnimation:toolbarAnimation forKey:@"ToolbarTransition"];
		}
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];

	UIButton *leftButton = nil;
	UIButton *rightButton = nil;
	CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, padding);
	CGFloat availibleWidth = bounds.size.width;
	NSUInteger flexible = 0;
	
	if ([toolbarItems count] > 0) {
		leftButton = [toolbarItems objectAtIndex:0];
		rightButton = [toolbarItems lastObject];
	}
	
	for (UIView *each in toolbarItems) {
		if ((each.autoresizingMask & UIViewAutoresizingFlexibleWidth) != 0) {
			flexible++;
		} else {
			if (each == leftButton) {
				availibleWidth -= leftWidth; 
			} else if (each == rightButton) {
				availibleWidth -= rightWidth; 
			} else {
				availibleWidth -= each.frame.size.width; 
			}
		}
	}
    
	CGFloat spacing = floorf(availibleWidth / (CGFloat) flexible);
	CGFloat offset = bounds.origin.x;
	
	for (UIView *each in toolbarItems) {
		if ((each.autoresizingMask & UIViewAutoresizingFlexibleWidth) != 0) {
			offset += spacing;
		} else {
			CGRect eachFrame = each.frame;
			
			if (each == leftButton) {
				eachFrame.size.width = leftWidth; 
			} else if (each == rightButton) {
				eachFrame.size.width = rightWidth; 
			}

			eachFrame.origin.x = offset;
			eachFrame.origin.y = 0;
			eachFrame.size.height = bounds.size.height;
			each.frame = CGRectIntegral(eachFrame);
			offset += each.frame.size.width;
        }
	}
    
    if (!IS_IPAD) {
        if ([toolbarItems count] > 1) {
            UIButton *leftButton = [toolbarItems objectAtIndex:0];
            CGRect leftFrame = CGRectZero;
            UIEdgeInsets leftImageEdgeInsets = leftInsets;
            CGRectDivide(bounds, &leftFrame, &bounds, leftWidth, CGRectMinXEdge);
            leftFrame.origin.x = 0;
            leftFrame.size.width += padding.left;
            leftButton.frame = CGRectIntegral(leftFrame);
            leftImageEdgeInsets.left += padding.left;
            leftButton.imageEdgeInsets = leftImageEdgeInsets;
                    
            UIButton *rightButton = [toolbarItems lastObject];
            CGRect rightFrame = CGRectZero;
            UIEdgeInsets rightImageEdgeInsets = rightInsets;
            CGRectDivide(bounds, &rightFrame, &bounds, rightWidth, CGRectMaxXEdge);
            rightFrame.size.width += padding.right;
            rightFrame.origin.x = CGRectGetMaxX(self.bounds) - rightFrame.size.width;
            rightButton.frame = CGRectIntegral(rightFrame);
            rightImageEdgeInsets.right += padding.right;
            rightButton.imageEdgeInsets = rightImageEdgeInsets;
        }
    }
	
	for (UIView *each in toolbarItems) {
		[each.layer removeAllAnimations];
	}	
}

@end
