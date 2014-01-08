//
//  AdvancedSettingsViewController.m
//  PlainText
//
//  Created by Jesse Grosjean on 5/19/11.
//

#import "AdvancedSettingsViewController.h"
#import "ExtendedKeyboardSettingsViewController.h"
#import "DebugSettingsViewController.h"
#import "ApplicationViewController.h"
#import "IFChoiceCellController.h"
#import "IFSwitchCellController.h"
#import "PasscodeViewController.h"
#import "ApplicationController.h"
#import "IFTextCellController.h"
#import "IFLinkCellController.h"
#import "UIView_Additions.h"
#import "PasscodeManager.h"
#import "PathController.h"

#ifdef TASKPAPER
#import "TaskViewController.h"
#endif

@implementation AdvancedSettingsViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
	if ([PasscodeManager sharedPasscodeManager].passcode == nil) {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:PasscodeEnableDefaultsKey];    
	}
}

- (void)constructTableGroups {
	NSMutableArray *groupOneCells = [NSMutableArray array];
	NSMutableArray *groupTwoCells = [NSMutableArray array];
		
	IFChoiceCellController *sortByCell = [[[IFChoiceCellController alloc] initWithLabel:NSLocalizedString(@"Sort By", nil) andChoices:[NSArray arrayWithObjects:NSLocalizedString(@"Name ↑", nil), NSLocalizedString(@"Name ↓", nil), NSLocalizedString(@"Modified ↑", nil), NSLocalizedString(@"Modified ↓", nil), /*NSLocalizedString(@"Created ↑", nil), NSLocalizedString(@"Created ↓", nil),*/ nil] andChoiceValues:nil atKey:SortByDefaultsKey inModel:model] autorelease];
	sortByCell.updateTarget = self;
	sortByCell.updateAction = @selector(sortByChanged:);
	[groupOneCells addObject:sortByCell];
	
	IFChoiceCellController *sortFoldersCell = [[[IFChoiceCellController alloc] initWithLabel:NSLocalizedString(@"Sort Folders", nil) andChoices:[NSArray arrayWithObjects:NSLocalizedString(@"To Top ↑", nil), NSLocalizedString(@"To Bottom ↓", nil), NSLocalizedString(@"With Files", nil), nil] andChoiceValues:nil atKey:SortFoldersDefaultsKey inModel:model] autorelease];
	sortFoldersCell.updateTarget = self;
	sortFoldersCell.updateAction = @selector(sortFoldersChanged:);
	[groupOneCells addObject:sortFoldersCell];
	
#if defined(WRITEROOM) || defined(TASKPAPER)
	IFChoiceCellController *autocorrectionTypeCell = [[[IFChoiceCellController alloc] initWithLabel:NSLocalizedString(@"Autocorrection", nil) 
																						 andChoices:[NSArray arrayWithObjects:NSLocalizedString(@"Default", nil), NSLocalizedString(@"Off", nil),NSLocalizedString(@"On", nil), nil]
																					andChoiceValues:[NSArray arrayWithObjects:[NSNumber numberWithInteger:UITextAutocorrectionTypeDefault], [NSNumber numberWithInteger:UITextAutocorrectionTypeNo], [NSNumber numberWithInteger:UITextAutocorrectionTypeYes], nil]
																							  atKey:AutocorrectionTypeDefaultsKey inModel:model] autorelease];
	autocorrectionTypeCell.updateTarget = self;
	autocorrectionTypeCell.updateAction = @selector(autocorrectionChanged:);
	[groupOneCells addObject:autocorrectionTypeCell];
	
	if (IS_IPAD) {
		IFLinkCellController *linkCell = [[[IFLinkCellController alloc] initWithLabel:NSLocalizedString(@"Extended Keyboard", nil) usingController:[[[ExtendedKeyboardSettingsViewController alloc] init] autorelease] inModel:model] autorelease];
		[groupOneCells addObject:linkCell];	
	}
	
	IFSwitchCellController *passcodeCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Passcode", nil) atKey:PasscodeEnableDefaultsKey inModel:self.model] autorelease];
	passcodeCell.updateTarget = self;
	passcodeCell.updateAction = @selector(passcodeCellChanged:);
	[groupOneCells addObject:passcodeCell];
    
    IFChoiceCellController *passcodeTimeoutCell = [[[IFChoiceCellController alloc] initWithLabel:NSLocalizedString(@"Passcode Timeout", nil) andChoices:[NSArray arrayWithObjects:NSLocalizedString(@"Immediately", nil), NSLocalizedString(@"1 minute", nil), NSLocalizedString(@"5 minutes", nil), NSLocalizedString(@"15 minutes", nil), nil] andChoiceValues:nil atKey:PasscodeTimeoutDefaultsKey inModel:model] autorelease];
    [groupOneCells addObject:passcodeTimeoutCell];
    
#endif
	
#if defined(WRITEROOM) || defined(TASKPAPER)
	IFSwitchCellController *showStatusBarCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Status Bar", nil) atKey:ShowStatusBarDefaultsKey inModel:self.model] autorelease];
	showStatusBarCell.updateTarget = self;
	showStatusBarCell.updateAction = @selector(showStatusBarChanged:);
	[groupOneCells addObject:showStatusBarCell];
#endif
	
#ifdef TASKPAPER
    IFTextCellController *defaultTagsCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"Default Tags", nil) andPlaceholder:@"" atKey:DefaultTagsKey inModel:model] autorelease];
    defaultTagsCell.keyboardType = UIKeyboardTypeDefault;
    [groupOneCells addObject:defaultTagsCell];
	
	IFSwitchCellController *dateDoneCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Add Date to Done", nil) atKey:AddDateToDoneTagKey inModel:model] autorelease];
    [groupOneCells addObject:dateDoneCell];
	
	IFSwitchCellController *enableLiveSearch = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Enable Live Search", nil) atKey:LiveSearchEnabledKey inModel:model] autorelease];
    [groupOneCells addObject:enableLiveSearch];
    
    IFSwitchCellController *showIconBadgeNumber =
    [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Show Badge Number", nil) atKey:ShowIconBadgeNumberDefaultsKey inModel:model] autorelease];
    showIconBadgeNumber.updateTarget = self;
    showIconBadgeNumber.updateAction = @selector(showIconBadgeNumberChanged:);
    [groupOneCells addObject:showIconBadgeNumber];
#endif
	
#ifndef TASKPAPER
	IFSwitchCellController *detectLinksCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Detect Links", nil) atKey:DetectLinksDefaultsKey inModel:self.model] autorelease];
	detectLinksCell.updateTarget = self;
	detectLinksCell.updateAction = @selector(detectLinksChanged:);
	[groupOneCells addObject:detectLinksCell];
	
	IFSwitchCellController *scrollsHeadingsCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Scroll Headings", nil) atKey:ScrollsHeadingsDefaultsKey inModel:self.model] autorelease];
	scrollsHeadingsCell.updateTarget = self;
	scrollsHeadingsCell.updateAction = @selector(scrollsHeadingsChanged:);
	[groupOneCells addObject:scrollsHeadingsCell];
#endif

	
#if defined(WRITEROOM) || defined(TASKPAPER)
	IFSwitchCellController *draggableScroller = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Draggable Scroller", nil) atKey:DraggableScrollerDefaultsKey inModel:self.model] autorelease];
	[groupOneCells addObject:draggableScroller];	
#endif
		
	if (!IS_IPAD) {
		IFSwitchCellController *switchCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Lock Orientation", nil) atKey:LockOrientationDefaultsKey inModel:self.model] autorelease];
		switchCell.updateTarget = self;
		switchCell.updateAction = @selector(lockOrientationChanged:);
		[groupOneCells addObject:switchCell];
	}	
	
	IFSwitchCellController *capitializeTitlesCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"ALL-CAPS Headings", nil) atKey:AllCapsHeadingsDefaultsKey inModel:self.model] autorelease];
	capitializeTitlesCell.updateTarget = self;
	capitializeTitlesCell.updateAction = @selector(allCapsHeadingsChanged:);
	[groupOneCells addObject:capitializeTitlesCell];
	
	IFSwitchCellController *showFileExtensionsCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Show File Extensions", nil) atKey:ShowFileExtensionsDefaultsKey inModel:self.model] autorelease];
	showFileExtensionsCell.updateTarget = self;
	showFileExtensionsCell.updateAction = @selector(showFileExtensionsChanged:);
	[groupOneCells addObject:showFileExtensionsCell];
    
#ifndef TASKPAPER
    IFSwitchCellController *textRightToLeftCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Text Right to Left", nil) atKey:TextRightToLeftDefaultsKey inModel:self.model] autorelease];
    textRightToLeftCell.updateTarget = self;
	textRightToLeftCell.updateAction = @selector(textRightToLeftChanged:);
    [groupOneCells addObject:textRightToLeftCell];
#endif
    
#if defined(WRITEROOM) || defined(TASKPAPER)
    IFTextCellController *textFileDefaultExtensionCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"New File Extension", nil) andPlaceholder:nil atKey:TextFileDefaultExtensionDefaultsKey inModel:self.model] autorelease];
    textFileDefaultExtensionCell.autocorrectionType = UITextAutocorrectionTypeNo;
    textFileDefaultExtensionCell.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textFileDefaultExtensionCell.updateAction = @selector(defaultFileExtensionFieldUpdated:);
    textFileDefaultExtensionCell.updateTarget = self;
    [groupOneCells addObject:textFileDefaultExtensionCell];
#endif	
    
	IFLinkCellController *linkCell = [[[IFLinkCellController alloc] initWithLabel:NSLocalizedString(@"Debug", nil) usingController:[[[DebugSettingsViewController alloc] init] autorelease] inModel:model] autorelease];
	[groupTwoCells addObject:linkCell];
    
    
    NSString *footers = @"";
	
	tableGroups = [[NSArray arrayWithObjects:groupOneCells, groupTwoCells, nil] retain];
	tableHeaders = [[NSArray arrayWithObjects:@"", @"", nil] retain];	
	tableFooters = [[NSArray arrayWithObjects:@"", footers, nil] retain];	
}

- (void)textRightToLeftChanged:(UISwitch *)sender {
    APP_VIEW_CONTROLLER.textRightToLeft = sender.on;
}

- (void)refreshViewFromDefaults:(id)sender {
    self.clearDefaultsCaches = YES;
}

- (void)sortByChanged:(id)sender {
	APP_VIEW_CONTROLLER.sortBy = [[NSUserDefaults standardUserDefaults] integerForKey:SortByDefaultsKey]; // fire notification
}

- (void)sortFoldersChanged:(id)sender {
	APP_VIEW_CONTROLLER.sortFolders = [[NSUserDefaults standardUserDefaults] integerForKey:SortFoldersDefaultsKey]; // fire notification
}

- (void)showFileExtensionsChanged:(UISwitch *)sender {
	APP_VIEW_CONTROLLER.showFileExtensions = sender.on; // fire notification
}

- (void)scrollsHeadingsChanged:(UISwitch *)sender {
	APP_VIEW_CONTROLLER.scrollsHeadings = sender.on; // fire notification
}

- (void)showIconBadgeNumberChanged:(UISwitch *)sender {
    APP_VIEW_CONTROLLER.iconBadgeNumberEnabled = sender.on; // fire notification
    self.clearDefaultsCaches = YES;
}

- (void)allCapsHeadingsChanged:(UISwitch *)sender {
	APP_VIEW_CONTROLLER.allCapsHeadings = sender.on; // fire notification
}

- (void)detectLinksChanged:(UISwitch *)sender {
	APP_VIEW_CONTROLLER.detectLinks = sender.on; // fire notification
}

- (void)showStatusBarChanged:(UISwitch *)sender {
	APP_VIEW_CONTROLLER.showStatusBar = sender.on; // fire notification
	if (!IS_IPAD) {
		// hack to make navigation controller relayout and cover status bar region.
		self.navigationController.navigationBarHidden = !self.navigationController.navigationBarHidden;
		self.navigationController.navigationBarHidden = !self.navigationController.navigationBarHidden;
	}
}

- (void)autocorrectionChanged:(id)sender {
	APP_VIEW_CONTROLLER.autocorrectionType = [[NSUserDefaults standardUserDefaults] integerForKey:AutocorrectionTypeDefaultsKey]; // fire notification
}

- (void)lockOrientationChanged:(id)sender {
    self.clearDefaultsCaches = YES;
	[[NSUserDefaults standardUserDefaults] setInteger:self.interfaceOrientation forKey:LockedOrientationDefaultsKey];
    [[[[APP_VIEW_CONTROLLER view] window] allMySubviews] makeObjectsPerformSelector:@selector(setNeedsLayout)];
}


- (void)passcodeCellChanged:(id)sender {
	[PasscodeManager sharedPasscodeManager].passcode = nil;
	if (!((UISwitch *)sender).on) {
		[PasscodeManager sharedPasscodeManager].passcode = nil;
	} else {
		PasscodeViewController *passcodeViewController = [[[PasscodeViewController alloc] initWithNibName:@"PasscodeViewController" bundle:nil] autorelease];
		passcodeViewController.viewState = PasscodeSetNewPasscode;
		[self.navigationController pushViewController:passcodeViewController animated:YES];
	}
	[self constructTableGroups];
	[self.tableView reloadData];
}

- (void)defaultFileExtensionFieldUpdated:(id)sender {
    [PathController setDefaultTextFileType:[sender text]];
}

@end