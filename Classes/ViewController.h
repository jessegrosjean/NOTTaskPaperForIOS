//
//  ViewController.h
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//


@class BrowserViewController;

@interface ViewController : NSObject {
	UIView *view;
	NSString *title;
	//NSArray *toolbarItems;
	ViewController *parentViewController;
}

@property (nonatomic, retain) UIView *view;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, readonly) NSArray *toolbarItems;
@property (nonatomic, assign) ViewController *parentViewController;
@property (nonatomic, readonly) BrowserViewController *browserViewController;

- (void)loadView;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;
- (void)viewDidLoad;
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender;

@end
