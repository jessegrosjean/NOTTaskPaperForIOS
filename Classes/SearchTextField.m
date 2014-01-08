//
//  SearchView.m
//  PlainText
//
//  Created by Jesse Grosjean on 12/23/10.
//

#import "SearchTextField.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "Button.h"


@implementation SearchTextField

- (void)refreshFromDefaults {
	self.font = [APP_VIEW_CONTROLLER font];
	self.textColor = [APP_VIEW_CONTROLLER inkColor];
	//self.placeholder = NSLocalizedString(@"Search", nil);

	[searchWithNoDot release];
	searchWithNoDot = [[Button buttonWithImage:[UIImage imageNamed:@"search_small.png"] accessibilityLabel:NSLocalizedString(@"Begin Search", nil) accessibilityHint:nil target:self action:@selector(becomeFirstResponder) edgeInsets:UIEdgeInsetsMake(0, 5, 0, 10)] retain];

	[searchWithDot release];
	searchWithDot = [[Button buttonWithImage:[UIImage imageNamed:@"search_small_active.png"] accessibilityLabel:NSLocalizedString(@"Begin Search", nil) accessibilityHint:nil target:self action:@selector(becomeFirstResponder) edgeInsets:UIEdgeInsetsMake(0, 5, 0, 10)] retain];

	self.leftView = searchWithNoDot;
	self.rightView = [Button buttonWithImage:[UIImage imageNamed:@"clear.png"] accessibilityLabel:NSLocalizedString(@"Clear", nil) accessibilityHint:nil target:self action:@selector(clearAndBecomeFirstResponder) edgeInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
	[self sizeToFit]; // creates subviews
	[self updateLeftRightViews];
	
	for (UILabel *each in [self subviews]) {
		if ([each isKindOfClass:[UILabel class]]) { // Placeholder text label
			each.textColor = [APP_VIEW_CONTROLLER inkColorByPercent:0.15];
		}
	}
}

- (id)init {
	self = [super initWithFrame:CGRectZero];
	self.returnKeyType = UIReturnKeySearch;
	self.borderStyle = UITextBorderStyleNone;
	self.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.autocorrectionType = UITextAutocorrectionTypeNo;
	self.leftViewMode = UITextFieldViewModeAlways;
	self.accessibilityLabel = NSLocalizedString(@"Search Field", nil);
	self.accessibilityTraits = UIAccessibilityTraitSearchField;
	[self refreshFromDefaults];	
	return self;
}

- (void)dealloc {
	[searchWithDot release];
	[searchWithNoDot release];
	[super dealloc];
}

- (void)updateLeftRightViews {
	if ([self.text length] > 0) {
		self.rightViewMode = UITextFieldViewModeAlways;
		self.leftView = searchWithDot;
	} else {
		self.rightViewMode = UITextFieldViewModeNever;
		self.leftView = searchWithNoDot;
	}
}

- (void)setText:(NSString *)aString {
	[super setText:aString];
	[self updateLeftRightViews];
}

- (void)clearAndBecomeFirstResponder {
	if ([self.delegate textFieldShouldClear:self]) {
		[self setText:@""];
		[self becomeFirstResponder];
	} 
}

- (CGSize)sizeThatFits:(CGSize)size {
	CGSize result = [super sizeThatFits:size];

	UIView *leftView = self.leftView;
	if (leftView) {
		CGFloat leftHeight = [leftView sizeThatFits:size].height;
		if (leftHeight > result.height) {
			result.height = leftHeight;
		}
	}
	
	UIView *rightView = self.rightView;
	if (rightView) {
		CGFloat rightHeight = [rightView sizeThatFits:size].height;
		if (rightHeight > result.height) {
			result.height = rightHeight;
		}
	}
	
	return result;
}

@end
