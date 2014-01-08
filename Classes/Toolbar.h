//
//  Toolbar.h
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//

#import "Bar.h"


@interface Toolbar : Bar {
	NSArray *toolbarItems;
	CGFloat leftWidth;
	UIEdgeInsets leftInsets;
	CGFloat rightWidth;
	UIEdgeInsets rightInsets;
}

+ (UIView *)flexibleSpace;

@property (nonatomic, retain) NSArray *toolbarItems;

- (void)setToolbarItems:(NSArray *)items animated:(BOOL)animated;

@end
