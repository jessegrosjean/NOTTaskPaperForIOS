//
//  TextFieldViewController.m
//  PlainText
//
//  Created by Jesse Grosjean on 12/23/10.
//

#import "TextFieldViewController.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"

@implementation TextFieldViewController

- (id)init {
	self = [super init];
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if (textExpander) {
		[[NSNotificationCenter defaultCenter] removeObserver:textExpander];
		[textExpander setNextDelegate:nil];
		[textExpander release];
		textExpander = nil;
	}
	self.textField.delegate = nil;
	[super dealloc];
}

- (UITextField *)textField {
	return (id) self.view;
}

@synthesize delegate;

#pragma mark -
#pragma mark View lifecycle

- (void)textExpanderEnabledChanged:(NSNotification *)aNotification {
	BOOL iOS4OrLater = [APP_CONTROLLER isIOS4OrLater];
	UITextField *textField = self.textField;
	
	if (textExpander) {
		if (iOS4OrLater) {
			[[NSNotificationCenter defaultCenter] removeObserver:textExpander name:UIApplicationWillEnterForegroundNotification object:nil];
		}
		textField.delegate = self;
		[textExpander setNextDelegate:nil];
		[textExpander release];
		textExpander = nil;
	}
	
	if ([APP_VIEW_CONTROLLER textExpanderEnabled]) {
		textExpander = [[SMTEDelegateController alloc] init];
		[textExpander setNextDelegate:textField.delegate];
		textField.delegate = textExpander;
		if (iOS4OrLater) {
			[[NSNotificationCenter defaultCenter] addObserver:textExpander selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
		}
	}
}

- (void)loadView {
	[self textExpanderEnabledChanged:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textExpanderEnabledChanged:) name:TextExpanderEnabledChangedNotification object:nil];
}

#pragma mark -
#pragma mark TextField delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	return YES;
}

@end
