//
//  CMFontStyleSelectTableViewController.m
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

#import "CMFontStyleSelectTableViewController.h"

#define kSelectedLabelTag		1001
#define kFontNameLabelTag		1002


@implementation CMFontStyleSelectTableViewController

@synthesize delegate;
@synthesize fontFamilyName;
@synthesize fontNames, selectedFont;


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

	assert(self.fontFamilyName != nil);
	
	self.fontNames = [[UIFont fontNamesForFamilyName:self.fontFamilyName]
					  sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
}

- (IBAction)dismissModalViewControllerAction:(id)sender {
	[self.navigationController dismissModalViewControllerAnimated:YES];
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
    return [self.fontNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FontStyleSelectTableCell";
    
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
    
	NSString *fontName = [self.fontNames objectAtIndex:indexPath.row];
	UILabel *fontNameLabel = (UILabel *)[cell viewWithTag:kFontNameLabelTag];
	fontNameLabel.text = fontName;
	fontNameLabel.font = [UIFont fontWithName:fontName size:16.0];
	
	UILabel *selectedLabel = (UILabel *)[cell viewWithTag:kSelectedLabelTag];
	if ([self.selectedFont.fontName isEqualToString:fontName]) {
		selectedLabel.text = @"✔";
	}
	else {
		selectedLabel.text = @"";
	}
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *fontName = [self.fontNames objectAtIndex:indexPath.row];
	self.selectedFont = [UIFont fontWithName:fontName size:self.selectedFont.pointSize];	
	[delegate fontStyleSelectTableViewController:self didSelectFont:self.selectedFont];
	[tableView reloadData];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[fontFamilyName release];
	[fontNames release];
	[selectedFont release];
    [super dealloc];
}

@end

