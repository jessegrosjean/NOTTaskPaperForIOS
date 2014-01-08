//
//  FolderView.m
// PlainText
//
//  Created by Jesse Grosjean on 6/24/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "FolderView.h"
#import "ApplicationViewController.h"
#import "UIScrollView_Additions.h"
#import "ApplicationController.h"
#import "UIView_Additions.h"

@implementation FolderView

- (void)refreshFromDefaults {
	if (IS_IPAD) {
		self.backgroundColor = [APP_VIEW_CONTROLLER inkColorByPercent:0.03];
	} else {
		self.backgroundColor = [APP_VIEW_CONTROLLER paperColor];
	}
	self.rowHeight = (NSInteger) ([APP_VIEW_CONTROLLER leading] * 2);

	[self setNeedsLayout];
	
	if (self.dataSource) {
		[self reloadData];
	}
}

- (id)init {
	self = [super init];
	self.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
	self.canCancelContentTouches = NO;
	self.alwaysBounceVertical = YES;
    self.sectionHeaderHeight = 0;
    self.sectionFooterHeight = 0;
	self.scrollsToTop = YES;

	[self refreshFromDefaults];
		
	return self;
}

- (void)setContentOffset:(CGPoint)offset {
	[super setContentOffset:offset];
}

@synthesize padding;

- (void)setPadding:(UIEdgeInsets)newPadding {
	padding = newPadding;
	[self setNeedsLayout];
	[self.subviews makeObjectsPerformSelector:@selector(setNeedsLayout)];
}

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition {
	[super selectRowAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition];
}

- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
	[super deselectRowAtIndexPath:indexPath animated:animated];
}

- (void)layoutSubviews {
	NSInteger newRowHeight = (NSInteger) ([APP_VIEW_CONTROLLER leading] * 2);
	if (self.rowHeight != newRowHeight) {
		[self refreshFromDefaults];
	}
	[super layoutSubviews];
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	if (DEBUG_DRAWING) {
		[[UIColor orangeColor] set];
		UIRectFrame(self.bounds);
	}
}

@end