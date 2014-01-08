//
//  IFGenericTableViewController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//
//  Based on work created by Matt Gallagher on 27/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//	For more information: http://cocoawithlove.com/2008/12/heterogeneous-cells-in.html
//

#import "IFGenericTableViewController.h"

#import "IFCellController.h"
#import "IFTextViewTableView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"

// NOTE: this code requires iPhone SDK 2.2. If you need to use it with SDK 2.1, you can enable
// it here. The table view resizing isn't very smooth, but at least it works :-)
#define FIRMWARE_21_COMPATIBILITY 0

@implementation IFGenericTableViewController
@synthesize clearDefaultsCaches;
@synthesize model;

#if FIRMWARE_21_COMPATIBILITY
- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShown:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHidden:) name:UIKeyboardWillHideNotification object:nil];

	[super awakeFromNib];
}
#endif

//
// constructTableGroups
//
// Creates/updates cell data. This method should only be invoked directly if
// a "reloadData" needs to be avoided. Otherwise, updateAndReload should be used.
//
- (void)constructTableGroups
{
	tableGroups = [[NSArray arrayWithObject:[NSArray array]] retain];

	tableHeaders = nil;
	tableFooters = nil;
}

//
// clearTableGroups
//
// Releases the table group data (it will be recreated when next needed)
//
- (void)clearTableGroups
{
	[tableHeaders release];
	tableHeaders = nil;
	[tableFooters release];
	tableFooters = nil;
	
	[tableGroups release];
	tableGroups = nil;
}

//
// updateAndReload
//
// Performs all work needed to refresh the data and the associated display
//
- (void)updateAndReload
{
	[self clearTableGroups];
	[self constructTableGroups];
	[self.tableView reloadData];
}

//
// numberOfSectionsInTableView:
//
// Return the number of sections for the table.
//
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	return [tableGroups count];
}

//
// tableView:numberOfRowsInSection:
//
// Returns the number of rows in a given section.
//
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	return [[tableGroups objectAtIndex:section] count];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	return
		[[[tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]
			tableView:(UITableView *)tableView
			cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<IFCellController> *cellData = [[tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([cellData respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)])
	{
		return [cellData tableView:tableView heightForRowAtIndexPath:indexPath];
	} else {
		return [tableView rowHeight];
	}
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<IFCellController> *cellData =
		[[tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([cellData respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)])
	{
		[cellData tableView:tableView didSelectRowAtIndexPath:indexPath];
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSString *title = nil;
	if (tableHeaders)
	{
		id object = [tableHeaders objectAtIndex:section];
		if ([object isKindOfClass:[NSString class]])
		{
			if ([object length] > 0)
			{
				title = object;
			}
		}
	}
	
	return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSString *title = nil;
	if (tableFooters)
	{
		id object = [tableFooters objectAtIndex:section];
		if ([object isKindOfClass:[NSString class]])
		{
			if ([object length] > 0)
			{
				title = object;
			}
		}
	}

	return title;
}

//
// didReceiveMemoryWarning
//
// Release any cache data.
//
- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	
	// [self clearTableGroups];  Commented out by Jesse... this creates problems if the controllers are delegates of the
	// table view items... because table view items stay alive and clickable, but controller targets get dealloced.
}

//
// dealloc
//
// Release instance memory
//
- (void)dealloc
{
#if FIRMWARE_21_COMPATIBILITY
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
#endif

	self.model = nil;

	[self clearTableGroups];
	[super dealloc];
}

- (void)validate:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)loadView
{
#if 1
	// NOTE: This code circumvents the normal loading of the UITableView and replaces it with an instance
	// of IFTextViewTableView (which includes a workaround for the hit testing problems in a UITextField.)
	// Check the header file for IFTextViewTableView to see why this is important.
	//
	// Since there is no style accessor on UITableViewController (to obtain the value passed in with the
	// initWithStyle: method), the value is hard coded for this use case. Too bad.

	self.view = [[[IFTextViewTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped] autorelease];
	[(IFTextViewTableView *)self.view setDelegate:self];
	[(IFTextViewTableView *)self.view setDataSource:self];
	[self.view setAutoresizesSubviews:YES];
	[self.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
#else
	[super loadView];
#endif
    clearDefaultsCaches = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
	// rows (such as choices) that were updated in child view controllers need to be updated
	[self.tableView reloadData];

	if ([self.toolbarItems count] > 0) {
		[self.navigationController setToolbarHidden:NO animated:animated];
	} else {
		[self.navigationController setToolbarHidden:YES animated:animated];
		//[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0]];
        //fix: in iOS5, above line cause flickering
	}

	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];	
	
	[super viewWillAppear:animated];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.clearDefaultsCaches = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([APP_VIEW_CONTROLLER lockOrientation]) {
		return interfaceOrientation == [APP_VIEW_CONTROLLER lockedOrientation];
	} else {
		return YES;
	}
}

- (void)setClearDefaultsCaches:(BOOL)newValue {
    if (IS_IPAD) {
        [APP_VIEW_CONTROLLER clearDefaultsCaches:YES];
#ifdef TASKPAPER
        [APP_VIEW_CONTROLLER performSelector:@selector(reloadData) withObject:nil afterDelay:0];
#endif
    } else {
        clearDefaultsCaches = newValue;
    }
}

- (IBAction)dismissModalViewControllerAction:(id)sender {
    if ([self.navigationController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            if (clearDefaultsCaches) {
                [APP_VIEW_CONTROLLER clearDefaultsCaches:YES];
            }
        }];
    } else {
        [self.navigationController dismissModalViewControllerAnimated:NO];
        [APP_VIEW_CONTROLLER clearDefaultsCaches:YES];
    }
}

#if FIRMWARE_21_COMPATIBILITY

- (void)keyboardShown:(NSNotification *)notification
{
	CGRect keyboardBounds;
	[[[notification userInfo] valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardBounds];
	
	CGRect tableViewFrame = [self.tableView frame];
	tableViewFrame.size.height -= keyboardBounds.size.height;

	[self.tableView setFrame:tableViewFrame];
}

- (void)keyboardHidden:(NSNotification *)notification
{
	CGRect keyboardBounds;
	[[[notification userInfo] valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardBounds];
	
	CGRect tableViewFrame = [self.tableView frame];
	tableViewFrame.size.height += keyboardBounds.size.height;

	[self.tableView setFrame:tableViewFrame];
}

#endif

@end

