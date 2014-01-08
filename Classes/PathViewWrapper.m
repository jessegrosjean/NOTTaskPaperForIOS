//
//  PathViewWrapper.m
//  PlainText
//
//  Created by Jesse Grosjean on 5/31/11.
//

#import "PathViewWrapper.h"
#import "PathView.h"
#import "Button.h"


@implementation PathViewWrapper

- (id)init {
    self = [super init];
    if (self) {
		pathView = [[[PathView alloc] init] autorelease];
		[self addSubview:pathView];
		popupMenuButton = [Button buttonWithTitle:@"" target:nil action:NULL edgeInsets:UIEdgeInsetsZero];
		popupMenuButton.accessibilityLabel = NSLocalizedString(@"Popup Menu", nil);
		[self addSubview:popupMenuButton];
		[self layoutSubviews];
		
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	[self layoutSubviews];
}

@synthesize pathView;

- (void)pathViewBecommingFirstResponder {
	popupMenuButton.userInteractionEnabled = NO;
}

- (void)pathViewResigningFirstResponder {
	popupMenuButton.userInteractionEnabled = YES;
}

@synthesize popupMenuButton;

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect bounds = self.bounds;
	CGRect pathViewFrame = bounds;
    
    if (isnan(pathViewFrame.size.width)) {
        pathViewFrame.size.width = 0;
    }
    if (isnan(pathViewFrame.size.height)) {
        pathViewFrame.size.height = 0;
    }
    
	pathViewFrame.size.height = pathView.frame.size.height;
	pathViewFrame.origin.y += round((bounds.size.height - pathViewFrame.size.height) / 2.0);
	pathView.frame = CGRectIntegral(pathViewFrame);	
	popupMenuButton.frame = bounds;
}

- (void)dealloc {
    [super dealloc];
}

@end
