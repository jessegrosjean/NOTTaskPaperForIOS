//
//  ScrollViewWithMargins.m
//  MarginsTest
//
//  Created by Jesse Grosjean on 10/27/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "BrowserView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "PathViewController.h"
#import "ItemViewController.h"
#import "NSObject_Additions.h"
#import "NSString_Additions.h"
#import "GradientFadeView.h"
#import "MarginScrollView.h"
#import "UIView_Additions.h"
#import "PathViewWrapper.h"
#import "ScrollerView.h"
#import "PathView.h"
#import "Titlebar.h"
#import "Toolbar.h"
#import "Button.h"
#import "Searchbar.h"
#import "SearchViewController.h"
#import "SearchView.h"

@interface BrowserView (Private)
- (void)updateTitleBarDrawBottomDivider;
@end

@implementation BrowserView

#pragma mark -
#pragma mark Init

- (void)refreshFromDefaults {
	if (IS_IPAD && isPrimaryBrowser) {
		self.backgroundColor = [APP_VIEW_CONTROLLER inkColorByPercent:0.03];
	} else {
		self.backgroundColor = [APP_VIEW_CONTROLLER paperColor];
	}    	    
	[self setNeedsLayout];
}

- (id)init {
	self = [super init];
	self.headerBarsScroll = YES;
	
	[self refreshFromDefaults];
	
	contentWrapper = [[[UIView alloc] init] autorelease];
	contentWrapper.autoresizesSubviews = YES;
	contentWrapper.clipsToBounds = YES;
	contentWrapper.userInteractionEnabled = YES;
	
	[self addSubview:contentWrapper];

    self.searchbar = [[[Searchbar alloc] init] autorelease];
	self.titlebar = [[[Titlebar alloc] init] autorelease];
	self.toolbar = [[[Toolbar alloc] init] autorelease];
	
	toolbar.hidden = YES;
	
	headerBarsGradientFadeView = [[[GradientFadeView alloc] init] autorelease];
	[self addSubview:headerBarsGradientFadeView];
	
	toolbarGradientFadeView = [[[GradientFadeView alloc] init] autorelease];
	toolbarGradientFadeView.flipped = YES;
	[self addSubview:toolbarGradientFadeView];
	
	if (!scrollerView) {
		scrollerView = [[[ScrollerView alloc] initWithFrame:self.bounds] autorelease];
		[self addSubview:scrollerView];
	}
    
	return self;
}

- (void)shrinkButtons {
    for (UIView *toolbarButton in self.toolbar.toolbarItems) {
        if ([toolbarButton isKindOfClass:[Button class]]) {
            [((Button *)toolbarButton) performSelector:@selector(pressShrink) withObject:nil];
        }
    }
}

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)gestureRecognizer {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DocumentFocusModeDefaultsKey]) {
        [APP_VIEW_CONTROLLER.view performSelector:@selector(toggleDocumentFocusMode:) withObject:nil];
        [self shrinkButtons];
    }
}

- (void)handleSwipeLeft:(UISwipeGestureRecognizer *)gestureRecognizer {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:DocumentFocusModeDefaultsKey]) {
        [APP_VIEW_CONTROLLER.view performSelector:@selector(toggleDocumentFocusMode:) withObject:nil];
        [self shrinkButtons];
    }
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[originalContentViewDelegate release];
	contentView.delegate = nil;
	leftMarginScrollView.delegate = nil;
	rightMarginScrollView.delegate = nil;
	[contentView release];
	[super dealloc];
}

#pragma mark -
#pragma mark Attributes

@synthesize padding;

- (void)setPadding:(UIEdgeInsets)insets {
	padding = insets;
	[self setNeedsLayout];
}

@synthesize titlebar;

- (void)setTitlebar:(Titlebar *)aTitlebar {
	[titlebar removeFromSuperview];
	titlebar = aTitlebar;
	[self addSubview:titlebar];
}

@synthesize searchbar;

- (void)setSearchbar:(Searchbar *)aSearchbar {
	[searchbar removeFromSuperview];
	searchbar = aSearchbar;
	[self addSubview:searchbar];
}

@synthesize headerBarsScroll;

- (void)setHeaderBarsScroll:(BOOL)aBool {
	headerBarsScroll = aBool;
	[self setNeedsLayout];
	[self updateTitleBarDrawBottomDivider];
}

@synthesize toolbar;

- (void)setToolbar:(Toolbar *)aToolbar {
	[toolbar removeFromSuperview];
	toolbar = aToolbar;
	[self addSubview:toolbar];
    
    UISwipeGestureRecognizer *recognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)] autorelease];
    recognizer.numberOfTouchesRequired = 1;
    [toolbar addGestureRecognizer:recognizer];
    
    
    recognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)] autorelease];
    [recognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    recognizer.numberOfTouchesRequired = 1;
    [toolbar addGestureRecognizer:recognizer];

}

- (UILabel *)statusLabel {
	if (!statusLabel) {
		statusLabel = [[[UILabel alloc] init] autorelease];
		statusLabel.userInteractionEnabled = NO;
		statusLabel.opaque = NO;
		statusLabel.backgroundColor = nil;//[UIColor clearColor];
		statusLabel.text = @"1234 words";
		statusLabel.textColor = [APP_VIEW_CONTROLLER inkColorByPercent:0.15];
		[self addSubview:statusLabel];
	}
	return statusLabel;
}
- (UIScrollView *)contentView {
	return contentView;
}

- (void)setContentView:(UIScrollView *)aView {
	contentView.delegate = originalContentViewDelegate;
	[contentView removeFromSuperview];
	[originalContentViewDelegate release];
	originalContentViewDelegate = nil;	
    [contentView autorelease];
	contentView = [aView retain];
	
	if (contentView) {
		originalContentViewDelegate = (id)[contentView.delegate retain];
		contentView.delegate = self;
		contentView.showsVerticalScrollIndicator = NO;
		contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		contentView.frame = contentWrapper.bounds;

		if (IS_IPAD) {
			// Only created secondary scroll views on iPad, they hurt scrolling performance on iPhone.
			if (!leftMarginScrollView) {
				leftMarginScrollView = [[[MarginScrollView alloc] initWithFrame:self.bounds] autorelease];
				leftMarginScrollView.showsVerticalScrollIndicator = NO;
				leftMarginScrollView.delegate = self;
				if (DEBUG_DRAWING) {
					leftMarginScrollView.backgroundColor = [UIColor brownColor];
				}
				[self addSubview:leftMarginScrollView];
			}
			
			leftMarginScrollView.bounces = contentView.bounces;
			leftMarginScrollView.alwaysBounceVertical = contentView.alwaysBounceVertical;
			
			if (!rightMarginScrollView) {
				rightMarginScrollView = [[[MarginScrollView alloc] initWithFrame:self.bounds] autorelease];
				rightMarginScrollView.showsVerticalScrollIndicator = NO;
				rightMarginScrollView.delegate = self;
				if (DEBUG_DRAWING) {
					rightMarginScrollView.backgroundColor = [UIColor brownColor];
				}			
				[self addSubview:rightMarginScrollView];
			}
			
			rightMarginScrollView.bounces = contentView.bounces;
			rightMarginScrollView.alwaysBounceVertical = contentView.alwaysBounceVertical;
		}
		
		[contentWrapper addSubview:contentView];
		
		[scrollerView updateScrollerViewFromScrollView:contentView fadeInPossible:NO];
	}
	
	[self setNeedsLayout];
}

- (UIScrollView *)activeScrollView {	
	if (contentView.tracking || contentView.dragging || contentView.decelerating) {
		return contentView;
	} else if (leftMarginScrollView.tracking || leftMarginScrollView.dragging || leftMarginScrollView.decelerating) {
		return leftMarginScrollView;
	} else if (rightMarginScrollView.tracking || rightMarginScrollView.dragging || rightMarginScrollView.decelerating) {
		return rightMarginScrollView;
	}
	
	return contentView;
}

@synthesize isPrimaryBrowser;

- (void)setIsPrimaryBrowser:(BOOL)aBool {
	isPrimaryBrowser = aBool;
	
	if (IS_IPAD) {
		if (isPrimaryBrowser) {
			self.backgroundColor = [APP_VIEW_CONTROLLER inkColorByPercent:0.03];
		}
	}	
}

@synthesize performingScrollAnimation;

#pragma mark -
#pragma mark Push/Pop views

- (CATransition *)pushAnimation {
	if (!pushAnimation) {
		pushAnimation = [[CATransition animation] retain];
		[pushAnimation setDuration:BROWSER_ANIMATION_DURATION];
		[pushAnimation setType:kCATransitionPush];
		[pushAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		[pushAnimation setSubtype:kCATransitionFromRight];
	}
	return pushAnimation;
}

- (CATransition *)popAnimation {
	if (!popAnimation) {
		popAnimation = [[CATransition animation] retain];
		[popAnimation setDuration:BROWSER_ANIMATION_DURATION];
		[popAnimation setType:kCATransitionPush];
		[popAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		[popAnimation setSubtype:kCATransitionFromLeft];
	}
	return popAnimation;
}

@synthesize currentViewController;

- (void)setViewController:(ItemViewController *)aViewController editingPath:(BOOL)editing animated:(BOOL)animated isPush:(BOOL)isPush {
	if (currentViewController == aViewController) return;
	
	[aViewController.view refreshSelfAndSubviewsFromDefaults];
	[aViewController.pathViewController.pathViewWrapper refreshSelfAndSubviewsFromDefaults];

	[currentViewController viewWillDisappear:animated];
	
	[titlebar setPathViewWrapper:aViewController.pathViewController.pathViewWrapper becomeFirstResponder:editing];
    [searchbar setSearchView:aViewController.searchViewController.searchView];
	
	CATransition *animation = nil;
	if (animated) {
		animation = isPush ? [self pushAnimation] : [self popAnimation];
		[[titlebar layer] addAnimation:animation forKey:@"SwitchTitleBar"];
        [[searchbar layer] addAnimation:animation forKey:@"SwitchSearchBar"];
	}
	
	[aViewController viewWillAppear:NO]; // animation only applies to sliding content views in and out. Don't want to actually animate the content of the view.
	
	self.contentView = (UIScrollView *) aViewController.view;
	
    if (aViewController) {
        if ([aViewController.view isKindOfClass:[UITextView class]]) {
            searchbar.hidden = YES;
        } else if (aViewController.searchViewController.searchView.text.length > 0) {
			searchbar.hidden = NO;
		} else {
            searchbar.hidden = YES;
        }
	} else {
		searchbar.hidden = YES;
	}

    
	NSArray *toolbarItems = aViewController.toolbarItems;
	BOOL hasToolbarItems = [toolbarItems count] > 0;
	if (hasToolbarItems == toolbar.hidden) {
		toolbar.hidden = !hasToolbarItems;
	}

	[toolbar setToolbarItems:toolbarItems animated:animated];
	
	if (animated) {
		[[contentWrapper layer] addAnimation:animation forKey:@"SwitchContentView"];
	}
	
	[currentViewController autorelease];
	currentViewController = [aViewController retain];
	[currentViewController saveOpenPathsState];

	[self updateTitleBarDrawBottomDivider];

	[self setNeedsLayout];
	[self layoutIfNeeded];
    
    [aViewController viewDidLoad];
}

#pragma mark -
#pragma mark Layout

- (void)updateTitleBarDrawBottomDivider {
	if (IS_IPAD) {
		if (!headerBarsScroll) {
			titlebar.drawBottomDivider = YES;
		} else {
			if (currentViewController) {
				if ([currentViewController.view isKindOfClass:[UITextView class]]) {
					titlebar.drawBottomDivider = NO;
				} else {
					titlebar.drawBottomDivider = YES;
				}
			}
		}
	}
}

- (void)statusBarReplacementTapped {
	UIScrollView *scrollView = [self contentView];
	if ([scrollView scrollsToTop]) {
		[scrollView setContentOffset:CGPointMake(0, -[scrollView contentInset].top) animated:YES];
	}
}

- (void)updateStatusBarReplacementUserInteractionStatus {
	if (statusBarReplacement) {
		if (CGRectGetMaxY(titlebar.frame) < CGRectGetMaxY(statusBarReplacement.frame)) {
			statusBarReplacement.userInteractionEnabled = YES;
		} else {
			statusBarReplacement.userInteractionEnabled = NO;
		}	
	}
}

- (void)layoutSubviews {	
	isPerformingLayout = YES;
	
	// 0. Don't want these guys firing did scrolled events durring layout.
	leftMarginScrollView.delegate = nil;
	rightMarginScrollView.delegate = nil;

	// 1. Calculate sizes
	CGRect bounds = self.bounds;
    
	CGFloat leading = [APP_VIEW_CONTROLLER leading];	
	CGFloat keyboardHeight = [APP_VIEW_CONTROLLER keyboardHeight];
	
	if (keyboardHeight > 0) {
		bounds.size.height -= (keyboardHeight - [APP_VIEW_CONTROLLER adsHeight]);		
		if (!IS_IPAD && !toolbar.hidden) {
			bounds.size.height += toolbar.frame.size.height;
		}
	}
	
	CGRect scrollerViewFrame = CGRectMake(CGRectGetMaxX(bounds) - 10, CGRectGetMinY(bounds), 10, CGRectGetHeight(bounds));

	UIEdgeInsets contentViewInset = UIEdgeInsetsZero;
	if ([contentView isKindOfClass:[UITextView class]]) {
		contentViewInset = UIEdgeInsetsMake((NSInteger)(leading / 4.0), 0, 32, 0);
	}
    
    if (!searchbar.hidden) {
        titlebar.hidden = YES;
    } else {
        titlebar.hidden = NO;
    }
	
	CGSize titlebarSize = CGSizeZero;
	if (!titlebar.hidden) {
		titlebarSize = [titlebar sizeThatFits:CGSizeMake(CGRectGetWidth(bounds), CGRectGetHeight(bounds))];
		titlebarSize.height += padding.top;
		titlebar.padding = UIEdgeInsetsMake(padding.top, padding.left, 0, padding.right);
		contentViewInset.top += titlebarSize.height;
	}
    
    CGSize searchbarSize = CGSizeZero;
	if (!searchbar.hidden) {
		searchbarSize = [searchbar sizeThatFits:CGSizeMake(CGRectGetWidth(bounds), CGRectGetHeight(bounds))];
        searchbarSize.height += padding.top;
		searchbar.padding = UIEdgeInsetsMake(padding.top, padding.left, 0, padding.right);
		contentViewInset.top += searchbarSize.height;
	}

	CGSize toolbarSize = CGSizeZero;
	if (!toolbar.hidden) {
		toolbarSize = [toolbar sizeThatFits:CGSizeMake(CGRectGetWidth(bounds), CGRectGetHeight(bounds))];
		toolbarSize.height += padding.bottom;
		toolbar.padding = UIEdgeInsetsMake(0, padding.left, padding.bottom, padding.right);
		contentViewInset.bottom += toolbarSize.height;
	}

	// 2. Position content view	and margin views
	UIScrollView *contentScrollViewView = self.contentView;
	if (contentScrollViewView) {
		if (!UIEdgeInsetsEqualToEdgeInsets(contentViewInset, contentScrollViewView.contentInset)) {
			contentScrollViewView.contentInset = contentViewInset;
			if (contentScrollViewView.contentOffset.y <= 0) {
				// Mostly handling case of initial load... making sure to scroll things so title bar is visible.
				contentScrollViewView.contentOffset = CGPointMake(0, -contentViewInset.top);
			}
		}
		
		CGRect contentWrapperViewFrame = CGRectMake(CGRectGetMinX(bounds) + padding.left, CGRectGetMinY(bounds), CGRectGetWidth(bounds) - (padding.left + padding.right), CGRectGetHeight(bounds));
		
		if ([contentScrollViewView isKindOfClass:[UITextView class]]) {
			contentWrapperViewFrame.origin.x -= 8;
			contentWrapperViewFrame.size.width += 16;
		}
		
		contentWrapperViewFrame = CGRectIntegral(contentWrapperViewFrame);		
		if (!CGRectEqualToRect(contentWrapper.frame, contentWrapperViewFrame)) {
			contentWrapper.frame = contentWrapperViewFrame;
		}
		
		// 2a. Left margin scroll view.
		CGSize leftContentSize = CGSizeMake(leftMarginScrollView.frame.size.width, contentScrollViewView.contentSize.height);
		if (!CGSizeEqualToSize(leftMarginScrollView.contentSize, leftContentSize)) {
			leftMarginScrollView.contentSize = leftContentSize;
		}
		
		if (!UIEdgeInsetsEqualToEdgeInsets(contentViewInset, leftMarginScrollView.contentInset)) {
			leftMarginScrollView.contentInset = contentViewInset;
		}
		
		CGRect leftMarginScrollViewFrame = CGRectMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds), padding.left, CGRectGetHeight(bounds));
		leftMarginScrollViewFrame = CGRectIntegral(leftMarginScrollViewFrame);		
		if (!CGRectEqualToRect(leftMarginScrollView.frame, leftMarginScrollViewFrame)) {
			leftMarginScrollView.frame = leftMarginScrollViewFrame;
		}
		
		[leftMarginScrollView.superview sendSubviewToBack:leftMarginScrollView];
		
		// 2b. Right margin scroll view.
		CGSize rightContentSize = CGSizeMake(rightMarginScrollView.frame.size.width, contentScrollViewView.contentSize.height);
		if (!CGSizeEqualToSize(rightMarginScrollView.contentSize, rightContentSize)) {
			rightMarginScrollView.contentSize = rightContentSize;
		}
		
		if (!UIEdgeInsetsEqualToEdgeInsets(contentViewInset, rightMarginScrollView.contentInset)) {
			rightMarginScrollView.contentInset = contentViewInset;
		}
		
		CGRect rightMarginScrollViewFrame = CGRectMake(CGRectGetMaxX(bounds) - padding.right, CGRectGetMinY(bounds), padding.right, CGRectGetHeight(bounds));
		rightMarginScrollViewFrame = CGRectIntegral(rightMarginScrollViewFrame);		
		if (!CGRectEqualToRect(rightMarginScrollView.frame, rightMarginScrollViewFrame)) {
			rightMarginScrollView.frame = rightMarginScrollViewFrame;
		}
		
		[rightMarginScrollView.superview sendSubviewToBack:rightMarginScrollView];
	}	
	
	// 3. Position header bars.
	CGPoint contentViewOffset = contentScrollViewView == nil ? CGPointZero : contentScrollViewView.contentOffset;
	CGFloat gradientFadeHeight = 8;
	CGRect titlebarFrame;
	
	if (!titlebar.hidden) {
		titlebarFrame = CGRectMake(CGRectGetMinX(bounds), 0, titlebarSize.width, titlebarSize.height);
		
		if (headerBarsScroll) {
			titlebarFrame.origin.y = (-contentViewOffset.y - contentViewInset.top);
			headerBarsGradientFadeView.hidden = YES;
		} else {
			CGRect headerBarsGradientFadeViewFrame = CGRectMake(padding.left, CGRectGetMaxY(titlebarFrame), bounds.size.width - (padding.left + padding.right), gradientFadeHeight);
			headerBarsGradientFadeViewFrame = CGRectIntegral(headerBarsGradientFadeViewFrame);		
			if (!CGRectEqualToRect(headerBarsGradientFadeView.frame, headerBarsGradientFadeViewFrame)) {
				headerBarsGradientFadeView.frame = headerBarsGradientFadeViewFrame;
			}
			
			scrollerViewFrame.origin.y += titlebarFrame.size.height;
			scrollerViewFrame.size.height -= titlebarFrame.size.height;
			headerBarsGradientFadeView.hidden = NO;
		}
        
		titlebarFrame = CGRectIntegral(titlebarFrame);
		if (!CGRectEqualToRect(titlebar.frame, titlebarFrame)) {
			titlebar.frame = titlebarFrame;
		}
	} else {
        CGRect searchbarFrame = CGRectMake(CGRectGetMinX(bounds), 0, searchbarSize.width, searchbarSize.height);
        
		if (headerBarsScroll) {
			searchbarFrame.origin.y = (-contentViewOffset.y - contentViewInset.top);
			headerBarsGradientFadeView.hidden = YES;
		} else {
			CGRect headerBarsGradientFadeViewFrame = CGRectMake(padding.left, CGRectGetMaxY(searchbarFrame), bounds.size.width - (padding.left + padding.right), gradientFadeHeight);
			headerBarsGradientFadeViewFrame = CGRectIntegral(headerBarsGradientFadeViewFrame);		
			if (!CGRectEqualToRect(headerBarsGradientFadeView.frame, headerBarsGradientFadeViewFrame)) {
				headerBarsGradientFadeView.frame = headerBarsGradientFadeViewFrame;
			}
			
			scrollerViewFrame.origin.y += searchbarFrame.size.height;
			scrollerViewFrame.size.height -= searchbarFrame.size.height;
			headerBarsGradientFadeView.hidden = NO;
		}
        		
		searchbarFrame = CGRectIntegral(searchbarFrame);		
		if (!CGRectEqualToRect(searchbar.frame, searchbarFrame)) {
			searchbar.frame = searchbarFrame;
		}
	}
	
	// 4. Position toolbar.
	if (!toolbar.hidden) {
		CGRect toolBarFrame = CGRectMake(CGRectGetMinX(bounds), CGRectGetMaxY(bounds) - toolbarSize.height, toolbarSize.width, toolbarSize.height);
		toolBarFrame = CGRectIntegral(toolBarFrame);		
		if (!CGRectEqualToRect(toolbar.frame, toolBarFrame)) {
			toolbar.frame = toolBarFrame;
		}

		scrollerViewFrame.size.height -= toolBarFrame.size.height;
        if (searchbar.hidden) {
            CGRect toolbarGradientFadeViewFrame = CGRectMake(CGRectGetMinX(toolBarFrame) + padding.left, CGRectGetMinY(toolBarFrame) - gradientFadeHeight, toolBarFrame.size.width - (padding.left + padding.right), gradientFadeHeight);
            toolbarGradientFadeViewFrame = CGRectIntegral(toolbarGradientFadeViewFrame);		
            if (!CGRectEqualToRect(toolbarGradientFadeView.frame, toolbarGradientFadeViewFrame)) {
                toolbarGradientFadeView.frame = toolbarGradientFadeViewFrame;
            }
            toolbarGradientFadeView.hidden = NO;
        }
	} else {
		toolbarGradientFadeView.hidden = YES;
	}
	
	if (!IS_IPAD && APP_VIEW_CONTROLLER.isClosingKeyboard) {
		[toolbar.layer removeAllAnimations];
	}
	
	// 5. Position scroller
	if (scrollerView) {
		scrollerViewFrame = CGRectIntegral(scrollerViewFrame);		
		if (!CGRectEqualToRect(scrollerView.frame, scrollerViewFrame)) {
			scrollerView.frame = scrollerViewFrame;
		}
	}
    	
	// 6. Position status bar replacement
	if ([[UIApplication sharedApplication] isStatusBarHidden]) {
		if (!statusBarReplacement) {
			statusBarReplacement = [UIButton buttonWithType:UIButtonTypeCustom];
			[statusBarReplacement addTarget:self action:@selector(statusBarReplacementTapped) forControlEvents:UIControlEventTouchUpInside];
			statusBarReplacement.accessibilityLabel = NSLocalizedString(@"Scroll to Top", nil);
			[self addSubview:statusBarReplacement];
		}
		
		CGRect statusBarFrame = bounds;
		statusBarFrame.size.height = 20;
		statusBarReplacement.frame = statusBarFrame;

		[self updateStatusBarReplacementUserInteractionStatus];
	} else {
		[statusBarReplacement removeFromSuperview];
		statusBarReplacement = nil;
	}
	
	// 6. Position status label
	/*if (self.statusLabel) {
		[statusLabel sizeToFit];
		
		CGRect statusFrame = statusLabel.frame;
		statusFrame.origin.x = CGRectGetMinX(bounds) + (leading / 2);
		statusFrame.origin.y = CGRectGetMaxY(bounds) - ((statusFrame.size.height * 1.5) + (leading / 2.0));
		statusFrame = CGRectIntegral(statusFrame);
		statusLabel.frame = statusFrame;
		[self bringSubviewToFront:statusLabel];
	}*/
	
	// 6. Sign up for scrolled events again
	leftMarginScrollView.delegate = self;
	rightMarginScrollView.delegate = self;
		
	isPerformingLayout = NO;
}

#pragma mark -
#pragma mark MarginScrollView tap detection

- (void)singleTapInMargin:(MarginScrollView *)aMargin yLocation:(CGFloat)yLocation {
	if ([self.contentView respondsToSelector:@selector(singleTapInMarginLocation:isLeftMargin:)]) {
		[(id)self.contentView singleTapInMarginLocation:yLocation isLeftMargin:aMargin == leftMarginScrollView];
	}
}

- (void)doubleTapInMargin:(MarginScrollView *)aMargin yLocation:(CGFloat)yLocation {	
	if ([self.contentView respondsToSelector:@selector(doubleTapInMarginLocation:isLeftMargin:)]) {
		[(id)self.contentView doubleTapInMarginLocation:yLocation isLeftMargin:aMargin == leftMarginScrollView];
	}
}

#pragma mark -
#pragma mark Keyboard delegate

- (void)didMoveToSuperview {
	[super didMoveToSuperview];
	if ([self superview]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:KeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:KeyboardWillHideNotification object:nil];
	} else {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:KeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:KeyboardWillHideNotification object:nil];
	}
}

- (void)keyboardWillShow:(NSNotification *)aNotification {
	[self setNeedsLayout];
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
	[self setNeedsLayout];
}

#pragma mark -
#pragma mark ScrollView Delegate;

- (void)updateScrollViews:(UIScrollView *)master dependent1:(UIScrollView *)dependent1 dependent2:(UIScrollView *)dependent2 {
	CGPoint contentOffset = master.contentOffset;
	
	if (master && (master.tracking || master.decelerating || scrollerView.tracking)) {
		[scrollerView updateScrollerViewFromScrollView:master fadeInPossible:!isPerformingLayout];
	}
	
	if (dependent1.decelerating) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0];
		[dependent1 setContentOffset:contentOffset animated:YES];
		[UIView commitAnimations];
	} else {
		dependent1.contentOffset = contentOffset;
	}

	if (dependent2.decelerating) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0];
		[dependent2 setContentOffset:contentOffset animated:YES];
		[UIView commitAnimations];
	} else {
		dependent2.contentOffset = contentOffset;
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
			[originalContentViewDelegate scrollViewDidScroll:scrollView];
		}
	}
	
	if (contentView.tracking) {
		[self updateScrollViews:contentView dependent1:leftMarginScrollView dependent2:rightMarginScrollView];
	} else if (leftMarginScrollView.tracking) {
		[self updateScrollViews:leftMarginScrollView dependent1:contentView dependent2:rightMarginScrollView];
	} else if (rightMarginScrollView.tracking) {
		[self updateScrollViews:rightMarginScrollView dependent1:leftMarginScrollView dependent2:contentView];
	
	} else if (contentView.decelerating) {
		[self updateScrollViews:contentView dependent1:leftMarginScrollView dependent2:rightMarginScrollView];
	} else if (leftMarginScrollView.decelerating) {
		[self updateScrollViews:leftMarginScrollView dependent1:contentView dependent2:rightMarginScrollView];
	} else if (rightMarginScrollView.decelerating) {
		[self updateScrollViews:rightMarginScrollView dependent1:leftMarginScrollView dependent2:contentView];
		
	} else if (contentView == scrollView) {
		[self updateScrollViews:contentView dependent1:leftMarginScrollView dependent2:rightMarginScrollView];
	} else if (leftMarginScrollView == scrollView) {
		[self updateScrollViews:leftMarginScrollView dependent1:contentView dependent2:rightMarginScrollView];
	} else if (rightMarginScrollView == scrollView) {
		[self updateScrollViews:rightMarginScrollView dependent1:leftMarginScrollView dependent2:contentView];
	}
		
	if (headerBarsScroll) {
		UIEdgeInsets contentViewInset = self.contentView.contentInset;
		CGPoint contentViewOffset = self.contentView.contentOffset;
				
		if (!titlebar.hidden) {
			CGRect titlebarFrame = titlebar.frame;
			titlebarFrame.origin.y = (-contentViewOffset.y - contentViewInset.top);
			titlebarFrame = CGRectIntegral(titlebarFrame);		
			if (!CGRectEqualToRect(titlebarFrame, titlebar.frame)) {
				titlebar.frame = titlebarFrame;
			}
		}
	}
	[self updateStatusBarReplacementUserInteractionStatus];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
			[originalContentViewDelegate scrollViewDidZoom:scrollView];
		}
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
			[originalContentViewDelegate scrollViewWillBeginDragging:scrollView];
		}
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
			[originalContentViewDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
		}
	}
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
			[originalContentViewDelegate scrollViewWillBeginDecelerating:scrollView];
		}
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
			[originalContentViewDelegate scrollViewDidEndDecelerating:scrollView];
		}
	}
}

- (void)scrollViewWillBeginScrollingAnimation:(UIScrollView *)scrollView {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(scrollViewWillBeginScrollingAnimation:)]) {
			[(id)originalContentViewDelegate scrollViewWillBeginScrollingAnimation:scrollView];
		}
		performingScrollAnimation = YES;
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
			[originalContentViewDelegate scrollViewDidEndScrollingAnimation:scrollView];
		}
		performingScrollAnimation = NO;
	}
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
			return [originalContentViewDelegate viewForZoomingInScrollView:scrollView];
		}
	}
	return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
			[originalContentViewDelegate scrollViewWillBeginZooming:scrollView withView:view];
		}
	}
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
			[originalContentViewDelegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
		}
	}
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
			return [originalContentViewDelegate scrollViewShouldScrollToTop:scrollView];
		}
	}
	return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
	if (scrollView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
			[originalContentViewDelegate scrollViewDidScrollToTop:scrollView];
		}
	}
}

#pragma mark -
#pragma mark TextView Delegate;

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	if (textView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
			return [originalContentViewDelegate textViewShouldBeginEditing:textView];
		}
	}
	return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	if (textView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
			return [originalContentViewDelegate textViewShouldEndEditing:textView];
		}
	}
	return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	if (textView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
			[originalContentViewDelegate textViewDidBeginEditing:textView];
		}
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	if (textView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
			[originalContentViewDelegate textViewDidEndEditing:textView];
		}
	}
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	if (textView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
			return [originalContentViewDelegate textView:textView shouldChangeTextInRange:range replacementText:text];
		}
	}
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
	if (textView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(textViewDidChange:)]) {
			[originalContentViewDelegate textViewDidChange:textView];
		}
	}
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
	if (textView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
			[originalContentViewDelegate textViewDidChangeSelection:textView];
		}
	}
}

#pragma mark -
#pragma mark TableView Delegate;

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
			[originalContentViewDelegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
		}
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
			return [originalContentViewDelegate tableView:tableView heightForRowAtIndexPath:indexPath];
		}
	}
	return [tableView rowHeight];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
			return [originalContentViewDelegate tableView:tableView heightForHeaderInSection:section];
		}
	}
	return tableView.sectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:heightForFooterInSection:)]) {
			return [originalContentViewDelegate tableView:tableView heightForFooterInSection:section];
		}
	}
	return tableView.sectionFooterHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
			return [originalContentViewDelegate tableView:tableView viewForHeaderInSection:section];
		}
	}
	return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section; {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:viewForFooterInSection:)]) {
			return [originalContentViewDelegate tableView:tableView viewForFooterInSection:section];
		}
	}
	return nil;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)]) {
			[originalContentViewDelegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
		}
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)]) {
			return [originalContentViewDelegate tableView:tableView willSelectRowAtIndexPath:indexPath];
		}
	}
	return indexPath;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:willDeselectRowAtIndexPath:)]) {
			return [originalContentViewDelegate tableView:tableView willDeselectRowAtIndexPath:indexPath];
		}
	}
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
			[originalContentViewDelegate tableView:tableView didSelectRowAtIndexPath:indexPath];
		}
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:didDeselectRowAtIndexPath:)]) {
			[originalContentViewDelegate tableView:tableView didDeselectRowAtIndexPath:indexPath];
		}
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:editingStyleForRowAtIndexPath:)]) {
			return [originalContentViewDelegate tableView:tableView editingStyleForRowAtIndexPath:indexPath];
		}
	}	
	return UITableViewCellEditingStyleNone;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:)]) {
			return [originalContentViewDelegate tableView:tableView titleForDeleteConfirmationButtonForRowAtIndexPath:indexPath];
		}
	}	
	return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:shouldIndentWhileEditingRowAtIndexPath:)]) {
			return [originalContentViewDelegate tableView:tableView shouldIndentWhileEditingRowAtIndexPath:indexPath];
		}
	}	
	return YES;
}

- (void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:willBeginEditingRowAtIndexPath:)]) {
			[originalContentViewDelegate tableView:tableView willBeginEditingRowAtIndexPath:indexPath];
		}
	}	
}

- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:didEndEditingRowAtIndexPath:)]) {
			[originalContentViewDelegate tableView:tableView didEndEditingRowAtIndexPath:indexPath];
		}
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]) {
			return [originalContentViewDelegate tableView:tableView targetIndexPathForMoveFromRowAtIndexPath:sourceIndexPath toProposedIndexPath:proposedDestinationIndexPath];
		}
	}	
	return proposedDestinationIndexPath;
}              

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (tableView == contentView) {
		if ([originalContentViewDelegate respondsToSelector:@selector(tableView:indentationLevelForRowAtIndexPath:)]) {
			return [originalContentViewDelegate tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
		}
	}	
	return 0;
}

@end

@implementation UIScrollView (BrowserViewAdditions)

+ (void)load {
    if (self == [UIScrollView class]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[UIScrollView replaceInstanceMethod:@selector(setContentOffset:animated:) withMethod:@selector(my_setContentOffset:animated:)];
		[UIScrollView replaceInstanceMethod:@selector(scrollRectToVisible:animated:) withMethod:@selector(my_scrollRectToVisible:animated:)];
		[pool release];
    }
}

- (void)my_setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
	id delegate = self.delegate;
	if ([delegate respondsToSelector:@selector(scrollViewWillBeginScrollingAnimation:)]) {
		[delegate scrollViewWillBeginScrollingAnimation:self];
	}
	[self my_setContentOffset:contentOffset animated:animated];
}

- (void)my_scrollRectToVisible:(CGRect)aRect animated:(BOOL)animated {
	id delegate = self.delegate;
	if ([delegate respondsToSelector:@selector(scrollViewWillBeginScrollingAnimation:)]) {
		[delegate scrollViewWillBeginScrollingAnimation:self];
	}
	[self my_scrollRectToVisible:aRect animated:animated];
}

@end