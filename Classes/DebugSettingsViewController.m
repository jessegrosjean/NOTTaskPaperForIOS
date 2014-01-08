//
//  DebugSettingsViewController.m
//  PlainText
//
//  Created by Jesse Grosjean on 4/20/11.
//

#import "DebugSettingsViewController.h"
#import "IFChoiceCellController.h"
#import "IFSwitchCellController.h"
#import "IFButtonCellController.h"

@implementation DebugSettingsViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
}

- (void)constructTableGroups {
	NSMutableArray *groupOneCells = [NSMutableArray array];
	NSMutableArray *groupTwoCells = [NSMutableArray array];
	
	IFChoiceCellController *logLevelCell = [[[IFChoiceCellController alloc] initWithLabel:NSLocalizedString(@"Log Level", nil) andChoices:[NSArray arrayWithObjects:NSLocalizedString(@"Debug", nil), NSLocalizedString(@"Info", nil), NSLocalizedString(@"Warn", nil), NSLocalizedString(@"Error", nil), nil] andChoiceValues:nil atKey:LogLevelDefaultsKey inModel:model] autorelease];
	logLevelCell.updateTarget = self;
	logLevelCell.updateAction = @selector(logLevelChanged);
	[groupOneCells addObject:logLevelCell];
	
	IFSwitchCellController *logLocationCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Log Locations", nil) atKey:LogLocationDefaultsKey inModel:self.model] autorelease];
	logLocationCell.updateTarget = self;
	logLocationCell.updateAction = @selector(logLocationChanged);
	[groupOneCells addObject:logLocationCell];	
	
	IFButtonCellController *buttonCell = [[[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"Open Debug Instructions", nil) withAction:@selector(openDebugInstructions) onTarget:self] autorelease];
	[groupTwoCells addObject:buttonCell];
	
	
	tableGroups = [[NSArray arrayWithObjects:groupOneCells, groupTwoCells, nil] retain];
	tableHeaders = [[NSArray arrayWithObjects:@"", @"", nil] retain];	
	tableFooters = [[NSArray arrayWithObjects:@"", @"", nil] retain];	
}

- (void)logLevelChanged {
	[[Logger sharedInstance] setLogLevel:[[NSUserDefaults standardUserDefaults] integerForKey:LogLevelDefaultsKey]]; // change state
}

- (void)logLocationChanged {
	[[Logger sharedInstance] setLogLocation:[[NSUserDefaults standardUserDefaults] integerForKey:LogLocationDefaultsKey]]; // change state
}

- (void)openDebugInstructions {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.hogbaysoftware.com/wiki/PlainTextDebugInstructions"]];
}

@end