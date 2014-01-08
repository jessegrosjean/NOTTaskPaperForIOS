//
//  TitleBar.h
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//

#import "Bar.h"

@class PathViewWrapper;

@interface Titlebar : Bar {
	PathViewWrapper *pathViewWrapper;
	UIButton *leftButton;
	CGFloat originalLeftWidth;
	UIEdgeInsets originalLeftInsets;
	UIButton *rightButton;
	CGFloat originalRightWidth;
	UIEdgeInsets originalRightInsets;
}

@property (nonatomic, readonly) PathViewWrapper *pathViewWrapper;
@property (nonatomic, retain) UIButton *leftButton;
@property (nonatomic, retain) UIButton *rightButton;

- (void)setPathViewWrapper:(PathViewWrapper *)aPathViewWrapper becomeFirstResponder:(BOOL)becomeFirstResponder;

@end
