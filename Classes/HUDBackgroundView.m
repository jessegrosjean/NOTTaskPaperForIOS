//
//  HUDView.m
//  PlainText
//
//  Created by Jesse Grosjean on 4/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HUDBackgroundView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "ApplicationView.h"

@interface HUDBorderView : UIView {
}
@end

@implementation HUDBorderView

- (void)refreshFromDefaults {
	[self setNeedsDisplay];
}

- (id)init {
	self = [super init];
	if (self) {
		self.opaque = NO;
		CALayer *layer = self.layer;
		if ([layer respondsToSelector:@selector(setShadowOffset:)]) {
			layer.shadowOffset = CGSizeMake(0, 10);
			layer.shadowRadius = 15;
			layer.shadowOpacity = 0.25;
		}
		[self refreshFromDefaults];
	}
	return self;
}

#pragma mark Drawing

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect) rect {
	[[UIColor clearColor] set];
	UIRectFill(rect);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect bounds = self.bounds;
	
	[[APP_VIEW_CONTROLLER inkColorByPercent:0.03] set];
	CGContextAddRoundedRect(context, bounds, 10);
	CGContextFillPath(context);
	
	[[APP_VIEW_CONTROLLER inkColorByPercent:0.8] set];
	bounds.origin.x += 0.5;
	bounds.origin.y += 0.5;
	bounds.size.width -= 1.0;
	bounds.size.height -= 1.0;
	
	CGContextAddRoundedRect(context, bounds, 10);
	CGContextSetLineWidth(context, 1);
	CGContextDrawPath(context, kCGPathStroke);
}

@end

@implementation HUDBackgroundView

- (void)refreshFromDefaults {
	//self.backgroundColor = [[APP_VIEW_CONTROLLER paperColor] colorWithAlphaComponent:0.5];
	[self setNeedsLayout];
}

- (id)init {
    self = [super init];
    if (self) {
		[self refreshFromDefaults];
		
		self.opaque = NO;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.borderInset = CGSizeMake(-10, -10);
		//self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
		hudBorderView = [[[HUDBorderView alloc] init] autorelease];
		[self addSubview:hudBorderView];
		[self addSubview:self.hudView];
    }
    return self;
}

- (void)dealloc {
	[anchorView release];
    [super dealloc];
}

@synthesize anchorRelativePosition;
@synthesize offsetPosition;
@synthesize borderInset;
@synthesize anchorView;
@synthesize hudView;

- (UIView *)hudView {
	return nil;
}

- (void)show {
	[self refreshSelfAndSubviewsFromDefaults];
	
	[[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
	
	showing++;
    
	[self setNeedsLayout];
	[self setNeedsDisplay];
	
	self.alpha = 0.0;
	[(ApplicationView *)[APP_VIEW_CONTROLLER view] setHUDBackgroundView:self];
	
	[self layoutSubviews];
	
	[UIView beginAnimations:nil	context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.1];
	self.alpha = 1.0;
	[UIView commitAnimations];
    self.hudView.userInteractionEnabled = YES;
    [self.hudView becomeFirstResponder];
    
    if ([self.hudView respondsToSelector:@selector(flashScrollIndicators)]) {
        [self.hudView performSelector:@selector(flashScrollIndicators)];
    }
}

- (void)close {
	showing--;
	
	self.hudView.userInteractionEnabled = NO;
	[[NSRunLoop currentRunLoop] cancelPerformSelectorsWithTarget:self.hudView];
	
	[UIView beginAnimations:nil	context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(closeAnimationDidStop:finished:context:)];
	[UIView setAnimationDuration:0.1];
	self.alpha = 0.0;
	offsetPosition = CGPointMake(0, 0);
	[UIView commitAnimations];
}

- (void)closeIfShowing {
	if (showing > 0) {
		[self close];
	}
}

- (void)didClose {
	[(ApplicationView *)[APP_VIEW_CONTROLLER view] setHUDBackgroundView:nil];
}

- (void)closeAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	//if (showing == 0) {
		[self didClose];
	//}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self close];
}

- (void)setNeedsLayout {
	[super setNeedsLayout];
}

- (void)layoutSubviews {
	if (!anchorView) {
		anchorView = [[APP_VIEW_CONTROLLER view] retain];
	}
	
	CGRect anchoreBounds = [self convertRect:[anchorView convertRect:anchorView.bounds toView:nil] fromView:nil];
	
	if (anchorView == [APP_VIEW_CONTROLLER view]) {
		CGFloat keyboardHeight = [APP_VIEW_CONTROLLER keyboardHeight];
		
		anchoreBounds.size.height -= keyboardHeight;
		//if (keyboardHeight > 0) {
		//	bounds.size.height -= (keyboardHeight - [APP_VIEW_CONTROLLER adsHeight]);		
		//	if (!IS_IPAD && !toolbar.hidden) {
		//		bounds.size.height += toolbar.frame.size.height;
		//	}
		//	}
	}

	anchoreBounds.origin.x += offsetPosition.x;
	anchoreBounds.origin.y += offsetPosition.y;
	
	hudViewFrame.origin = CGPointMake(0, 0);
	hudViewFrame = CGRectInset(hudViewFrame, 0, -5);
	hudViewFrame.origin = anchoreBounds.origin;
	
	switch (anchorRelativePosition) {
		case PositionUp:
			hudViewFrame.origin.x -= CGRectGetMidX(hudViewFrame) - CGRectGetMidX(anchoreBounds);
			hudViewFrame.origin.y -= hudViewFrame.size.height;
			break;
		case PositionDown:
			hudViewFrame.origin.x -= CGRectGetMidX(hudViewFrame) - CGRectGetMidX(anchoreBounds);
			hudViewFrame.origin.y += anchoreBounds.size.height;
			break;
		case PositionLeft:
			break;
		case PositionRight:
			break;
		case PositionUpLeft:
			hudViewFrame.origin.y -= hudViewFrame.size.height;
			hudViewFrame.origin.x -= hudViewFrame.size.width - anchoreBounds.size.width;
			break;
		case PositionUpRight:
			hudViewFrame.origin.y -= hudViewFrame.size.height;
			break;
		case PositionDownLeft:
			hudViewFrame.origin.x -= hudViewFrame.size.width - anchoreBounds.size.width;
			hudViewFrame.origin.y += anchoreBounds.size.height;
			break;
		case PositionDownRight:
			hudViewFrame.origin.y += anchoreBounds.size.height;
			break;
		case PositionCentered:
			hudViewFrame.origin.x -= CGRectGetMidX(hudViewFrame) - CGRectGetMidX(anchoreBounds);
			hudViewFrame.origin.y -= CGRectGetMidY(hudViewFrame) - CGRectGetMidY(anchoreBounds);			
	}
	
	CGRect bounds = self.bounds;
	
	UIWindow *selfWindow = self.window;
	for (UIWindow *eachWindow in [[UIApplication sharedApplication] windows]) {
		if (eachWindow != selfWindow) {
			if (!eachWindow.hidden) {
				for (UIView *eachView in eachWindow.subviews) {
					if (!eachView.hidden) {
						CGRect eachRect = CGRectInset([eachView convertRect:eachView.bounds toView:self], -5, -5);
						if (CGRectGetMinY(eachRect) < CGRectGetMaxY(hudViewFrame)) {
							hudViewFrame.size.height -= CGRectGetMaxY(hudViewFrame) - CGRectGetMinY(eachRect);
						}
					}
				}
			}
		}
	}
	
	hudViewFrame = CGRectIntersection(hudViewFrame, CGRectInset(bounds, 5, 5));
	
	if (![[UIApplication sharedApplication] isStatusBarHidden]) {
		if (hudViewFrame.origin.y < 20) {
			hudViewFrame.size.height -= 20 - hudViewFrame.origin.y;
			hudViewFrame.origin.y = 20;
		}
	}
	
	hudViewFrame = CGRectInset(hudViewFrame, 0, 5);
	hudViewFrame = CGRectIntegral(hudViewFrame);
    
    if (!CGRectEqualToRect(hudViewFrame, self.hudView.frame)) {
		self.hudView.frame = hudViewFrame;
	}
    
    hudBorderView.frame = CGRectInset(self.hudView.frame, borderInset.width, borderInset.height);
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

@end
