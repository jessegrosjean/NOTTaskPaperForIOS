//
//  SearchView.m
//  PlainText
//
//  Created by Jesse Grosjean on 4/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HUDSearchView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "SearchTextField.h"

@implementation HUDSearchView

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (SearchTextField *)searchTextField {
	if (!searchTextField) {
		searchTextField = [[[SearchTextField alloc] init] autorelease];
	}
	return searchTextField;
}

- (UIView *)hudView {
	return [self searchTextField];
}

- (void)show {
	[super show];
	[searchTextField becomeFirstResponder];
}

- (void)close {
	[searchTextField resignFirstResponder];
	[super close];
}

- (void)layoutSubviews {
	if ([searchTextField.text length] == 0) {
		searchTextField.text = @"Tips";
		[searchTextField sizeToFit]; // wrong height unless we give it some text.
		searchTextField.text = @"";
	} else {
		[searchTextField sizeToFit];
	}
	CGRect f = searchTextField.frame;
	f.size.width = (NSInteger) anchorView.frame.size.width * 0.8;
	//searchTextField.frame = f;
    
    hudViewFrame = f;
	[super layoutSubviews];
}

@end
