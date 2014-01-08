//
//  FolderViewCell.m
//  PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "FolderViewCell.h"
#import "FolderViewCellDirectoryAccessoryView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "FolderCellViewContent.h"
#import "UIView_Additions.h"
#import "ShadowMetadata.h"
#import "PathOperation.h"
#import "BrowserView.h"
#import "FolderView.h"
/*
@interface UITableViewCellDeleteConfirmationControl : UIControl
{
    BOOL _visible;
}

+ (struct CGSize)defaultSizeForTitle:(id)arg1;
- (id)initWithTitle:(id)arg1;
- (struct CGSize)defaultSize;
- (id)hitTest:(struct CGPoint)arg1 withEvent:(id)arg2;
- (BOOL)beginTrackingWithTouch:(id)arg1 withEvent:(id)arg2;
- (BOOL)continueTrackingWithTouch:(id)arg1 withEvent:(id)arg2;
- (void)endTrackingWithTouch:(id)arg1 withEvent:(id)arg2;
- (void)cancelTrackingWithEvent:(id)arg1;
@property(nonatomic, getter=isVisible) BOOL visible;
- (void)setVisible:(BOOL)arg1 animated:(BOOL)arg2;
- (void)layoutSubviews;
- (void)removeFromSuperview;

@end

@implementation UITableViewCellDeleteConfirmationControl (Additions)

+ (void)load {
	if (self == [UITableViewCellDeleteConfirmationControl class]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[UITableViewCellDeleteConfirmationControl replaceMethod:@selector(setVisible:animated:) withMethod:@selector(my_setVisible:animated:)];
		[pool release];
	}
}

- (void)my_setVisible:(BOOL)arg1 animated:(BOOL)arg2 {
	[self my_setVisible:arg1 animated:arg2];
}

@end*/

@implementation FolderViewCell

- (void)refreshFromDefaults {
	[[self selectedBackgroundView] refreshFromDefaults];
	[self setNeedsDisplay];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	if (self) {
		CGRect frame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
		frame.size.height--;
		folderCellViewContent = [[FolderCellViewContent alloc] initWithFrame:frame];
		folderCellViewContent.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = APP_VIEW_CONTROLLER.paperColor;
		[self.contentView addSubview:folderCellViewContent];
	}
	return self;
}

@synthesize folderCellViewContent;
	 
- (void)prepareForReuse {
	[super prepareForReuse];
	showingDeleteConfirmation = NO;
	/*self.highlighted = NO;
	self.selected = NO;
	[self.selectedBackgroundView removeFromSuperview];
	[self setNeedsLayout];
	[self setNeedsDisplay];*/
}

- (NSString *)accessibilityLabel {
	if (self.accessoryView != nil) {
		return [NSString stringWithFormat:@"%@, %@", folderCellViewContent.name, NSLocalizedString(@"folder", nil)];
	} else {
		return [NSString stringWithFormat:@"%@, %@", folderCellViewContent.name, NSLocalizedString(@"document", nil)];
	}
}

#define SPACE 10

- (void)setFrame:(CGRect)aRect {
	[super setFrame:aRect];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	UIEdgeInsets ancestorPadding = self.ancestorPadding;
	ancestorPadding.top = 0;
	ancestorPadding.bottom = 0;
	CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, ancestorPadding);
		
	static Class deleteButtonClass = nil;
	if (!deleteButtonClass) {
		deleteButtonClass = [NSClassFromString([@"UITableViewCellDelete" stringByAppendingString:@"ConfirmationControl"]) retain];
	}
	
	UIView *deleteButton = [self firstSubviewOfClass:deleteButtonClass];
	UIView *deleteButtonConfirmationControl = [deleteButton.subviews lastObject];
	UIView *selectedBackgroundView = self.selectedBackgroundView;
	UIView *backgroundView = self.backgroundView;
	UIView *contentView = self.contentView;
	UIView *accessoryView = self.accessoryView;
	
	CGRect contentViewFrame = contentView.frame;
	CGRect accessoryFrame = accessoryView.frame;

	if (!accessoryView) {
		accessoryFrame = CGRectZero;
	} else if (!accessoryView.superview) {
		[self addSubview:accessoryView];
		[self sendSubviewToBack:[self accessoryView]];
	}
	
	//textFrame.origin.x = bounds.origin.x;
	//textFrame.origin.y = round((bounds.size.height - textFrame.size.height) / 2.0);
	//textFrame.size.width = bounds.size.width - accessoryFrame.size.width;

	accessoryFrame.origin.x = CGRectGetMaxX(bounds) - accessoryFrame.size.width;
	accessoryFrame.origin.y = round((bounds.size.height - accessoryFrame.size.height) / 2.0);
	
	if (accessoryFrame.size.width > 0) {
		// contentViewFrame.size.width -= SPACE;
	}
		
	if (showingDeleteConfirmation) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDuration:0];
		CGRect deleteFrame = deleteButton.frame;
		deleteFrame.origin.x = CGRectGetMaxX(bounds) - deleteFrame.size.width;
		deleteFrame.origin.x += 6;
		deleteFrame.origin.y = round((bounds.size.height - deleteFrame.size.height) / 2.0);
		deleteButton.frame = deleteFrame;
		contentViewFrame.size.width = deleteFrame.origin.x;
		//contentViewFrame.size.width -= (CGRectGetMaxX(contentViewFrame) - CGRectGetMinX(deleteFrame));
		//textFrame.size.width -= (CGRectGetMaxX(textFrame) - CGRectGetMinX(deleteFrame));
		[UIView commitAnimations];
	}
	
	//textLabel.frame = textFrame;
	accessoryView.frame = accessoryFrame;
	contentView.frame = contentViewFrame;	
	backgroundView.frame = self.bounds;
	selectedBackgroundView.frame = self.bounds;	
		
	if ([APP_VIEW_CONTROLLER animatingKeyboardOrDocumentFocusMode]) {
		NSArray *allMySubviews = [self allMySubviews];
		for (UIView *each in allMySubviews) {
			if (each != self && each != deleteButtonConfirmationControl) {
				[each.layer removeAllAnimations];
			}
		}
	}
}

- (void)willTransitionToState:(UITableViewCellStateMask)state {
	[super willTransitionToState:state];
	showingDeleteConfirmation = (state & UITableViewCellStateShowingDeleteConfirmationMask) != 0;
}

- (void)setBackgroundColor:(UIColor *)aColor {
	[super setBackgroundColor:aColor];
	[folderCellViewContent setBackgroundColor:aColor];
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];

	ApplicationViewController *appViewController = APP_VIEW_CONTROLLER;
	
	UIEdgeInsets ancestorPadding = self.ancestorPadding;
	ancestorPadding.top = 0;
	ancestorPadding.bottom = 0;
	
	CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, ancestorPadding);
	bounds.origin.y += bounds.size.height - 1;
	bounds.size.height = 1;
	[[appViewController inkColorByPercent:0.15] set];
	UIRectFill(bounds);
		
	if (DEBUG_DRAWING) {
		[[UIColor greenColor] set];
		UIRectFrame(self.bounds);
	}
}

@end
