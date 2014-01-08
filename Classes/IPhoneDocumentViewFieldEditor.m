//
//  IPhoneDocumentViewFieldEditor.m
//  Documents
//
//  Created by Jesse Grosjean on 12/18/09.
//

#import "IPhoneDocumentViewFieldEditor.h"
#import "TaskView.h"

#import "ApplicationController.h"
#import "ApplicationViewController.h"
#import "KeyboardAccessoryView.h"

@implementation IPhoneDocumentViewFieldEditor

+ (IPhoneDocumentViewFieldEditor *)sharedInstance {
	static id sharedInstance = nil;
	if (sharedInstance == nil) {
		sharedInstance = [[self alloc] init];
	}
    ((IPhoneDocumentViewFieldEditor *)sharedInstance).backgroundColor = APP_VIEW_CONTROLLER.paperColor;
	return sharedInstance;
}

- (id)initWithFrame:(CGRect)aFrame {
	if (self = [super initWithFrame:aFrame]) {
		self.scrollEnabled = NO;
		self.bounces = NO;
		self.opaque = YES;
		self.clipsToBounds = NO;
        
	}
	return self;
}

- (void)dealloc {
	[placeholderText release];
	[super dealloc];
}

/*
- (id)undoManagerForWebView:(id)webView { // Hack to turn off default undo support in UITextView.
	id undoManager = [super undoManagerForWebView:webView];
	return undoManager;
}
*/

- (BOOL)becomeFirstResponder {
    if (IS_IPAD) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:ExtendedKeyboardDefaultsKey]) {
            KeyboardAccessoryView *accessoryView = [[KeyboardAccessoryView alloc] init];
            accessoryView.target = (id) self;
            self.inputAccessoryView = accessoryView;
        } else {
            self.inputAccessoryView = nil;
        }
    }
    
	return [super becomeFirstResponder];
}

- (void)setText:(NSString *)aString {
	[super setText:aString];
	[self setNeedsDisplay];
}

@synthesize uncommitedChanges;
@synthesize placeholderText;

- (void)setPlaceholderText:(NSString *)aString {
	[placeholderText release];
	placeholderText = [aString retain];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	if (placeholderText != nil && [self.text length] == 0) {
		[[UIColor colorWithWhite:0.85 alpha:1.0] set];
		CGRect b = CGRectInset(self.bounds, 8, 8);
		b.origin.x += 3;
		b.size.width -= 3;
        [[APP_VIEW_CONTROLLER inkColorByPercent:0.30] set];
		[placeholderText drawInRect:b withFont:self.font];
	}
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	UIView *hit = [super hitTest:point withEvent:event];
	
	if (!hit) { // UITextView Seems to ignore subviews that are outside of bounds... so force hit check against them.
		for (UIView *each in self.subviews) {
			CGPoint p = [self convertPoint:point toView:each];
			each = [each hitTest:p withEvent:event];
			if (each) {
				return each;
			}
		}
	}
	
	return hit;
}

- (void)scrollRectToVisibleInContainingScrollView {
}

- (void)setContentOffset:(CGPoint)aContentOffset {
}

@end
