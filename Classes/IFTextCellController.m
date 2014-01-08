//
//  IFTextCellController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFTextCellController.h"

#import	"IFControlTableViewCell.h"

@implementation IFTextCellController

@synthesize updateTarget, updateAction;

@synthesize enabled, numericValues, keyboardType, returnKeyType, autocapitalizationType, autocorrectionType, secureTextEntry, indentationLevel, clearButtonMode;

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel andPlaceholder:(NSString *)newPlaceholder atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		placeholder = [newPlaceholder retain];
		key = [newKey retain];
		model = [newModel retain];

		enabled = YES;
		numericValues = NO;
		keyboardType = UIKeyboardTypeAlphabet;
		autocapitalizationType = UITextAutocapitalizationTypeNone;
		autocorrectionType = UITextAutocorrectionTypeNo;
		secureTextEntry = NO;
		indentationLevel = 0;
		clearButtonMode = UITextFieldViewModeWhileEditing;
	}
	return self;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[label release];
	[placeholder release];
	[key release];
	[model release];
	
	[super dealloc];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"TextDataCell";
	
	IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
	}
	
	cell.textLabel.text = label;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.indentationLevel = indentationLevel;

	// NOTE: The documentation states that the indentation width is 10 "points". It's more like 20
	// pixels and changing the property has no effect on the indentation. We'll use 20.0f here
	// and cross our fingers that this doesn't screw things up in the future.
		
	// add a text field to the cell
	CGRect frame = CGRectMake(0.0f, 0.0f, 20, 21.0f);
	UITextField *textField = [[UITextField alloc] initWithFrame:frame];
	[textField addTarget:self action:@selector(updateValue:) forControlEvents:UIControlEventEditingChanged];
	[textField setDelegate:self];
	id value = [model objectForKey:key];
	[textField setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	[textField setText:[value description]];
	[textField setFont:[UIFont systemFontOfSize:17.0f]];
	[textField setPlaceholder:placeholder];
	[textField setReturnKeyType:UIReturnKeyDone];
	[textField setKeyboardType:keyboardType];
	[textField setReturnKeyType:returnKeyType];
	[textField setAutocapitalizationType:autocapitalizationType];
	[textField setAutocorrectionType:autocorrectionType];
	[textField setBackgroundColor:[UIColor whiteColor]];
	[textField setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
	[textField setSecureTextEntry:secureTextEntry];
	[textField setClearButtonMode:clearButtonMode];
	[textField setBorderStyle:UITextBorderStyleNone];
	if (enabled) {
		textField.enabled = YES;	
		textField.backgroundColor = [UIColor whiteColor];
		textField.textAlignment = UITextAlignmentLeft;
	} else {
		textField.enabled = NO;
		textField.backgroundColor = [UIColor clearColor];
		textField.textAlignment = UITextAlignmentRight;
	}	
	cell.view = textField;
	[textField release];
	
	[cell layoutSubviews];

	return cell;
}

- (void)updateValue:(id)sender {
	if (numericValues) {
		[model setObject:[[[[NSNumberFormatter alloc] init] autorelease] numberFromString:[sender text]] forKey:key];		
	} else {
		[model setObject:[sender text] forKey:key];
	}
	
	if (updateTarget && [updateTarget respondsToSelector:updateAction])
	{
		// action is peformed after keyboard has had a chance to resign
		[updateTarget performSelector:updateAction withObject:sender];
	}
}


#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{	
	return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	// hide the keyboard
	[textField resignFirstResponder];
	
	return YES;
}

@end
