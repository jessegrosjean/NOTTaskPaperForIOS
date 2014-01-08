//
//  ApplicationView.m
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//

#import "ApplicationView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "HUDBackgroundView.h"
#import "UIImage_Additions.h"
#import "UIView_Additions.h"
#import "BrowserView.h"
#import "Button.h"
#import "SettingsViewController.h"

@implementation ApplicationView

- (void)refreshFromDefaults {
	self.backgroundColor = [APP_VIEW_CONTROLLER paperColor];
	dividerView.backgroundColor = [APP_VIEW_CONTROLLER inkColorByPercent:0.15];
	self.window.backgroundColor = [UIColor blackColor];
	[hideKeyboardButton setImage:[UIImage colorizeImage:[UIImage imageNamed:@"hideKeyboard.png"] color:[APP_VIEW_CONTROLLER inkColorByPercent:0.15]] forState:UIControlStateNormal];
	[self setNeedsLayout];
}

- (id)initWithFrame:(CGRect)aFrame {
	self = [super initWithFrame:aFrame];
	self.autoresizesSubviews = YES;
	dividerView = [[[UIView alloc] init] autorelease];
	[self addSubview:dividerView];

#if !defined(WRITEROOM) && !defined(TASKPAPER)
	adView = [AdWhirlView requestAdWhirlViewWithDelegate:self];
	if (![[StoreController sharedInstance] shouldShowAdBanner]) {
		[adView ignoreNewAdRequests];
	}
	
	adWrapperView = [[[AdWrapperView alloc] initWithFrame:adView.frame] autorelease];
	adWrapperView.userInteractionEnabled = YES;
	adWrapperView.backgroundColor = [UIColor blackColor];
	[adWrapperView addSubview:adView];
	[self addSubview:adWrapperView];
#endif
    
	[self refreshFromDefaults];

	hideKeyboardButton = [Button buttonWithImage:[UIImage imageNamed:@"hideKeyboard.png"] accessibilityLabel:NSLocalizedString(@"Hide Keyboard", nil) accessibilityHint:nil target:APP_VIEW_CONTROLLER action:@selector(hideKeyboard) edgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
	hideKeyboardButton.brightness = 0.15;
	hideKeyboardButton.userInteractionEnabled = NO;
	hideKeyboardButton.alpha = 0.0;
	[self addSubview:hideKeyboardButton];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	if (IS_IPAD) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setBool:![defaults boolForKey:DocumentFocusModeDefaultsKey] forKey:DocumentFocusModeDefaultsKey];
		[UIView setAnimationsEnabled:NO];
		[self toggleDocumentFocusMode:nil];
		[UIView setAnimationsEnabled:YES];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (IBAction)toggleDocumentFocusMode:(id)sender {
	if (!toggleDocumentFocusButton) {
		toggleDocumentFocusButton = [Button buttonWithImage:nil accessibilityLabel:nil accessibilityHint:nil target:self action:@selector(toggleDocumentFocusMode:) edgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
		toggleDocumentFocusButton.brightness = 0.15;
		[self addSubview:toggleDocumentFocusButton];
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL newDocumentFocusMode = ![defaults boolForKey:DocumentFocusModeDefaultsKey];
	[defaults setBool:newDocumentFocusMode forKey:DocumentFocusModeDefaultsKey];

	[[NSNotificationCenter defaultCenter] postNotificationName:DocumentFocusModeAnimationWillStart object:self];

	[UIView beginAnimations:@"ToggleDocumentFocus" context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(toggleDocumentFocusModeAnimationDidStop:context:)];
	[UIView setAnimationDuration:0.5];

	[APP_VIEW_CONTROLLER setAnimatingKeyboardOrDocumentFocusMode:YES];
	
	if (newDocumentFocusMode) {
		[toggleDocumentFocusButton setImage:[UIImage imageNamed:@"exitFullScreen.png"] forState:UIControlStateNormal];
		toggleDocumentFocusButton.accessibilityLabel = NSLocalizedString(@"Exit fullscreen mode", nil);
	} else {
		[toggleDocumentFocusButton setImage:[UIImage imageNamed:@"enterFullScreen.png"] forState:UIControlStateNormal];
		toggleDocumentFocusButton.accessibilityLabel = NSLocalizedString(@"Enter fullscreen mode", nil);
	}
	
	[toggleDocumentFocusButton refreshFromDefaults];
	
	[self setNeedsLayout];
	[self layoutIfNeeded];
	
	[APP_VIEW_CONTROLLER setAnimatingKeyboardOrDocumentFocusMode:NO];
	[UIView commitAnimations];
}

- (void)toggleDocumentFocusModeAnimationDidStop:(NSString *)animationID context:(void *)context {
	[[NSNotificationCenter defaultCenter] postNotificationName:DocumentFocusModeAnimationDidStop object:self];
}

- (void)setFrame:(CGRect)aRect {
	[super setFrame:aRect];
}

@synthesize primaryView, secondaryView;

- (void)setPrimaryView:(BrowserView *)aView {
	if (primaryView) {
		[primaryView removeFromSuperview];
	}
	[primaryView autorelease];
	primaryView = [aView retain];
	if (primaryView) {
		[self addSubview:primaryView];
	}
	[self bringSubviewToFront:dividerView];
}

- (void)setSecondaryView:(BrowserView *)aView {
	if (secondaryView) {
		[secondaryView removeFromSuperview];
	}
	[secondaryView autorelease];
	secondaryView = [aView retain];
	if (secondaryView) {
		[self addSubview:secondaryView];
	}
}

- (BOOL)ignoreNextkeyboardHideShowIfKeyboardIsShowing {
	return ignoreNextkeyboardHideShowIfKeyboardIsShowingCount > 0;
}

- (void)setIgnoreNextkeyboardHideShowIfKeyboardIsShowing:(BOOL)aBool {
	if (keyboardHeight > 0) {
		ignoreNextkeyboardHideShowIfKeyboardIsShowingCount = 2;
	} else {
		ignoreNextkeyboardHideShowIfKeyboardIsShowingCount = 0;
	}
}

- (void)setHUDBackgroundView:(HUDBackgroundView *)aHUDBackgroundView {
	if (hudBackgroundView) {
		[hudBackgroundView removeFromSuperview];
		hudBackgroundView = nil;
	}
	
	if (aHUDBackgroundView) {
		hudBackgroundView = aHUDBackgroundView;
		hudBackgroundView.frame = self.bounds;
		[self addSubview:hudBackgroundView];
		[self setNeedsLayout];
	}
}

- (void)layoutSubviews {
    /*if ([SettingsViewController showing]) {
        [self performSelector:@selector(setNeedsLayout) withObject:nil afterDelay:0.1];
        return;
    }*/
    
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
	if (!CGRectEqualToRect(applicationFrame, self.frame)) {
		self.frame = applicationFrame;
	}
	
	[super layoutSubviews];
	
	CGRect bounds = self.bounds;
			
	hudBackgroundView.frame = bounds;
	
	CGFloat leading = round([APP_VIEW_CONTROLLER leading]);	
		
	[APP_VIEW_CONTROLLER setAdsHeight:0];

	if (IS_IPAD) {
		CGRect primaryViewFrame;
		CGRect secondaryViewFrame;
		CGRect dividerViewFrame;
		CGFloat primaryWidth = round(bounds.size.width * (1 / 3.2));
		CGRectDivide(bounds, &primaryViewFrame, &secondaryViewFrame, primaryWidth, CGRectMinXEdge);
		primaryViewFrame.size.width--;
		dividerViewFrame = primaryViewFrame;
		dividerViewFrame.size.width = 1;
		dividerViewFrame.origin.x = CGRectGetMaxX(primaryViewFrame);
		
		BOOL primaryIsHidden = [[NSUserDefaults standardUserDefaults] boolForKey:DocumentFocusModeDefaultsKey];
		BOOL portraitOrientation = UIInterfaceOrientationIsPortrait([APP_VIEW_CONTROLLER interfaceOrientation]);
        
		UIEdgeInsets primaryViewPadding = UIEdgeInsetsMake(12, 24, 6, 24);
		UIEdgeInsets secondaryViewPadding = UIEdgeInsetsMake(12, 48, 6, 48);

		if (portraitOrientation) {
			if (!primaryIsHidden) {
				CGRect screenBounds = [self convertRect:[[UIScreen mainScreen] bounds] fromView:nil];
				CGFloat widthScaleFactor = screenBounds.size.width / screenBounds.size.height;
				primaryViewPadding.left *= widthScaleFactor;
				primaryViewPadding.right *= widthScaleFactor;
				secondaryViewPadding.left *= widthScaleFactor;
				secondaryViewPadding.right *= widthScaleFactor;
			} else {
				secondaryViewFrame.size.width = round(bounds.size.height - (bounds.size.height * (1 / 3.2)));
			}
		}
		
		if (primaryIsHidden) {
			primaryViewFrame.origin.x -= primaryViewFrame.size.width;
			dividerViewFrame.origin.x = CGRectGetMaxX(primaryViewFrame) - 1;
			
			if (portraitOrientation) {
				secondaryViewPadding.left += round((bounds.size.width - secondaryViewFrame.size.width) / 2.0);
				secondaryViewPadding.right += round((bounds.size.width - secondaryViewFrame.size.width) / 2.0);
				secondaryViewFrame = bounds;
			} else {
				secondaryViewPadding.left += round((bounds.size.width - secondaryViewFrame.size.width) / 2.0);
				secondaryViewPadding.right += round((bounds.size.width - secondaryViewFrame.size.width) / 2.0);
                
#ifdef TASKPAPER
                secondaryViewPadding.left = round(secondaryViewPadding.left - secondaryViewPadding.left / 1.75);
                secondaryViewPadding.right = round(secondaryViewPadding.right - secondaryViewPadding.right / 1.75);
#endif
				secondaryViewFrame = bounds;
			}
		}

		primaryView.padding = primaryViewPadding;
		secondaryView.padding = secondaryViewPadding;

		primaryView.frame = primaryViewFrame;
		secondaryView.frame = secondaryViewFrame;
		dividerView.frame = dividerViewFrame;
		
		CGRect toggleFrame = toggleDocumentFocusButton.frame;
		toggleFrame.size.width = leading * 2;
		toggleFrame.size.height = leading * 2;
		toggleFrame.origin.x = CGRectGetMaxX(bounds) - toggleFrame.size.width;
		toggleFrame.origin.y = CGRectGetMaxY(bounds) - toggleFrame.size.height;

		if (keyboardHeight > 0) {
			toggleFrame.origin.y -= (keyboardHeight - [APP_VIEW_CONTROLLER adsHeight]);
		}
		
		toggleFrame = CGRectIntegral(toggleFrame);
		toggleDocumentFocusButton.frame = toggleFrame;
#ifdef TASKPAPER
        toggleDocumentFocusButton.hidden = YES;
#else
		[self bringSubviewToFront:toggleDocumentFocusButton];
#endif
	} else {
		primaryView.frame = bounds;
		primaryView.padding = UIEdgeInsetsMake(0, 10, 0, 10);
	}
	
	if (hideKeyboardButton) {
		CGRect hideFrame = hideKeyboardButton.frame;
		hideFrame.size.width = leading * 2;
		hideFrame.size.height = leading * 2;
		hideFrame.origin.x = CGRectGetMaxX(bounds) - hideFrame.size.width;
		hideFrame.origin.y = CGRectGetMaxY(bounds) - hideFrame.size.height;
		hideFrame.origin.y -= (keyboardHeight - [APP_VIEW_CONTROLLER adsHeight]);
		hideFrame = CGRectIntegral(hideFrame);
		hideKeyboardButton.frame = hideFrame;
		[self bringSubviewToFront:hideKeyboardButton];
	}	

	[hudBackgroundView setNeedsLayout];
	[hudBackgroundView layoutIfNeeded];
}

#pragma mark -
#pragma mark Keyboard delegate

- (void)keybooardInfo:(NSDictionary *)userInfo animationDuration:(NSTimeInterval *)animationDuration animationCurve:(UIViewAnimationCurve *)animationCurve keyboardBeginFrame:(CGRect *)keyboardBeginFrame keyboardEndFrame:(CGRect *)keyboardEndFrame{
	ApplicationController *applicationController = APP_CONTROLLER;
	
	[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:animationDuration];
	
	if ([applicationController isIOS32OrLater]) {
		[[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:keyboardBeginFrame];
		[[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:keyboardEndFrame];
	} 
}

- (void)keyboardWillShow:(NSNotification *)aNotification {
	if (ignoreNextkeyboardHideShowIfKeyboardIsShowingCount > 0) {
		ignoreNextkeyboardHideShowIfKeyboardIsShowingCount--;
		return;
	}
	
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardBeginFrame;
    CGRect keyboardEndFrame;
	[self keybooardInfo:[aNotification userInfo] animationDuration:&animationDuration animationCurve:&animationCurve keyboardBeginFrame:&keyboardBeginFrame keyboardEndFrame:&keyboardEndFrame];
	CGRect keyboardEndFrameVisibleRect = CGRectIntersection([self convertRect:self.bounds toView:nil], keyboardEndFrame);
	CGFloat keyboardFullHeight = [self convertRect:keyboardEndFrame fromView:nil].size.height;
	
	[UIView beginAnimations:@"ResizeViewsForKeyboard" context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:animationDuration];
	[UIView setAnimationCurve:animationCurve];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(keyboardAnimationEnded:context:)];
	keyboardHeight = [self convertRect:keyboardEndFrameVisibleRect fromView:nil].size.height;
	
	if (keyboardHeight < keyboardFullHeight) {
		[APP_VIEW_CONTROLLER setIsHardwareKeyboard:YES];
		keyboardHeight = 0;
	} else {
		[APP_VIEW_CONTROLLER setIsHardwareKeyboard:NO];
	}
	
	[APP_VIEW_CONTROLLER setAnimatingKeyboardOrDocumentFocusMode:YES];
	[APP_VIEW_CONTROLLER setKeyboardHeight:keyboardHeight];

	[[NSNotificationCenter defaultCenter] postNotificationName:KeyboardWillShowNotification object:self];
	
	if (!IS_IPAD) {
		hideKeyboardButton.alpha = 1.0;
		hideKeyboardButton.userInteractionEnabled = YES;
	}
	
	[self setNeedsLayout];
	[self layoutIfNeeded];
	[UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
	if (ignoreNextkeyboardHideShowIfKeyboardIsShowingCount > 0) {
		ignoreNextkeyboardHideShowIfKeyboardIsShowingCount--;
		return;
	}
	
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardBeginFrame;
    CGRect keyboardEndFrame;
	[self keybooardInfo:[aNotification userInfo] animationDuration:&animationDuration animationCurve:&animationCurve keyboardBeginFrame:&keyboardBeginFrame keyboardEndFrame:&keyboardEndFrame];
		
	[UIView beginAnimations:@"ResizeViewsForKeyboard" context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:animationDuration];
	[UIView setAnimationCurve:animationCurve];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(keyboardAnimationEnded:context:)];
	keyboardHeight = 0;
	
	if (hideKeyboardButton) {
		hideKeyboardButton.userInteractionEnabled = NO;
		hideKeyboardButton.alpha = 0;
	}
	
	[APP_VIEW_CONTROLLER setAnimatingKeyboardOrDocumentFocusMode:YES];
	[APP_VIEW_CONTROLLER setIsHardwareKeyboard:NO];
	[APP_VIEW_CONTROLLER setIsClosingKeyboard:YES];
	[APP_VIEW_CONTROLLER setKeyboardHeight:keyboardHeight];

	[[NSNotificationCenter defaultCenter] postNotificationName:KeyboardWillHideNotification object:self];
	[self setNeedsLayout];
	[self layoutIfNeeded];
	[UIView commitAnimations];	
}

- (void)keyboardAnimationEnded:(NSString *)animationID context:(void *)context {
	[APP_VIEW_CONTROLLER setAnimatingKeyboardOrDocumentFocusMode:NO];	
	[APP_VIEW_CONTROLLER setIsClosingKeyboard:NO];
}

#pragma mark -
#pragma mark AdWhirl Delegate

- (UIViewController *)viewControllerForPresentingModalView {
	return APP_VIEW_CONTROLLER;
}

@end
