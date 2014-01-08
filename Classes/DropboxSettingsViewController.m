//
//  DropboxSettingsViewController.m
//  PlainText
//
//  Created by Jesse Grosjean on 4/20/11.
//

#import "DropboxSettingsViewController.h"
#import "IFSwitchCellController.h"
#import "IFButtonCellController.h"
#import "ApplicationController.h"
#import "IFTextCellController.h"
#import "IFTemporaryModel.h"
#import "PathController.h"
#import "KeychainManager.h"

@interface DropboxSettingsViewController () <DBSessionDelegate>

@end



@implementation DropboxSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginStatusChanged) name:DropboxLoginSuccessNotification object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [DBSession sharedSession].delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DropboxLoginSuccessNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
	[self setToolbarItems:[NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Sync All Now", nil) style:UIBarButtonItemStyleBordered target:PATH_CONTROLLER action:@selector(beginFullSync)]] animated:NO];
	[super viewWillAppear:animated];
}

- (void)constructTableGroups {
	NSMutableArray *groupOneCells = [NSMutableArray array];
	NSMutableArray *groupTwoCells = [NSMutableArray array];
	PathController *pathController = PATH_CONTROLLER;
	BOOL isLinked = [pathController isLinked];
	
	// Group One
	NSString *processName = [[NSProcessInfo processInfo] processName];
	NSString *dropboxInfo = nil;
    
	if (isLinked) {
		IFButtonCellController *dropboxStatusCell = [[[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"Dropbox Status", nil) withAction:@selector(dropboxStatus) onTarget:self] autorelease];
		dropboxStatusCell.textAlignment = UITextAlignmentLeft;
		dropboxStatusCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		[groupOneCells addObject:dropboxStatusCell];	
		
		IFSwitchCellController *syncAutomaticallyCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Sync Automatically", nil) atKey:SyncAutomaticallyDefaultsKey inModel:self.model] autorelease];
		[groupOneCells addObject:syncAutomaticallyCell];
		
		// Group Two
		IFButtonCellController *buttonCell = [[[IFButtonCellController alloc] initWithLabel:@"Unlink from Dropbox Account" withAction:@selector(unlink:) onTarget:self] autorelease];
		[groupTwoCells addObject:buttonCell];
		
		dropboxInfo = NSLocalizedString(@"Unlink to change which file types are synced and which Dropbox folder is linked.", nil);
	} else {		
		IFTextCellController *linkedFolder = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"Link Folder", nil) andPlaceholder:processName atKey:ServerRootDefaultsKey inModel:self.model] autorelease];
		linkedFolder.autocorrectionType = UITextAutocorrectionTypeNo;
		linkedFolder.autocapitalizationType = UITextAutocapitalizationTypeNone;
		linkedFolder.updateAction = @selector(dropboxFolderFieldUpdated:);
		linkedFolder.updateTarget = self;
		[groupOneCells addObject:linkedFolder];
		
		id<IFCellModel> fileExtensionsModel = [[[IFTemporaryModel alloc] initWithDictionary:[NSDictionary dictionaryWithObject:[[NSUserDefaults standardUserDefaults] stringForKey:TextFileExtensionsDefaultsKey] forKey:TextFileExtensionsDefaultsKey]] autorelease];
		IFTextCellController *textFileExtensions = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"Sync File Types", nil) andPlaceholder:nil atKey:TextFileExtensionsDefaultsKey inModel:fileExtensionsModel] autorelease];
		textFileExtensions.autocorrectionType = UITextAutocorrectionTypeNo;
		textFileExtensions.autocapitalizationType = UITextAutocapitalizationTypeNone;
		textFileExtensions.updateAction = @selector(fileExtensionsFieldUpdated:);
		textFileExtensions.updateTarget = self;
		[groupOneCells addObject:textFileExtensions];
		
		// Group Two
		IFButtonCellController *buttonCell = [[[IFButtonCellController alloc] initWithLabel:@"Link to Dropbox Account" withAction:@selector(link:) onTarget:self] autorelease];
		[groupTwoCells addObject:buttonCell];			
		
		dropboxInfo = NSLocalizedString(@"Dropbox is software that syncs your files online and across your computers. http://www.dropbox.com", nil);
	}
	
	tableGroups = [[NSArray arrayWithObjects: groupOneCells, groupTwoCells, nil] retain];
	tableHeaders = [[NSArray arrayWithObjects:@"", @"", nil] retain];	
	tableFooters = [[NSArray arrayWithObjects:@"", dropboxInfo, nil] retain];	
}

- (IBAction)dropboxFolderFieldUpdated:(id)sender {
	if ([PATH_CONTROLLER isLinked]) {
		NSString *linkFolder = [[NSUserDefaults standardUserDefaults] stringForKey:ServerRootDefaultsKey];
		UITextField *textField = sender;
		if (![[textField text] isEqualToString:linkFolder]) {
			[textField setText:linkFolder];
			UIAlertView *unlinkAlertView = [[[UIAlertView alloc] initWithTitle:nil
																	   message:NSLocalizedString(@"The link folder can only be changed before linking to Dropbox. Please unlink Dropbox and then try again.", nil)
																	  delegate:nil
															 cancelButtonTitle:NSLocalizedString(@"OK", nil)
															 otherButtonTitles:nil] autorelease];
			[unlinkAlertView show];
		}
	} else {
		[PATH_CONTROLLER setServerRoot:[sender text]];
		[[NSUserDefaults standardUserDefaults] setObject:[PATH_CONTROLLER serverRoot] forKey:ServerRootDefaultsKey];	
        [[KeychainManager sharedKeychainManager] setValue:[[NSUserDefaults standardUserDefaults] stringForKey:ServerRootDefaultsKey] forKey:ServerRootDefaultsKey];
	}
}

- (IBAction)fileExtensionsFieldUpdated:(id)sender {
	[PathController setTextFileTypes:[sender text]];
}

- (IBAction)link:(id)sender {
    [DBSession sharedSession].delegate = self;
    [[DBSession sharedSession] linkFromController:self];
}

- (IBAction)unlink:(id)sender {
	UIAlertView *unlinkAlertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unlink Dropbox?", nil)
															   message:NSLocalizedString(@"This will unlink your Dropbox account and remove all synced documents from this device.", nil)
															  delegate:self
													 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
													 otherButtonTitles:NSLocalizedString(@"Unlink", nil), nil] autorelease];
	[unlinkAlertView show];
}

- (void)dropboxStatus {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://status.dropbox.com"]];
}

- (void)loginStatusChanged {
    [DBSession sharedSession].delegate = nil;
	[self constructTableGroups];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
	relinkUserId = [userId retain];
	[[[[UIAlertView alloc]
	   initWithTitle:@"Dropbox Session Ended" message:@"Do you want to relink?" delegate:self
	   cancelButtonTitle:@"Cancel" otherButtonTitles:@"Relink", nil]
	  autorelease]
	 show];
}


#pragma mark -
#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Dropbox Session Ended"]) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [[DBSession sharedSession] linkUserId:relinkUserId fromController:self];
        }
        [relinkUserId release];
        relinkUserId = nil;
    } else {
        if (buttonIndex == 1) {
            [PATH_CONTROLLER unlink:YES];
            [self updateAndReload];
        }
    }
}

@end
