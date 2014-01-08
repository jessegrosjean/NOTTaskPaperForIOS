//
//  PasscodeViewController.m
//  Secretnote
//
//  Created by Kim Young Hoo on 10. 10. 9..
//  Copyright 2010 Codingrobots. All rights reserved.
//

#import "PasscodeViewController.h"
#import "PasscodeManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import "ApplicationViewController.h"
#import "ApplicationController.h"

@interface PasscodeViewController(/*Private*/)

- (void)close;
- (void)onFourthInput:(NSString *)fourthString;
- (void)clearTextFeilds;
- (void)showConfirm;
- (void)checkConfirm;
- (void)checkPasscode;

@end


@implementation PasscodeViewController

@synthesize viewState;

- (void)setViewState:(PasscodeViewState)aViewState {
	viewState = aViewState;
	
	switch (viewState) {
		case PasscodeSetNewPasscode: {
			self.title = NSLocalizedString(@"Set Passcode", nil);
			self.descriptionLabel.text = NSLocalizedString(@"Enter a passcode", nil);
			UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
			self.navigationItem.rightBarButtonItem = cancelButton;
			[self.hiddenTextField becomeFirstResponder];
			break;
		}
			
		case PasscodeConfirmNewPasscode: {
			self.title = NSLocalizedString(@"Set Passcode", nil);
			self.descriptionLabel.text = NSLocalizedString(@"Re-enter your passcode", nil);
			UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
			self.navigationItem.rightBarButtonItem = cancelButton;
			[self.hiddenTextField becomeFirstResponder];
			break;
		}
			
		case PasscodeCheck: {
			self.title = NSLocalizedString(@"Enter Passcode", nil);
			self.descriptionLabel.text = NSLocalizedString(@"Please enter your passcode", nil);
			self.navigationItem.rightBarButtonItem = nil;
			break;
		}
			
		default:
			break;
	}
}

@synthesize passcodeTextField1 = _passcodeTextField1;
@synthesize passcodeTextField2 = _passcodeTextField2;
@synthesize passcodeTextField3 = _passcodeTextField3;
@synthesize passcodeTextField4 = _passcodeTextField4;
@synthesize hiddenTextField = _hiddenTextField;
@synthesize descriptionLabel = _descriptionLabel;
@synthesize descriptionLabel2 = _descriptionLabel2;
@synthesize theNewPasscode = _theNewPasscode;

- (void)viewDidLoad {
	[super viewDidLoad];
	self.descriptionLabel2.hidden = YES;
	self.passcodeTextField1.backgroundColor = [UIColor whiteColor];
	self.passcodeTextField2.backgroundColor = [UIColor whiteColor];
	self.passcodeTextField3.backgroundColor = [UIColor whiteColor];
	self.passcodeTextField4.backgroundColor = [UIColor whiteColor];
	self.viewState = self.viewState;
    
    if (IS_IPAD) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHide:)
                                                     name:UIKeyboardDidHideNotification
                                                   object:nil];
    }
}

- (void)keyboardDidHide:(id)sender {
    if (IS_IPAD) {
        [self clearTextFeilds];
        [self.hiddenTextField becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.hiddenTextField resignFirstResponder];
	[APP_VIEW_CONTROLLER hideKeyboardDarnIt];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation  {
    return YES;
}

//#pragma mark -
//#pragma mark UITextFieldDelegate
//- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
//    if (IS_IPAD) {
//        return NO;
//    }
//    return YES;
//}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if (textField.text.length >= 4 && range.length == 0) {
        return NO; 
    } else {
		if ([string length] > 0) {
			if (textField.text.length == 0) {
				self.passcodeTextField1.text = @"*";
				self.passcodeTextField2.text = @"";
				self.passcodeTextField3.text = @"";
				self.passcodeTextField4.text = @"";
			} else if (textField.text.length == 1) {
				self.passcodeTextField1.text = @"*";
				self.passcodeTextField2.text = @"*";		
				self.passcodeTextField3.text = @"";
				self.passcodeTextField4.text = @"";
			} else if (textField.text.length == 2) {
				self.passcodeTextField1.text = @"*";
				self.passcodeTextField2.text = @"*";		
				self.passcodeTextField3.text = @"*";		
				self.passcodeTextField4.text = @"";
			} else if (textField.text.length == 3) {
				self.passcodeTextField1.text = @"*";
				self.passcodeTextField2.text = @"*";		
				self.passcodeTextField3.text = @"*";		
				self.passcodeTextField4.text = @"*";	
				[self performSelector:@selector(onFourthInput:) withObject:string afterDelay:0.3];
				return NO;
			}
		} else {
			if (textField.text.length == 0) {
				self.passcodeTextField1.text = @"";
				self.passcodeTextField2.text = @"";
				self.passcodeTextField3.text = @"";
				self.passcodeTextField4.text = @"";
			} else if (textField.text.length == 1) {
				self.passcodeTextField1.text = @"";
				self.passcodeTextField2.text = @"";		
				self.passcodeTextField3.text = @"";
				self.passcodeTextField4.text = @"";
			} else if (textField.text.length == 2) {
				self.passcodeTextField1.text = @"*";
				self.passcodeTextField2.text = @"";		
				self.passcodeTextField3.text = @"";		
				self.passcodeTextField4.text = @"";
			} else if (textField.text.length == 3) {
				self.passcodeTextField1.text = @"*";
				self.passcodeTextField2.text = @"*";		
				self.passcodeTextField3.text = @"";		
				self.passcodeTextField4.text = @"";		
			} else if (textField.text.length == 4) {
				self.passcodeTextField1.text = @"*";
				self.passcodeTextField2.text = @"*";		
				self.passcodeTextField3.text = @"*";		
				self.passcodeTextField4.text = @"";		
			}
		}
		
		return YES;
	}
}

#pragma mark -
#pragma mark Public

- (NSString *)passcode {
	return self.hiddenTextField.text;
}

#pragma mark -
#pragma mark Private

- (void)onFourthInput:(NSString *)fourthString {
	if (self.viewState == PasscodeCheck) {
		self.hiddenTextField.delegate = nil;
		self.hiddenTextField.text = [self.hiddenTextField.text stringByAppendingString:fourthString];
		self.hiddenTextField.delegate = self;
		[self checkPasscode];
	} else if (self.viewState == PasscodeSetNewPasscode) {
		self.theNewPasscode =  [self.hiddenTextField.text stringByAppendingString:fourthString];
		[self showConfirm];
	} else if (self.viewState == PasscodeConfirmNewPasscode) {
		self.hiddenTextField.delegate = nil;
		self.hiddenTextField.text = [self.hiddenTextField.text stringByAppendingString:fourthString];
		self.hiddenTextField.delegate = self;
		[self checkConfirm];
	}
}

- (void)clearTextFeilds {
	self.passcodeTextField1.text = @"";
	self.passcodeTextField2.text = @"";		
	self.passcodeTextField3.text = @"";		
	self.passcodeTextField4.text = @"";	
	self.hiddenTextField.delegate = nil;
	self.hiddenTextField.text = @"";
	self.hiddenTextField.delegate = self;		
}

- (void)showConfirm {
	self.descriptionLabel2.hidden = YES;
	self.viewState = PasscodeConfirmNewPasscode;
	[self clearTextFeilds];
}

- (void)checkConfirm {
	if ([self.theNewPasscode isEqualToString:self.hiddenTextField.text]) {
		[PasscodeManager sharedPasscodeManager].passcode = self.theNewPasscode;
		[self.navigationController popViewControllerAnimated:YES];
	} else {
		self.viewState = PasscodeSetNewPasscode;
		_descriptionLabel2.hidden = NO;
		[self clearTextFeilds];
	}
}

- (void)checkPasscode {
	if ([[PasscodeManager sharedPasscodeManager].passcode isEqualToString:self.hiddenTextField.text]) {
		self.viewState = PasscodeCheck;
		[self clearTextFeilds];
        [self dismissModalViewControllerAnimated:NO];
        [APP_VIEW_CONTROLLER clearDefaultsCaches:YES];
#ifdef TASKPAPER
        [APP_VIEW_CONTROLLER performSelector:@selector(reloadData) withObject:nil afterDelay:0];
#endif
	} else {
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
		[self clearTextFeilds];
	}
}

#pragma mark -
#pragma mark Private

- (void)close {
	[self clearTextFeilds];
	[self dismissModalViewControllerAnimated:NO];
}

- (void)dealloc {
	[_passcodeTextField1 release], _passcodeTextField1 = nil;
	[_passcodeTextField2 release], _passcodeTextField2 = nil;
	[_passcodeTextField3 release], _passcodeTextField3 = nil;
	[_passcodeTextField4 release], _passcodeTextField4 = nil;

	_hiddenTextField.delegate = nil;
	[_hiddenTextField release], _hiddenTextField = nil;
	[_descriptionLabel release], _descriptionLabel = nil;
	[_descriptionLabel2 release], _descriptionLabel2 = nil;	
	
	[_theNewPasscode release], _theNewPasscode = nil;

    [super dealloc];
}


@end
