//
//  SearchBar.m
//  PlainText
//
//  Created by Jesse Grosjean on 10/14/10.
//

#import "Searchbar.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "SearchView.h"
#import "Button.h"

@implementation Searchbar

- (id)init {
	self = [super init];
    self.drawTopDivider = NO;
	self.drawBottomDivider = YES;
	return self;
}

@synthesize searchView;

- (void)setSearchView:(SearchView *)aSearchView {
	if (aSearchView) {		
		if (!aSearchView.accessibilityLabel) {
			aSearchView.accessibilityLabel = NSLocalizedString(@"Search", nil);
		}
		
		[self addSubview:aSearchView];
	}
	[searchView removeFromSuperview];
	searchView = aSearchView;
}

@synthesize rightButton;

- (void)setRightButton:(UIButton *)aButton {
	[rightButton removeFromSuperview];
	rightButton = aButton;
	if (rightButton) {
		originalRightWidth = rightButton.frame.size.width;
		originalRightInsets = rightButton.imageEdgeInsets;
		[self layoutSubviews];
		[self addSubview:rightButton];
	}
}

@synthesize leftButton;

- (void)setLeftButton:(UIButton *)aButton {
    [leftButton removeFromSuperview];
    leftButton = aButton;
    if (leftButton) {
        originalLeftWidth = leftButton.frame.size.width;
		originalLeftInsets = leftButton.imageEdgeInsets;
		[self layoutSubviews];
		[self addSubview:leftButton];
    }
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, padding);
    
    if (leftButton) {
		CGRect leftFrame = CGRectZero;
		UIEdgeInsets imageEdgeInsets = originalLeftInsets;
		CGRectDivide(bounds, &leftFrame, &bounds, originalLeftWidth, CGRectMinXEdge);
		leftFrame.origin.x = 0;
		leftFrame.size.width += padding.left;
		leftButton.frame = CGRectIntegral(leftFrame);
		imageEdgeInsets.left += padding.left;
		leftButton.imageEdgeInsets = imageEdgeInsets;
	}
    
    if (rightButton) {
		CGRect rightFrame = CGRectZero;
		UIEdgeInsets imageEdgeInsets = originalRightInsets;
		CGRectDivide(bounds, &rightFrame, &bounds, originalRightWidth, CGRectMaxXEdge);
		rightFrame.size.width += padding.right;
		rightFrame.origin.x = CGRectGetMaxX(self.bounds) - rightFrame.size.width;
		rightButton.frame = CGRectIntegral(rightFrame);
		imageEdgeInsets.right += padding.right;
		rightButton.imageEdgeInsets = imageEdgeInsets;
	}
    
    CGFloat leftWidth = leftButton != nil ? originalLeftWidth : 0;
    CGFloat rightWidth = rightButton != nil ? originalRightWidth : 0;   
    CGFloat maxWidth = 0;
	
	if (leftWidth > rightWidth) {
		maxWidth = leftWidth;
	} else {
		maxWidth = rightWidth;
	}
	
	if (maxWidth == 0) {
		maxWidth = 32;
	}
        
	CGRect searchFrame = bounds;
	searchFrame.size.height = searchView.frame.size.height;
    //searchFrame.size.width -= rightWidth + leftWidth;
    searchFrame.origin.x = CGRectGetMinX(bounds);
	searchFrame.origin.y += round((bounds.size.height - searchFrame.size.height) / 2.0);
	if (!CGRectEqualToRect(searchFrame, searchView.frame)) {
		searchView.frame = searchFrame;
	}
     
}

@end
