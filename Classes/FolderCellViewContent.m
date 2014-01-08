//
//  FolderCellViewContent.m
//  PlainText
//
//  Created by Jesse Grosjean on 3/4/11.
//

#import "FolderCellViewContent.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"

@implementation FolderCellViewContent

- (void)refreshFromDefaults {
	[self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)aFrame {
	self = [super initWithFrame:aFrame];
	self.contentMode = UIViewContentModeLeft;
	return self;
}

- (void)dealloc {
	[name release];
	[color release];
	[super dealloc];
}

@synthesize name;

- (void)setName:(NSString *)aString {
	[name autorelease];
	name = [aString retain];
	[self setNeedsDisplay];
}

@synthesize color;

- (void)setColor:(UIColor *)aColor {
	[color autorelease];
	color = [aColor retain];
	[self setNeedsDisplay];
}

- (void)setFrame:(CGRect)aRect {
	CGRect f = self.frame;
	if (!CGRectEqualToRect(aRect, f)) {
		if (!CGSizeEqualToSize(f.size, aRect.size)) {
			[self setNeedsDisplay];
		}
		[super setFrame:aRect];
	}	
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	ApplicationViewController *appViewController = APP_VIEW_CONTROLLER;
	UIFont *font = [appViewController font];
	CGRect bounds = self.bounds;
	CGSize size = [name sizeWithFont:font forWidth:bounds.size.width lineBreakMode:UILineBreakModeTailTruncation];
	CGRect textRect = CGRectMake(bounds.origin.x,
								 floor((bounds.size.height - size.height) / 2.0),
		//						 floor((size.height - bounds.origin.y) - (size.height / 2.0)),
								 size.width,
								 size.height);
	
	[color set];
	[name drawInRect:textRect withFont:font lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
	//cell.textLabel.highlightedTextColor = cell.textLabel.textColor;
	//cell.textLabel.font = [appViewController font];
	//cell.textLabel.text = displayName;
}

@end
