//
//  IFTextViewTableView.h
//  Thunderbird
//
//  Created by Craig Hockenberry on 3/1/09.
//  Copyright 2009 The Iconfactory. All rights reserved.
//
//
//	A subclass of UITableView that works around the problems with the loupe
//	in a UITextField embedded in a UITableViewCell. For more information,
//	please refer to this thread on the Apple Developer Forums:
//
//	<https://devforums.apple.com/message/10575>
//
//	Thanks go to Glen Low of Pixelglow Software <http://www.pixelglow.com/>
//	for figuring this out, and Tom Saxton (@tomsaxton) for pointing me to it.
//

#import <UIKit/UIKit.h>


@interface IFTextViewTableView : UITableView
{
	UIView* _trackedFirstResponder;
	BOOL _handledEvent;
}

- (UIView*)safeHitTest:(CGPoint)point withEvent:(UIEvent*)event;

@end
