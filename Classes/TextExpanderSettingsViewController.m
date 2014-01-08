//
//  TextExpanderSettingsViewController.m
//  PlainText
//
//  Created by Jesse Grosjean on 4/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TextExpanderSettingsViewController.h"
#import "ApplicationViewController.h"
#import "IFSwitchCellController.h"
#import "SMTEDelegateController.h"
#import "ApplicationController.h"


@implementation TextExpanderSettingsViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
}

- (void)constructTableGroups {
	NSMutableArray *groupOneCells = [NSMutableArray array];
	
	IFSwitchCellController *switchCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"TextExpander", nil) atKey:TextExpanderEnabledDefaultsKey inModel:self.model] autorelease];
	switchCell.updateAction = @selector(enableTextExpanderUpdated:);
	switchCell.updateTarget = self;
	[groupOneCells addObject:switchCell];
	
	NSString *footer = @"";
	
	if ([APP_VIEW_CONTROLLER textExpanderEnabled]) {
		if (![SMTEDelegateController isTextExpanderTouchInstalled]) {
			footer = NSLocalizedString(@"TextExpander isn't installed, but you can try TextExpander's functionality by typing the built-in 'ddate' abbreviation. You can also try (iOS 3.2 and greater) typing four spaces which will be expanded into a tab.", nil);
		} else if (![SMTEDelegateController snippetsAreShared]) {
			footer = NSLocalizedString(@"TextExpander snippet sharing isn't turned on, but you can try TextExpander's functionality by typing the built-in 'ddate' abbreviation. You can also try (iOS 3.2 and greater) typing four spaces which will get expanded into a tab.", nil);
		} else {
			footer = NSLocalizedString(@"TextExpander is installed and snippet sharing is on.", nil);
		}
	} else {
		footer = NSLocalizedString(@"TextExpander is a third party app that allows you to type short abbreviations that are expanded into long snippets.", nil);
	}
	
	tableGroups = [[NSArray arrayWithObjects: groupOneCells, nil] retain];
	tableHeaders = [[NSArray arrayWithObjects:@"", nil] retain];	
	tableFooters = [[NSArray arrayWithObjects:footer, nil] retain];		
}


- (IBAction)enableTextExpanderUpdated:(UISwitch *)sender {
	[self constructTableGroups];
	
	[self.tableView beginUpdates];
	
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
	
	[self.tableView endUpdates];
	
	[APP_VIEW_CONTROLLER setTextExpanderEnabled:sender.on]; // fire changed notification
}

@end