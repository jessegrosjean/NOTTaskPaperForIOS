//
//  Bar.m
//  PlainText
//
//  Created by Jesse Grosjean on 10/14/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "Bar.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"

@implementation Bar

- (void)refreshFromDefaults {
	topDivider.backgroundColor = [APP_VIEW_CONTROLLER inkColorByPercent:0.8];
	bottomDivider.backgroundColor = [APP_VIEW_CONTROLLER inkColorByPercent:0.8];
	[self setNeedsLayout];
	[self setNeedsDisplay];
	[self sizeToFit];
}

- (id)init {
	self = [super init];

	self.opaque = YES;
	
	topDivider = [[[UIView alloc] init] autorelease];
	topDivider.userInteractionEnabled = NO;
	topDivider.hidden = YES;
	[self addSubview:topDivider];
	
	bottomDivider = [[[UIView alloc] init] autorelease];
	bottomDivider.userInteractionEnabled = NO;
	bottomDivider.hidden = YES;
	[self addSubview:bottomDivider];
    
	[self refreshFromDefaults];

	return self;
}

@synthesize padding;

- (void)setPadding:(UIEdgeInsets)newPadding {
	padding = newPadding;
	[self setNeedsLayout];
}

- (BOOL)drawTopDivider {
	return !topDivider.hidden;
}

- (void)setDrawTopDivider:(BOOL)aBool {
	topDivider.hidden = !aBool;
}

- (BOOL)drawBottomDivider {
	return !bottomDivider.hidden;
}

- (void)setDrawBottomDivider:(BOOL)aBool {
	bottomDivider.hidden = !aBool;
}

- (CGSize)sizeThatFits:(CGSize)size {
	CGFloat height = roundf([APP_VIEW_CONTROLLER leading] * 2);
	return CGSizeMake(size.width, height);
}

- (void)setFrame:(CGRect)aFrame {
	[super setFrame:aFrame];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, padding);
	topDivider.frame = CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, 1.0);
	bottomDivider.frame = CGRectMake(bounds.origin.x, CGRectGetMaxY(bounds) - 1.0 + padding.bottom, bounds.size.width, 1.0);
	[self bringSubviewToFront:topDivider];
	[self bringSubviewToFront:bottomDivider];
}

- (void)drawRect:(CGRect)rect {
	[self.superview.backgroundColor set];
	UIRectFill(rect);
	
	if (DEBUG_DRAWING) {
		CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(0, 0, 0, padding.right)); // space for scroller to show through
		[[UIColor redColor] set];
		UIRectFrame(self.bounds);
		[[UIColor greenColor] set];
		UIRectFrame(bounds);
	}	
}

@end
