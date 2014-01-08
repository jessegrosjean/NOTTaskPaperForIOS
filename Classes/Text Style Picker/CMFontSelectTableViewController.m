//
//  CMFontSelectTableViewController.m
//  CMTextStylePicker
//
//  Created by Chris Miles on 20/10/10.
//  Copyright (c) Chris Miles 2010.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "CMFontSelectTableViewController.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"


#define kSelectedLabelTag		1001
#define kFontNameLabelTag		1002

@implementation CMFontSelectTableViewController

@synthesize delegate;
@synthesize fontFamilyNames, selectedFont;
@synthesize clearDefaultsCaches;

#pragma mark -
#pragma mark FontStyleSelectTableViewControllerDelegate methods

- (void)fontStyleSelectTableViewController:(CMFontStyleSelectTableViewController *)fontStyleSelectTableViewController didSelectFont:(UIFont *)font {
	self.selectedFont = font;
	
	[delegate fontSelectTableViewController:self didSelectFont:self.selectedFont];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

	self.fontFamilyNames = [[UIFont familyNames] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    clearDefaultsCaches = NO;
#ifdef TASKPAPER
    //remove no bold fonts
    NSIndexSet *indexes = [self.fontFamilyNames indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSString *fontFamilyName = obj;
        NSArray *fontNames = [UIFont fontNamesForFamilyName:fontFamilyName];
        if ([fontNames count] > 1) {
            for (NSString *fontName in fontNames) {
                if ([[fontName uppercaseString] hasSuffix:@"-BOLD"] || [[fontName uppercaseString] hasSuffix:@"BOLDMT"]) {
                    return YES;
                }
            }
        }
        return NO;
    }];  
    self.fontFamilyNames = [fontFamilyNames objectsAtIndexes:indexes];
#endif
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fontFamilyNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"FontSelectTableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		
		CGRect frame = CGRectMake(10.0, 5.0, 25.0, cell.frame.size.height-5.0);
		UILabel *selectedLabel = [[UILabel alloc] initWithFrame:frame];
		selectedLabel.tag = kSelectedLabelTag;
		selectedLabel.font = [UIFont systemFontOfSize:24.0];
		[cell.contentView addSubview:selectedLabel];
		[selectedLabel release];
		
		frame = CGRectMake(35.0, 5.0, cell.frame.size.width-70.0, cell.frame.size.height-5.0);
		UILabel *fontNameLabel = [[UILabel alloc] initWithFrame:frame];
		fontNameLabel.tag = kFontNameLabelTag;
		[cell.contentView addSubview:fontNameLabel];
		[fontNameLabel release];
    }
    
    // Configure the cell...
	NSString *fontFamilyName = [self.fontFamilyNames objectAtIndex:indexPath.row];
	
	UILabel *fontNameLabel = (UILabel *)[cell viewWithTag:kFontNameLabelTag];
	
	fontNameLabel.text = fontFamilyName;
	fontNameLabel.font = [UIFont fontWithName:fontFamilyName size:16.0];
	
	if ([[UIFont fontNamesForFamilyName:fontFamilyName] count] > 1) {
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}
	else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	UILabel *selectedLabel = (UILabel *)[cell viewWithTag:kSelectedLabelTag];
	if ([self.selectedFont.familyName isEqualToString:fontFamilyName]) {
		selectedLabel.text = @"✔";
	}
	else {
		selectedLabel.text = @"";
	}

    
    return cell;
}

- (void)setClearDefaultsCaches:(BOOL)newValue {
    if (IS_IPAD) {
        [APP_VIEW_CONTROLLER clearDefaultsCaches:YES];
    } else {
        clearDefaultsCaches = newValue;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.clearDefaultsCaches = YES;
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	CMFontStyleSelectTableViewController *fontStyleSelectTableViewController = [[CMFontStyleSelectTableViewController alloc] init];
	fontStyleSelectTableViewController.fontFamilyName = [self.fontFamilyNames objectAtIndex:indexPath.row];
	fontStyleSelectTableViewController.selectedFont = self.selectedFont;
	fontStyleSelectTableViewController.delegate = self;
	fontStyleSelectTableViewController.title = NSLocalizedString(@"Font Style", nil);
	UIBarButtonItem *current = self.navigationItem.rightBarButtonItem;
	fontStyleSelectTableViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:current.title style:current.style target:current.target action:current.action] autorelease];		
	[self.navigationController pushViewController:fontStyleSelectTableViewController animated:YES];
	[fontStyleSelectTableViewController release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *fontName = [self.fontFamilyNames objectAtIndex:indexPath.row];
	self.selectedFont = [UIFont fontWithName:fontName size:self.selectedFont.pointSize];
	
	[delegate fontSelectTableViewController:self didSelectFont:self.selectedFont];
	[tableView reloadData];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[fontFamilyNames release];
	[selectedFont release];
	
    [super dealloc];
}


@end

