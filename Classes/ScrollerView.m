//
//  Scroller.m
// PlainText
//
//  Created by Jesse Grosjean on 6/24/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "ScrollerView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "UIImage_Additions.h"
#import "BrowserView.h"
#import "Button.h"


@implementation ScrollerView

#pragma mark -
#pragma mark Init

- (void)refreshFromDefaults {
	UIImage *thumbImage = [UIImage colorizeImage:[UIImage imageNamed:@"UIScrollerIndicatorBlack.png"] color:[APP_VIEW_CONTROLLER inkColorByPercent:0.5]];
	thumbImage = [thumbImage stretchableImageWithLeftCapWidth:2 topCapHeight:2];
	if (thumbImageView) {
		thumbImageView.image = thumbImage;
	} else {
		thumbImageView = [[UIImageView alloc] initWithImage:thumbImage];
	}
}

- (id)initWithFrame:(CGRect)aFrame {
	self = [super initWithFrame:aFrame];
	self.opaque = NO;
	[self refreshFromDefaults];
	thumbImageView.userInteractionEnabled = NO;
	thumbImageView.alpha = 0.0;
	[self addSubview:thumbImageView];
	return self;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[thumbImageView release];
	[super dealloc];
}

#pragma mark -
#pragma mark Scrolling

- (BOOL)tracking {
	return tracking;
}

- (void)checkForShouldFadeScrollView:(UIScrollView *)scrollView {
	if (tracking) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkForShouldFadeScrollView:) object:scrollView];
		[self performSelector:@selector(checkForShouldFadeScrollView:) withObject:scrollView afterDelay:0.1];
	} else {
		[UIView beginAnimations:@"FadeOut" context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDelegate:self];
		thumbImageView.alpha = 0;
		[UIView commitAnimations];
	}
}

- (void)updateScrollerViewFromScrollView:(UIScrollView *)scrollView fadeInPossible:(BOOL)fadeInPossible {
	BrowserView *browserView = (id) self.superview;

	CGPoint contentOffset = scrollView.contentOffset;
	UIEdgeInsets contentInset = scrollView.contentInset;
	CGSize contentSize = scrollView.contentSize;
	CGFloat totalHeight = contentSize.height + contentInset.bottom + contentInset.top;
	CGFloat thumbTopPercent = (contentOffset.y + contentInset.top) / totalHeight;
	CGFloat thumbBottomPercent = (contentOffset.y + contentInset.top + scrollView.bounds.size.height) / totalHeight;
	CGFloat thumbHeightPercent = scrollView.bounds.size.height / totalHeight;
	
	if (thumbHeightPercent >= 1) {
		self.userInteractionEnabled = NO;
	} else {
		self.userInteractionEnabled = YES;
	}	
	
	if (tracking || browserView.performingScrollAnimation || scrollView.tracking || scrollView.dragging || scrollView.decelerating) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkForShouldFadeScrollView:) object:scrollView];
		[self performSelector:@selector(checkForShouldFadeScrollView:) withObject:scrollView afterDelay:0.1];
		
		CGSize imageSize = [thumbImageView.image size];
		
		if (thumbHeightPercent >= 1) {
			[UIView beginAnimations:@"FadeOut" context:nil];
			[UIView setAnimationBeginsFromCurrentState:YES];
			[UIView setAnimationDelegate:self];
			thumbImageView.alpha = 0;
			[UIView commitAnimations];
		} else {
			CGRect bounds = CGRectInset(self.bounds, 0, 0);
			CGFloat minY = CGRectGetMinY(bounds) + 2;
			CGFloat maxY = CGRectGetMaxY(bounds) - 2 ;
			CGFloat topLocation = maxY * thumbTopPercent;
			CGFloat bottomLocation = maxY * thumbBottomPercent;
			CGFloat actualHeight = bottomLocation - topLocation;
			
			// Rubber band bottom;
			if (thumbTopPercent < 0) {
				bottomLocation -= abs(topLocation) * 1.5;//(contentInset.top + contentOffset.y);
			}
			
			// Rubber band top;
			if (thumbBottomPercent > 1.0) {
				topLocation += (bottomLocation - maxY) * 1.5;
				//topLocation += (bounds.size.height - (contentSize.height - contentOffset.y + contentInset.bottom));
			}
			
			// Adjust for min height;
			CGFloat minHeight = 25;
			CGFloat growBy = minHeight - actualHeight;
			if (growBy > 0) {
				topLocation -= (growBy * thumbTopPercent);
				bottomLocation += growBy * (1.0 - thumbBottomPercent);
			}
			
			if (topLocation < minY) {
				topLocation = minY;
				if (bottomLocation < minY + imageSize.height) {
					bottomLocation = minY + imageSize.height;
				}
			}
			
			if (bottomLocation > maxY) {
				bottomLocation = maxY;
				if (topLocation > maxY - imageSize.height) {
					topLocation = maxY - imageSize.height;
				}
			}
			
			CGRect thumb = bounds;
			thumb.origin.y = topLocation;
			thumb.size.height = bottomLocation - topLocation;
			thumb.size.width = imageSize.width;
			thumb.origin.x = bounds.size.width - (thumb.size.width + 2);
			thumb = CGRectIntegral(thumb);
			
			thumbImageView.frame = thumb;

			if (fadeInPossible) {
				[UIView beginAnimations:@"FadeIn" context:nil];
				[UIView setAnimationBeginsFromCurrentState:YES];
				[UIView setAnimationDelegate:self];
				thumbImageView.alpha = 1.0;
				[UIView commitAnimations];
			}
		}
	}
}

- (void)updateScrollViewFromSelf:(CGFloat)touchPoint {
	BrowserView *browserView = (id) self.superview;
	UIScrollView *scrollView = browserView.contentView;
	UIEdgeInsets contentInset = scrollView.contentInset;
	CGSize contentSize = scrollView.contentSize;
	CGFloat height = self.frame.size.height;
	CGFloat percent = touchPoint / height;
	
	if (percent < 0) percent = 0;
	if (percent > 1) percent = 1;
	
	contentSize.height += (contentInset.bottom + contentInset.top);

	if (contentSize.height < height) return;
	
	CGPoint nextContentOffset = CGPointMake(0, ((contentSize.height - scrollView.frame.size.height) * percent) - contentInset.top);

	[scrollView setContentOffset:nextContentOffset];
}

#pragma mark -
#pragma mark Events

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	if (![[NSUserDefaults standardUserDefaults] boolForKey:DraggableScrollerDefaultsKey]) {
		self.userInteractionEnabled = NO;
	}

	if (self.userInteractionEnabled) {
		// allow click on buttons to pass through, otherwise start scroller drag.
		self.userInteractionEnabled = NO;
		UIView *buttonTest = [self.window hitTest:[self convertPoint:point toView:nil] withEvent:event];
		self.userInteractionEnabled = YES;
		if ([buttonTest isKindOfClass:[Button class]]) {
			return buttonTest;
		} else {
			return [super hitTest:point withEvent:event];
		}
	} else {
		return [super hitTest:point withEvent:event];
	}
}

- (BOOL)becomeFirstResponder {
	return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	BrowserView *browserView = (id) self.superview;
	UIScrollView *scrollView = browserView.activeScrollView;
	
	if (scrollView.decelerating) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0];
		[scrollView setContentOffset:scrollView.contentOffset animated:YES];
		[UIView commitAnimations];
	}

	tracking = YES;
	canceledFirst = NO;
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.5];
	[self updateScrollViewFromSelf:[[touches anyObject] locationInView:self].y];
	[UIView commitAnimations];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {	
	if (!canceledFirst) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0];
		[self updateScrollViewFromSelf:[[touches anyObject] locationInView:self].y];
		[UIView commitAnimations];
		canceledFirst = YES;
	} else {
		[self updateScrollViewFromSelf:[[touches anyObject] locationInView:self].y];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	tracking = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	tracking = NO;
}

@end
