//
//  ViewController.m
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "ViewController.h"
#import "ApplicationViewController.h"
#import "BrowserViewController.h"


@implementation ViewController

- (void)dealloc {
	[view release];
	[title release];
	parentViewController = nil;
	[super dealloc];
}

@synthesize view;

- (UIView *)view {
	if (!view) {
		[self loadView];
	}
	return view;
}

@synthesize title;

- (void)setTitle:(NSString *)aTitle {
	if (![title isEqualToString:aTitle]) {
		[title autorelease];
		title = [aTitle retain];
		self.browserViewController.title = title;
	}
}

- (NSArray *)toolbarItems {
	return nil;
}

@synthesize parentViewController;

- (BrowserViewController *)browserViewController {
	ViewController *each = self.parentViewController;
	while (each) {
		if ([each isKindOfClass:[BrowserViewController class]]) {
			return (id) each;
		}
		each = each.parentViewController;
	}
	return nil;
}

- (void)loadView {
	self.view = [[[UIView alloc] init] autorelease];
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidLoad {
    
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return YES;
}

@end
