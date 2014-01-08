//
//  ExtendedKeyboardSettingsViewController.m
//  PlainText
//
//  Created by Jesse Grosjean on 5/31/11.
//

#import "ExtendedKeyboardSettingsViewController.h"
#import "ApplicationViewController.h"
#import "IFSwitchCellController.h"
#import "ApplicationController.h"
#import "IFTextCellController.h"
#import <AudioToolbox/AudioToolbox.h>


@implementation ExtendedKeyboardSettingsViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[APP_VIEW_CONTROLLER hideKeyboardDarnIt];
}

- (void)constructTableGroups {
	NSMutableArray *groupOneCells = [NSMutableArray array];
	
	IFSwitchCellController *extendedKeyboard = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Extended Keyboard", nil) atKey:ExtendedKeyboardDefaultsKey inModel:self.model] autorelease];
	extendedKeyboard.updateTarget = self;
	extendedKeyboard.updateAction = @selector(extendedKeyboardChanged);
	[groupOneCells addObject:extendedKeyboard];
	
	IFTextCellController *keysCellController = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"Extended Keyboard Keys", nil) andPlaceholder:nil atKey:ExtendedKeyboardKeysDefaultsKey inModel:self.model] autorelease];
	keysCellController.autocorrectionType = UITextAutocorrectionTypeNo;
	keysCellController.autocapitalizationType = UITextAutocapitalizationTypeNone;
	keysCellController.updateAction = @selector(extendedKeysUpdated:);
	keysCellController.updateTarget = self;
	[groupOneCells addObject:keysCellController];

	
	tableGroups = [[NSArray arrayWithObjects: groupOneCells, nil] retain];
	tableHeaders = [[NSArray arrayWithObjects:@"", nil] retain];	
	tableFooters = [[NSArray arrayWithObjects:NSLocalizedString(@"Extended keyboard has room for a maximum of 9 characters.", nil), nil] retain];		
}

- (void)extendedKeyboardChanged {
    self.clearDefaultsCaches = YES;
}

- (void)extendedKeysUpdated:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *keys = [defaults stringForKey:ExtendedKeyboardKeysDefaultsKey];
	if ([keys length] > 9) {
		keys = [keys substringToIndex:9];
		[defaults setObject:keys forKey:ExtendedKeyboardKeysDefaultsKey];
		[sender setTextColor:[UIColor redColor]];
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	} else {
		[sender setTextColor:[UIColor blackColor]];
	}
    self.clearDefaultsCaches = YES;
}

@end
