//
//  UIScrollView_Additions.m
//  PlainText
//
//  Created by Jesse Grosjean on 5/25/10.
//

#import "UIScrollView_Additions.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "NSObject_Additions.h"
#import "UIImage_Additions.h"
#import "GradientFadeView.h"

void MyFaderLayoutFunction(UIScrollView *scrollView);

@implementation UITableView (Additions)

+ (void)load {
    if (self == [UITableView class]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		//[UITableView replaceMethod:@selector(layoutSubviews) withMethod:@selector(my_layoutSubviews)];
		[pool release];
    }
}

- (void)my_layoutSubviews {
	MyFaderLayoutFunction(self);
}

@end

@implementation UIScrollView (Additions)

+ (void)load {
    if (self == [UIScrollView class]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		//[UIScrollView replaceMethod:@selector(layoutSubviews) withMethod:@selector(my_layoutSubviews)];
		//[UIScrollView replaceMethod:NSSelectorFromString([@"_adjustContent" stringByAppendingString:@"OffsetIfNecessary"]) withMethod:@selector(my_adjustContentOffsetIfNecessary)];		
		[pool release];
    }
}

- (void)my_adjustContentOffsetIfNecessary {
	[self my_adjustContentOffsetIfNecessary];
	
	/*if (self.dragging || self.decelerating) {
	 [self my_adjustContentOffsetIfNecessary];
	 return;
	 }
	 
	 AccordionView *accordianHeaderView = (id) [self viewWithTag:304];
	 if (accordianHeaderView) {
	 CGFloat height = [accordianHeaderView sizeThatFits:CGSizeMake(accordianHeaderView.frame.size.width, CGFLOAT_MAX)].height;
	 if (self.contentOffset.y != -height) {
	 [self setContentOffset:CGPointMake(self.contentOffset.x, -height) animated:NO];
	 }
	 } else {
	 [self my_adjustContentOffsetIfNecessary];
	 }*/
}

- (void)installTopFaderWithHeight:(CGFloat)height {
	GradientFadeView *topFader = (id) [self viewWithTag:300];
	if (!topFader) {
		topFader = [[[GradientFadeView alloc] initWithFrame:CGRectMake(0, 0, 0, height)] autorelease];
		topFader.tag = 300;
		[self addSubview:topFader];
	}
	CGRect f = topFader.frame;	
	f.size.height = height;
	topFader.frame = f;
}

- (void)uninstallTopFader {
	[[self viewWithTag:300] removeFromSuperview];
}

- (void)installBottomFaderWithHeight:(CGFloat)height {
	GradientFadeView *bottomFader = (id) [self viewWithTag:301];
	if (!bottomFader) {
		bottomFader = [[[GradientFadeView alloc] initWithFrame:CGRectMake(0, 0, 0, height)] autorelease];
		bottomFader.tag = 301;
		bottomFader.flipped = YES;
		[self addSubview:bottomFader];
	}
	CGRect f = bottomFader.frame;	
	f.size.height = height;
	bottomFader.frame = f;
}

- (void)uninstallBottomFader {
	[[self viewWithTag:301] removeFromSuperview];
}

- (void)my_layoutSubviews {
	MyFaderLayoutFunction(self);
}

@end

void MyFaderLayoutFunction(UIScrollView *scrollView) {
	[scrollView my_layoutSubviews];
	
	CGRect bounds = scrollView.bounds;
	CGSize contentSize = scrollView.contentSize;
	CGPoint contentOffset = scrollView.contentOffset;
		
	UIImageView *topFader = (id) [scrollView viewWithTag:300];
	if (topFader) {
		if (contentOffset.y <= 1) {
			topFader.frame = CGRectMake(bounds.origin.x, contentOffset.y, 0, topFader.frame.size.height);
		} else {
			if (topFader.frame.size.width == 0) {
				[topFader setNeedsDisplay];
			}
			topFader.frame = CGRectMake(bounds.origin.x, contentOffset.y, bounds.size.width, topFader.frame.size.height);
			[topFader.superview bringSubviewToFront:topFader];
		}
	}
	
	UIImageView *bottomFader = (id) [scrollView viewWithTag:301];
	if (bottomFader) {
		if (contentOffset.y + bounds.size.height >= contentSize.height) {
			bottomFader.frame = CGRectMake(bounds.origin.x, contentOffset.y + bounds.size.height - bottomFader.frame.size.height, 0, bottomFader.frame.size.height);
		} else {
			if (bottomFader.frame.size.width == 0) {
				[bottomFader setNeedsDisplay];
			}
			bottomFader.frame = CGRectMake(bounds.origin.x, contentOffset.y + bounds.size.height - bottomFader.frame.size.height, bounds.size.width, bottomFader.frame.size.height);
			[bottomFader.superview bringSubviewToFront:bottomFader];
		}
	}
}