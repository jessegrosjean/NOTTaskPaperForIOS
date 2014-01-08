//
//  IFChoiceTableViewController.m
//  Thunderbird
//
//  Created by Craig Hockenberry on 1/29/09.
//  Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFChoiceTableViewController.h"

#import "IFNamedImage.h"

@implementation IFChoiceTableViewController

@synthesize updateAction;
@synthesize updateTarget;

@synthesize footerNote;

@synthesize choices;
@synthesize choiceValues;
@synthesize model, key;

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
}

- (IBAction)dismissModalViewControllerAction:(id)sender {
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [choices count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = 44.0f;
	
	NSUInteger row = [indexPath row];
	id choice = [choices objectAtIndex:row];
	if ([choice isKindOfClass:[IFNamedImage class]])
	{
		CGSize imageSize = [[choice image] size];
		if (imageSize.height < 44.0f)
		{
			result = 44.0f;
		}
		else
		{
			result = imageSize.height + 20.0f + 1.0f;
		}
	}
	else if ([choice isKindOfClass:[UIImage class]])
	{
		CGSize imageSize = [(UIImage *)choice size];
		result = imageSize.height + 20.0f + 1.0f;
	}

	return result;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return footerNote;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *cellIdentifier = @"ChoiceSelectionCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
	}
	
	NSUInteger row = [indexPath row];
	id choice = [choices objectAtIndex:row];
	if ([choice isKindOfClass:[NSString class]])
	{
		cell.textLabel.text = choice;
		cell.imageView.image = nil;
	}
	else if ([choice isKindOfClass:[IFNamedImage class]])
	{
		UIImage *image = [choice image];
		CGSize imageSize = [image size];
		
		cell.imageView.image = image;
		if (imageSize.width < 44.0f)
		{
			cell.textLabel.text = [choice name];
		}
		else
		{
			cell.textLabel.text = nil;
		}
	}
	else if ([choice isKindOfClass:[UIImage class]])
	{
		cell.imageView.image = choice;
		cell.textLabel.text = nil;
	}
	else
	{
		cell.imageView.image = nil;
		cell.textLabel.text = nil;
	}

	if (choiceValues) {
		if ([choiceValues objectAtIndex:row] == [model objectForKey:key]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	} else {
		if (row == [[model objectForKey:key] intValue]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger row = [indexPath row];
	if (choiceValues) {
        NSLog(@"%@", [choiceValues objectAtIndex:row]);
        NSLog(@"model: %@", model);
		[model setObject:[choiceValues objectAtIndex:row] forKey:key];
	} else {
		[model setObject:[NSNumber numberWithInt:row] forKey:key];
	}

	if (updateTarget && [updateTarget respondsToSelector:updateAction])
	{
		[updateTarget performSelector:updateAction withObject:tableView];
	}

	for (NSIndexPath *visibleIndexPath in [tableView indexPathsForVisibleRows])
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:visibleIndexPath];
		NSUInteger visibleRow = [visibleIndexPath row];
		if (visibleRow == row)
		{
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		else
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)dealloc
{
	[choices release];
	[choiceValues release];
	[model release];
	[key release];
	
	[footerNote release];
	
	[super dealloc];
}

@end

