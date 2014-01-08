//
//  ScrollViewWithMargins.h
//  MarginsTest
//
//  Created by Jesse Grosjean on 10/27/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@class ItemViewController;
@class GradientFadeView;
@class MarginScrollView;
@class ScrollerView;
@class Titlebar;
@class Toolbar;
@class Searchbar;

@interface BrowserView : UIView <UITextViewDelegate, UIScrollViewDelegate, UITableViewDelegate> {
	UIEdgeInsets padding;
	UIButton *statusBarReplacement;
	Titlebar *titlebar;
    Searchbar *searchbar;
	BOOL headerBarsScroll;
	GradientFadeView *headerBarsGradientFadeView;
	Toolbar *toolbar;
	GradientFadeView *toolbarGradientFadeView;
	UIScrollView *contentView;
	UIView *contentWrapper;
	BOOL isPrimaryBrowser;
	BOOL performingScrollAnimation;
	BOOL isPerformingLayout;
	ScrollerView *scrollerView;
	MarginScrollView *leftMarginScrollView;
	MarginScrollView *rightMarginScrollView;
	id <UITextViewDelegate, UIScrollViewDelegate, UITableViewDelegate> originalContentViewDelegate;
	ItemViewController *currentViewController;
	CATransition *pushAnimation;
	CATransition *popAnimation;
	UILabel *statusLabel;
}

#pragma mark -
#pragma mark Attributes

@property (nonatomic, assign) UIEdgeInsets padding;
@property (nonatomic, retain) Titlebar *titlebar;
@property (nonatomic, retain) Searchbar *searchbar;
@property (nonatomic, assign) BOOL headerBarsScroll;
@property (nonatomic, retain) Toolbar *toolbar;
@property (nonatomic, readonly) UILabel *statusLabel;
@property (nonatomic, retain) UIScrollView *contentView;
@property (nonatomic, readonly) UIScrollView *activeScrollView;
@property (nonatomic, assign) BOOL isPrimaryBrowser;
@property (nonatomic, readonly) BOOL performingScrollAnimation;

#pragma mark -
#pragma mark Current View Controller

@property (nonatomic, readonly) ItemViewController *currentViewController;
- (void)setViewController:(ItemViewController *)aViewController editingPath:(BOOL)editing animated:(BOOL)animated isPush:(BOOL)isPush;

@end
