//
//  SyncSpinnerView.m
//  PlainText
//
//  Created by Jesse Grosjean on 5/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SyncSpinnerView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "UIImage_Additions.h"

@implementation SyncSpinnerView

- (void)refreshFromDefaults {
	NSArray *images = self.animationImages;
	NSMutableArray *colorizedImages = [NSMutableArray arrayWithCapacity:[images count]];
	for (UIImage *each in images) {
		[colorizedImages addObject:[UIImage colorizeImage:each color:[APP_VIEW_CONTROLLER inkColorByPercent:0.15]]];
	}
	self.animationImages = colorizedImages;
	self.highlightedAnimationImages = colorizedImages;
}

- (id)init {
    self = [super init];
    if (self) {
		self.animationImages = [NSArray arrayWithObjects:
								[UIImage imageNamed:@"spinner0.png"],
								[UIImage imageNamed:@"spinner1.png"],
								[UIImage imageNamed:@"spinner2.png"],
								[UIImage imageNamed:@"spinner3.png"],
								[UIImage imageNamed:@"spinner4.png"],
								[UIImage imageNamed:@"spinner5.png"],
								[UIImage imageNamed:@"spinner6.png"],
								[UIImage imageNamed:@"spinner7.png"],
								[UIImage imageNamed:@"spinner8.png"], nil];
		self.animationDuration = 0.75;
		[self sizeToFit];
		[self refreshFromDefaults];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
	BOOL isAnimating = self.isAnimating;
	[super setHighlighted:highlighted];
	if (isAnimating) {
		[self startAnimating];
	}
}

- (void)dealloc {
    [super dealloc];
}

@end
