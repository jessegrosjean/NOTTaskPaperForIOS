//
//  MarginScrollView.m
//  PlainText
//
//  Created by Jesse Grosjean on 12/16/10.
//

#import "MarginScrollView.h"


@implementation MarginScrollView

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	self.multipleTouchEnabled = YES;
	self.scrollsToTop = NO;
    
    UISwipeGestureRecognizer *recognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)] autorelease];
    recognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:recognizer];
    
    recognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)] autorelease];
    [recognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    recognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:recognizer];
    
	return self;
}

- (void)dealloc {
	[super dealloc];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	
	if ([touches count] == 1) {
		[[self superview] singleTapInMargin:self yLocation:location.y];
	} else {
		[[self superview] doubleTapInMargin:self yLocation:location.y];
	}
	
	[super touchesEnded:touches withEvent:event];
}

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)gestureRecognizer {
    [[self superview] handleSwipeRight:gestureRecognizer];
}

- (void)handleSwipeLeft:(UISwipeGestureRecognizer *)gestureRecognizer {
    [[self superview] handleSwipeLeft:gestureRecognizer];
}

@end
