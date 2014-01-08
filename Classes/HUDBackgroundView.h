//
//  HUDView.h
//  PlainText
//
//  Created by Jesse Grosjean on 4/28/11.
//

#import <Foundation/Foundation.h>


typedef enum _HUDViewPosition {
	PositionUp,
	PositionDown,
	PositionLeft,
	PositionUpLeft,
	PositionDownLeft,
	PositionRight,
	PositionUpRight,
	PositionDownRight,
	PositionCentered,
} HUDAnchorRelativePosition;

@interface HUDBackgroundView : UIView {
	NSUInteger showing;
	CGPoint offsetPosition;
	CGSize borderInset;
	HUDAnchorRelativePosition anchorRelativePosition;
	UIView *anchorView;
	UIView *hudBorderView;
    CGRect hudViewFrame;
}

@property(readonly, nonatomic) UIView *hudView;
@property(retain, nonatomic) UIView *anchorView;
@property(assign, nonatomic) HUDAnchorRelativePosition anchorRelativePosition;
@property(assign, nonatomic) CGPoint offsetPosition;
@property(assign, nonatomic) CGSize borderInset;

- (void)show;
- (void)close;
- (void)closeIfShowing;
- (void)didClose;

@end
