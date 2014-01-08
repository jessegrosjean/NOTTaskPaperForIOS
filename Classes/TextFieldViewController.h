//
//  TextFieldViewController.h
//  PlainText
//
//  Created by Jesse Grosjean on 12/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "ViewController.h"
#import "SMTEDelegateController.h"

@class TextFieldViewController;

@interface TextFieldViewController : ViewController <UITextFieldDelegate> {
	id delegate;
	SMTEDelegateController *textExpander;
}

@property (nonatomic, readonly) UITextField *textField;
@property (nonatomic, assign) id delegate;

@end
