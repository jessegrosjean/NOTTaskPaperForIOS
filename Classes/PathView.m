//
//  PathTextField.m
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//

#import "PathView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "UIImage_Additions.h"
#import "UIView_Additions.h"
#import "MenuView.h"
#import "Button.h"

@implementation PathView

- (void)refreshFromDefaults {
	self.font = [APP_VIEW_CONTROLLER font];
	self.textColor = [APP_VIEW_CONTROLLER inkColor];
	self.keyboardAppearance = [APP_VIEW_CONTROLLER keyboardAppearance];
	self.contentMode = UIViewContentModeCenter;
	self.placeholder = nil;
	self.rightView = [[[UIImageView alloc] initWithImage:[UIImage colorizeImage:[UIImage imageNamed:@"pulldown.png"] color:[APP_VIEW_CONTROLLER inkColorByPercent:0.15]]] autorelease];
	self.rightView.contentMode = UIViewContentModeCenter;
	self.rightViewMode = UITextFieldViewModeUnlessEditing;
	[self sizeToFit];
}

- (id)init {
	self = [super initWithFrame:CGRectZero];
	self.returnKeyType = UIReturnKeyDone;
	self.textAlignment = UITextAlignmentCenter;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(allCapsHeadingsChangedNotification:) name:AllCapsHeadingsChangedNotification object:nil];
	[self refreshFromDefaults];
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)allCapsHeadingsChangedNotification:(NSNotification *)aNotification {
	[self setNeedsDisplay];
}

- (void)setFrame:(CGRect)aFrame {
	[super setFrame:aFrame];
	[self setNeedsDisplay];
}

- (BOOL)becomeFirstResponder {
	if ([self.superview respondsToSelector:@selector(pathViewBecommingFirstResponder)]) {
		[self.superview performSelector:@selector(pathViewBecommingFirstResponder)];
	}
	[self setNeedsDisplay];
	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
	if ([self.superview respondsToSelector:@selector(pathViewResigningFirstResponder)]) {
		[self.superview performSelector:@selector(pathViewResigningFirstResponder)];
	}
	[self setNeedsDisplay];
	return [super resignFirstResponder];
}

- (void)selectAllWithNoMenuController:(id)sender {
	[self selectAll:sender];
	[UIMenuController sharedMenuController].menuVisible = NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(promptForReplace:)) return NO;
	return [super canPerformAction:action withSender:sender];
}

- (void)didAddSubview:(UIView *)subview {
	if ([subview isKindOfClass:[UILabel class]]) {
		subview.hidden = YES;
	}
	[super didAddSubview:subview];
}

- (void)setTextColor:(UIColor *)textColor {
	[super setTextColor:textColor];
	[self setNeedsDisplay];
}

- (void)setText:(NSString *)aString {
	[super setText:aString];
	[self setNeedsDisplay];
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds {
	CGFloat rightWidth = [self.rightView frame].size.width;
	CGFloat textWidth = [[self.text uppercaseString] sizeWithFont:self.font forWidth:bounds.size.width - rightWidth lineBreakMode:UILineBreakModeTailTruncation].width;
	CGFloat extra = bounds.size.width - (textWidth + rightWidth);
	CGRect r = CGRectMake(textWidth + (extra / 2) + 10, CGRectGetMinY(bounds), rightWidth, CGRectGetHeight(bounds));
	return CGRectIntegral(r);
}

- (void)drawRect:(CGRect)rect {
	if ([self isFirstResponder]) {
		
	} else {
		[self.textColor set];
		if ([APP_VIEW_CONTROLLER allCapsHeadings]) {
			[[self.text uppercaseString] drawInRect:self.bounds withFont:self.font lineBreakMode:UILineBreakModeTailTruncation alignment:self.textAlignment];
		} else {
			[self.text drawInRect:self.bounds withFont:self.font lineBreakMode:UILineBreakModeTailTruncation alignment:self.textAlignment];
		}
	}
}

@end
