//
//  ApplicationView.h
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

@class Button;
@class BrowserView;
@class HUDBackgroundView;

@interface ApplicationView : UIView {
	BrowserView *primaryView;
	BrowserView *secondaryView;
	Button *hideKeyboardButton;
	Button *toggleDocumentFocusButton;
	HUDBackgroundView *hudBackgroundView;
	UIView *dividerView;
	CGFloat keyboardHeight;
	NSInteger ignoreNextkeyboardHideShowIfKeyboardIsShowingCount;
}

@property (nonatomic, retain) BrowserView *primaryView;
@property (nonatomic, retain) BrowserView *secondaryView;
@property (nonatomic, assign) BOOL ignoreNextkeyboardHideShowIfKeyboardIsShowing;

- (void)setHUDBackgroundView:(HUDBackgroundView *)aHUDBackgroundView;
- (IBAction)toggleDocumentFocusMode:(id)sender;

@end