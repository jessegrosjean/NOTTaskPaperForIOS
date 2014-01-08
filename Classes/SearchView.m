//
//  SearchView.m
//  PlainText
//
//  Created by Jesse Grosjean on 12/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "SearchView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "Button.h"
#import "UIImage_Additions.h"

@implementation SearchView

- (void)refreshFromDefaults {
	self.font = [APP_VIEW_CONTROLLER font];
	self.textColor = [APP_VIEW_CONTROLLER inkColor];
	self.placeholder = NSLocalizedString(@"Search", nil);
	self.leftView = [Button buttonWithImage:[UIImage imageNamed:@"search_small.png"] accessibilityLabel:NSLocalizedString(@"Search", nil) accessibilityHint:nil target:self action:@selector(becomeFirstResponder) edgeInsets:UIEdgeInsetsMake(0, 5, 0, 10)];
	[self sizeToFit]; // creates subviews
	
	for (UILabel *each in [self subviews]) {
		if ([each isKindOfClass:[UILabel class]]) {
			each.textColor = [APP_VIEW_CONTROLLER inkColorByPercent:0.5];
		}        
	}
}

- (void)dealloc {
    [pulldownButton release];
    [super dealloc];
}

- (id)init {
	self = [super initWithFrame:CGRectZero];
	self.returnKeyType = UIReturnKeySearch;
	self.borderStyle = UITextBorderStyleNone;
	self.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.autocorrectionType = UITextAutocorrectionTypeNo;
	self.leftViewMode = UITextFieldViewModeAlways;
    
	[self refreshFromDefaults];	
	return self;
}

- (void)menu {
    [self.delegate performSelector:@selector(menu)];
}

- (void)clearAndBecomeFirstResponder {
	if ([self.delegate textFieldShouldClear:self]) {
		[self setText:@""];
		[self becomeFirstResponder];
	} 
}

- (BOOL)resignFirstResponder {
    if ([self isFirstResponder]) {
        if (self.text.length == 0) {
            [self.delegate performSelector:@selector(updateSearchText:) withObject:@""];  
        }
    }
    return [super resignFirstResponder];
}


@end
