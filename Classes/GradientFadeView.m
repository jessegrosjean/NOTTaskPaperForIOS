//
//  GradientFadeView.m
// PlainText
//
//  Created by Jesse Grosjean on 6/29/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "GradientFadeView.h"
#import "ApplicationViewController.h"


@implementation GradientFadeView

- (void)refreshFromDefaults {
	[self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)aFrame {
	self = [super initWithFrame:aFrame];
	self.userInteractionEnabled = NO;
	self.opaque = NO;
	[self refreshFromDefaults];
	return self;
}

@synthesize flipped;

- (void)didMoveToWindow {
	[super didMoveToWindow];
	[self setNeedsDisplay];
}

- (void)setHidden:(BOOL)hidden {
	[super setHidden:hidden];
	if (!hidden) {
		[self setNeedsDisplay];
	}
}

- (void)drawRect:(CGRect)aRect {
	if (flipped) {
		DrawFadeFunction(UIGraphicsGetCurrentContext(), self.bounds, [self.superview.backgroundColor CGColor], 1.571);
	} else {
		DrawFadeFunction(UIGraphicsGetCurrentContext(), self.bounds, [self.superview.backgroundColor CGColor], -1.571);
	}
}

@end
