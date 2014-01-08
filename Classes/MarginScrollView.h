//
//  MarginScrollView.h
//  PlainText
//
//  Created by Jesse Grosjean on 12/16/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//


@interface MarginScrollView : UIScrollView {

}

@end

@interface NSObject (MarginScrollViewAdditions)
- (void)singleTapInMargin:(MarginScrollView *)aMargin yLocation:(CGFloat)yLocation;
- (void)doubleTapInMargin:(MarginScrollView *)aMargin yLocation:(CGFloat)yLocation;
- (void)singleTapInMarginLocation:(CGFloat)yLocation isLeftMargin:(BOOL)isLeftMargin;
- (void)doubleTapInMarginLocation:(CGFloat)yLocation isLeftMargin:(BOOL)isLeftMargin;
- (void)handleSwipeRight:(UISwipeGestureRecognizer *)gestureRecognizer;
- (void)handleSwipeLeft:(UISwipeGestureRecognizer *)gestureRecognizer;

@end
