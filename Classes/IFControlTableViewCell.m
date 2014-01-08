//
//  IFControlTableViewCell.m
//  Thunderbird
//
//  Created by Craig Hockenberry on 4/12/08.
//  Copyright 2008 The Iconfactory. All rights reserved.
//

#import "IFControlTableViewCell.h"
#import "ApplicationViewController.h"


#define kCellHorizontalOffset 8.0f

@implementation IFControlTableViewCell

@synthesize view;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		self.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	}
	return self;
}

- (void)setView:(UIView *)newView
{
	[view removeFromSuperview];

	view = [newView retain];
	[self.contentView addSubview:view];
	
	[self layoutSubviews];
}

- (void)layoutSubviews
{	
	[[self textLabel] sizeToFit];
	CGRect textFrame = self.textLabel.frame;
	
	[super layoutSubviews];
	
	CGRect contentRect = [self.contentView bounds];
	CGRect viewRect = [view bounds];
	
	if ((view.autoresizingMask & UIViewAutoresizingFlexibleWidth) != 0) {
		viewRect.size.width = contentRect.size.width - (textFrame.size.width + 30);
	}
	
	CGRect viewFrame = CGRectMake(contentRect.size.width - viewRect.size.width - kCellHorizontalOffset,
								  floorf((contentRect.size.height - viewRect.size.height) / 2.0f),
								  viewRect.size.width,
								  viewRect.size.height);
	view.frame = viewFrame;
}

- (void)dealloc
{
	[view release];
	
	[super dealloc];
}

@end
