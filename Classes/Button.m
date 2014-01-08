//
//  Button.m
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//

#import "Button.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "PressIndicatorView.h"
#import "UIImage_Additions.h"

@implementation Button

+ (Button *)buttonWithImage:(UIImage *)image color:(UIColor *)color accessibilityLabel:(NSString *)accessibilityLabel accessibilityHint:(NSString *)accessibilityHint target:(id)target action:(SEL)action edgeInsets:(UIEdgeInsets)edgeInsets {
    Button *button = [Button buttonWithType:UIButtonTypeCustom];
	button.accessibilityLabel = accessibilityLabel;
	button.accessibilityHint = accessibilityHint;
	image = [UIImage colorizeImage:image color:color];
	button.imageEdgeInsets = edgeInsets;
	CGSize size = image.size;
	button.frame = CGRectMake(0, 0, edgeInsets.left + edgeInsets.right + size.width, edgeInsets.top + edgeInsets.bottom + size.height);
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:button action:@selector(pressGrow) forControlEvents:UIControlEventTouchDown];
	[button addTarget:button action:@selector(pressGrow) forControlEvents:UIControlEventTouchDragEnter];
	[button addTarget:button action:@selector(pressShrink) forControlEvents:UIControlEventTouchDragExit];
	[button addTarget:button action:@selector(pressShrink) forControlEvents:UIControlEventTouchUpInside];
	[button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
	return button;
}

+ (Button *)buttonWithImage:(UIImage *)image accessibilityLabel:(NSString *)accessibilityLabel accessibilityHint:(NSString *)accessibilityHint target:(id)target action:(SEL)action edgeInsets:(UIEdgeInsets)edgeInsets {
	Button *button = [Button buttonWithType:UIButtonTypeCustom];
	button.accessibilityLabel = accessibilityLabel;
	button.accessibilityHint = accessibilityHint;
	image = [UIImage colorizeImage:image color:[APP_VIEW_CONTROLLER inkColor]];
	button.imageEdgeInsets = edgeInsets;
	CGSize size = image.size;
	button.frame = CGRectMake(0, 0, edgeInsets.left + edgeInsets.right + size.width, edgeInsets.top + edgeInsets.bottom + size.height);
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:button action:@selector(pressGrow) forControlEvents:UIControlEventTouchDown];
	[button addTarget:button action:@selector(pressGrow) forControlEvents:UIControlEventTouchDragEnter];
	[button addTarget:button action:@selector(pressShrink) forControlEvents:UIControlEventTouchDragExit];
	[button addTarget:button action:@selector(pressShrink) forControlEvents:UIControlEventTouchUpInside];
	[button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
	return button;
}

+ (Button *)buttonWithTitle:(NSString *)title target:(id)target action:(SEL)action edgeInsets:(UIEdgeInsets)edgeInsets {
	Button *button = [Button buttonWithType:UIButtonTypeCustom];
	button.titleEdgeInsets = edgeInsets;
	[button setTitle:title forState:UIControlStateNormal];
	[button addTarget:button action:@selector(pressGrow) forControlEvents:UIControlEventTouchDown];
	[button addTarget:button action:@selector(pressGrow) forControlEvents:UIControlEventTouchDragEnter];
	[button addTarget:button action:@selector(pressShrink) forControlEvents:UIControlEventTouchDragExit];
	[button addTarget:button action:@selector(pressShrink) forControlEvents:UIControlEventTouchUpInside];
	[button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
	return button;
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    image = [UIImage colorizeImage:image color:[APP_VIEW_CONTROLLER inkColor]];
    [super setImage:image forState:state];
}

- (void)refreshFromDefaults {
	if (brightness == 0) {
		brightness = 1.0;
	}
	UIImage *image = [self imageForState:UIControlStateNormal];
	image = [UIImage colorizeImage:image color:[APP_VIEW_CONTROLLER inkColorByPercent:brightness]];
	[self setImage:image forState:UIControlStateNormal];
	[self setTitleColor:[APP_VIEW_CONTROLLER inkColor] forState:UIControlStateNormal];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
	if (newSuperview) {
		[self refreshFromDefaults];
	}
	[super willMoveToSuperview:newSuperview];
}

/*- (id)init { never getting called
	self = [super init];
	brightness = 0.8;
	[self refreshFromDefaults];
	[self sizeToFit];
	UIEdgeInsets reverseInsets = self.titleEdgeInsets;
	reverseInsets.top *= -1;
	reverseInsets.bottom *= -1;
	reverseInsets.left *= -1;
	reverseInsets.right *= -1;
	self.frame = UIEdgeInsetsInsetRect(self.frame, reverseInsets);
	return self;
}*/

@synthesize brightness;

- (void)setBrightness:(CGFloat)aFloat {
	brightness = aFloat;
	[self refreshFromDefaults];
}

- (void)setImage:(UIImage *)image {
    [self setImage:image forState:UIControlStateNormal];
}

- (void)pressGrow {
	UIWindow *window = self.window;
	UIView *pressIndicator = [window viewWithTag:35];
	if (!pressIndicator) {
		pressIndicator = [[[PressIndicatorView alloc] init] autorelease];
		pressIndicator.userInteractionEnabled = NO;
		pressIndicator.tag = 35;
		pressIndicator.alpha = 0.0;
		[window addSubview:pressIndicator];
	}
	
	CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, self.imageEdgeInsets);
	CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
	center = [self convertPoint:center toView:nil];
	pressIndicator.center = center;
	[UIView beginAnimations:@"pressIndicatorShow" context:NULL];
	[UIView setAnimationsEnabled:YES];
	[UIView setAnimationDuration:0.1];
	pressIndicator.alpha = 1.0;
	[UIView commitAnimations];
}

- (void)pressShrink {
	UIView *pressIndicator = [[self window] viewWithTag:35];
	[UIView beginAnimations:@"pressIndicatorHide" context:NULL];
	[UIView setAnimationsEnabled:YES];
	[UIView setAnimationDuration:0.1];
	pressIndicator.alpha = 0.0;
	[UIView commitAnimations];
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	if (DEBUG_DRAWING) {
		[[UIColor blueColor] set];
		UIRectFrame(self.bounds);
	}
}

@end
