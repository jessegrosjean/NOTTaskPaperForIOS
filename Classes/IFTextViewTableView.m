//
//  IFTextViewTableView.m
//  Thunderbird
//
//  Created by Craig Hockenberry on 3/1/09.
//  Copyright 2009 The Iconfactory. All rights reserved.
//
//	A subclass of UITableView that works around the problems with the loupe
//	"stalling" in a UITextField embedded in a UITableViewCell. For more information,
//	please refer to this thread on the Apple Developer Forums:
//
//	<https://devforums.apple.com/message/10575>
//
//	Thanks go to Glen Low of Pixelglow Software <http://www.pixelglow.com/>
//	for figuring this out, and Tom Saxton (@tomsaxton) for pointing me to it.
//

#import "IFTextViewTableView.h"
#import "ApplicationViewController.h"


@implementation IFTextViewTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
	self = [super initWithFrame:frame style:style];
	return self;
}

- (UIView*)safeHitTest:(CGPoint)point withEvent:(UIEvent*)event
{
	// reimplements hitTest:withEvent: which in the case of UITableView hides the presence of certain cells and subviews
	for (UIView* subview in self.subviews)
	{
		UIView* hitTest = [subview hitTest:[self convertPoint:point toView:subview] withEvent:event];
		if (hitTest)
			return hitTest;
	}

	return nil;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	UIView* hitView = [self safeHitTest:[touches.anyObject locationInView:self] withEvent:event];
	if ([hitView isFirstResponder])
	{
		if (!_trackedFirstResponder)
		{
			_trackedFirstResponder = hitView;
			[_trackedFirstResponder touchesBegan:touches withEvent:event];
		}
	}
	else
		[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	if (_trackedFirstResponder && !_handledEvent)
	{
		_handledEvent = YES;
		[_trackedFirstResponder touchesMoved:touches withEvent:event];
		_handledEvent = NO;
	}
	else
		[super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	if (_trackedFirstResponder && !_handledEvent)
	{
		_handledEvent = YES;
		[_trackedFirstResponder touchesEnded:touches withEvent:event];
		_handledEvent = NO;

		_trackedFirstResponder = nil;
	}
	else
		[super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
	if (_trackedFirstResponder && !_handledEvent)
	{
		_handledEvent = YES;
		[_trackedFirstResponder touchesCancelled:touches withEvent:event];
		_handledEvent = NO;

		_trackedFirstResponder = nil;
	}
	else
		[super touchesCancelled:touches withEvent:event];
}

@end
