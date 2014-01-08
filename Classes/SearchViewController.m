//
//  SearchViewController.m
//  PlainText
//
//  Created by Jesse Grosjean on 12/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "SearchViewController.h"
#import "SearchView.h"
#import "Button.h"
#import "BrowserViewController.h"
#import "BrowserView.h"
#import "Bar.h"
#import "Searchbar.h"
#import "ViewController.h"
#import "ItemViewController.h"
#import "MenuView.h"
#import "ApplicationController.h"
#import "ApplicationViewController.h"

@implementation SearchViewController

- (id)init {
	self = [super init];
	return self;
}

- (void)dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (SearchView *)searchView {
	return (id) self.view;
}

- (Button *)beginSearchButton {
	[beginSearchButton autorelease];
	beginSearchButton = nil;
	
	if (!beginSearchButton) {
        if ([self.searchView.text length] == 0) {
            beginSearchButton = [[Button buttonWithImage:[UIImage imageNamed:@"search_small.png"] accessibilityLabel:NSLocalizedString(@"Search", nil) accessibilityHint:nil target:self action:@selector(beginSearch:) edgeInsets:UIEdgeInsetsMake(0, 15, 0, 15)] retain];
        } else {
            beginSearchButton = [[Button buttonWithImage:[UIImage imageNamed:@"search_small_active.png"] accessibilityLabel:NSLocalizedString(@"Search", nil) accessibilityHint:nil target:self action:@selector(beginSearch:) edgeInsets:UIEdgeInsetsMake(0, 15, 0, 15)] retain];            
        }
	}
	return beginSearchButton;
}

- (Searchbar *)searchbar {
    ItemViewController *viewController = (ItemViewController *)(self.delegate);
    return viewController.browserViewController.browserView.searchbar;
}

- (void)setSearchbarHidden:(BOOL)hidden {
    ItemViewController *viewController = (ItemViewController *)(self.delegate);
    Searchbar *searchbar = viewController.browserViewController.browserView.searchbar;
    searchbar.hidden = hidden;
    [viewController.browserViewController.browserView setNeedsLayout];
}

- (void)updateSearchText:(NSString *)newSearchText {
    self.searchView.text = newSearchText;
    if (newSearchText && [newSearchText length] > 0) {
        [self setSearchbarHidden:NO];
        [beginSearchButton setImage:[UIImage imageNamed:@"search_small_active.png"] forState:UIControlStateNormal];
    } else {
        [self setSearchbarHidden:YES];
        [beginSearchButton setImage:[UIImage imageNamed:@"search_small.png"] forState:UIControlStateNormal];
    }
    [beginSearchButton setNeedsDisplay];
}

- (void)beginSearch:(id)sender {
    if (self.searchbar.hidden) {
        ItemViewController *viewController = (ItemViewController *)(self.delegate);
        UIScrollView *scrollView = (UIScrollView *)viewController.view;
        [scrollView setContentOffset:CGPointMake(0, -scrollView.contentInset.top) animated:NO];
        [self setSearchbarHidden:NO];
        [self.searchView becomeFirstResponder];
    } else {
        [self updateSearchText:@""];    
        [self performSelector:@selector(notifiySearchFieldChangedAfterDelay:) withObject:[NSNumber numberWithFloat:0.0000001]];
        [self setSearchbarHidden:YES];
        if ([self.searchView isFirstResponder]) {
            [self.searchView resignFirstResponder];
        }
    }
}

#pragma mark -
#pragma mark View lifecycle

- (void)loadView {    
	SearchView *searchView = [[[SearchView alloc] init] autorelease];
	searchView.delegate = self;
	searchView.text = self.title;
	self.view = searchView;
	[super loadView];
}

#pragma mark -
#pragma mark TextField delegate

- (void)menu {
    MenuView *menuView = [self.delegate pathViewPopupMenuView:nil];
	menuView.anchorView = self.searchView;
	menuView.offsetPosition = CGPointMake(0, (NSUInteger)([APP_VIEW_CONTROLLER leading] / 2));
	menuView.anchorRelativePosition = PositionDown;
	[menuView show];	
}

- (void)notifiySearchFieldChangedAfterDelay:(NSNumber *)delayNumber {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (self.searchView.text.length > 0) {
        [beginSearchButton setImage:[UIImage imageNamed:@"search_small_active.png"] forState:UIControlStateNormal];
    }
    
	CGFloat delay = [delayNumber floatValue];
	
	if (delay == 0) {
		[self.delegate searchViewTextDidChange:self];
	} else {
		[self performSelector:@selector(notifiySearchFieldChangedAfterDelay:) withObject:[NSNumber numberWithFloat:0] afterDelay:[delayNumber floatValue]];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self notifiySearchFieldChangedAfterDelay:[NSNumber numberWithFloat:0]];
	
    if ([self.delegate respondsToSelector:@selector(searchViewShouldReturn:)]) {
        [self.delegate performSelector:@selector(searchViewShouldReturn:) withObject:textField];
    }

	if ([textField isFirstResponder]) {
		[textField resignFirstResponder];
	}
	return NO;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	[self notifiySearchFieldChangedAfterDelay:[NSNumber numberWithFloat:0.0000001]];
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {	
	NSString *endString = [textField.text stringByReplacingCharactersInRange:range withString:string];
	if ([endString length] > 0) {
		textField.rightViewMode = UITextFieldViewModeAlways;
	} else {
		textField.rightViewMode = UITextFieldViewModeNever;
	}
	[self notifiySearchFieldChangedAfterDelay:[NSNumber numberWithFloat:0.5]];
	return YES;
}

@end