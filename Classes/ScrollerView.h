//
//  Scroller.h
// PlainText
//
//  Created by Jesse Grosjean on 6/24/10.
//


@interface ScrollerView : UIView {
	//CGRect thumb;
	BOOL tracking;
	BOOL canceledFirst;
	UIImageView *thumbImageView;
	//UIImage *thumbImage;
}

- (void)updateScrollerViewFromScrollView:(UIScrollView *)scrollView fadeInPossible:(BOOL)fadeInPossible;

- (BOOL)tracking;

@end
