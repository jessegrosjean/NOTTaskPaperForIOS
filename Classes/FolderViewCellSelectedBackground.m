//
//  FolderViewCellSelectedBackground.m
// PlainText
//
//  Created by Jesse Grosjean on 6/24/10.
//

#import "FolderViewCellSelectedBackground.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "UIView_Additions.h"
#import "BrowserView.h"
#import "FolderView.h"

@implementation FolderViewCellSelectedBackground

- (void)refreshFromDefaults {
	[self setNeedsDisplay];
	[self setNeedsLayout];
}

- (id)init {
	self = [super init];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	UIEdgeInsets ancestorPadding = self.ancestorPadding;
	ancestorPadding.top = 0;
	ancestorPadding.bottom = 0;
	
	CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, ancestorPadding);
	
	[[APP_VIEW_CONTROLLER inkColorByPercent:0.10] set];

	bounds.origin.y += 1;
	bounds.size.height -= 3;
	UIRectFill(bounds);
	
	UIView *each = self.superview;
	Class tableViewClass = [UITableView class];
	while (each != nil && ![each isKindOfClass:tableViewClass]) {
		each = [each superview];
	}
	
	UIColor *color = each.backgroundColor;
	if (!color) {
		color = [UIColor redColor];
	}
	
	CGFloat leading = [APP_VIEW_CONTROLLER leading];
	CGRect leftSlice;
	CGRectDivide(bounds, &leftSlice, &bounds, leading, CGRectMinXEdge);
	DrawFadeFunction(UIGraphicsGetCurrentContext(), leftSlice, [color CGColor], 0);
	
	CGRect rightSlice;
	CGRectDivide(bounds, &rightSlice, &bounds, leading, CGRectMaxXEdge);
	DrawFadeFunction(UIGraphicsGetCurrentContext(), rightSlice, [color CGColor], 3.141);
	
	
	if (DEBUG_DRAWING) {
		[[UIColor blueColor] set];
		UIRectFrame(self.bounds);
	}	
}

@end