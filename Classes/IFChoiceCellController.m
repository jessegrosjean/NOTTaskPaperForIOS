//
//  IFChoiceRowCellController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFChoiceCellController.h"
#import "ApplicationViewController.h"
#import "IFControlTableViewCell.h"
#import "IFNamedImage.h"

@implementation IFChoiceCellController

@synthesize updateTarget, updateAction;

@synthesize footerNote;

@synthesize indentationLevel;

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel andChoices:(NSArray *)newChoices andChoiceValues:(NSArray *)newChoiceValues atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		choices = [newChoices retain];
		choiceValues = [newChoiceValues retain];
		key = [newKey retain];
		model = [newModel retain];

		footerNote = nil;
		
		indentationLevel = 0;
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
	[choices release];
	[choiceValues release];
	[key release];
	[model release];
	
	[footerNote release];
	
	[super dealloc];
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewController *tableViewController = (UITableViewController *)tableView.dataSource;
	
	IFChoiceTableViewController *choiceTableViewController = [[IFChoiceTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
	choiceTableViewController.title = label;
	choiceTableViewController.choices = choices;
	choiceTableViewController.choiceValues = choiceValues;
	choiceTableViewController.model = model;
	choiceTableViewController.key = key;
	choiceTableViewController.updateTarget = updateTarget;
	choiceTableViewController.updateAction = updateAction;
	choiceTableViewController.footerNote = footerNote;
	[tableViewController.navigationController pushViewController:choiceTableViewController animated:YES];
	[choiceTableViewController release];

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"ChoiceDataCell";

	IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
		
	}
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.indentationLevel = indentationLevel;
	
	// NOTE: The documentation states that the indentation width is 10 "points". It's more like 20
	// pixels and changing the property has no effect on the indentation. We'll use 20.0f here
	// and cross our fingers that this doesn't screw things up in the future.
	
	if (! label || [label length] == 0)
	{
		// choice acts as label

		id choice = [choices objectAtIndex:[[model objectForKey:key] intValue]];
		if ([choice isKindOfClass:[NSString class]])
		{
			cell.textLabel.text = choice;
		}
		else if ([choice isKindOfClass:[IFNamedImage class]])
		{
			cell.textLabel.text = [choice name];
			cell.imageView.image = [choice image];
		}
	}
	else
	{
		// choice is subview in cell

		cell.textLabel.text = label;
		
		CGSize labelSize = [label sizeWithFont:cell.textLabel.font];
		CGFloat viewWidth = 255.0f - (labelSize.width + (20.0f * indentationLevel));
		
		NSUInteger choiceIndex = [[model objectForKey:key] intValue];
		if (choiceIndex >= [choices count])
		{
			choiceIndex = 0;
			[model setObject:[NSNumber numberWithInt:choiceIndex] forKey:key];
		}
		id choice = [choices objectAtIndex:choiceIndex];
		if ([choice isKindOfClass:[NSString class]])
		{
			CGRect frame = CGRectMake(0.0f, 0.0f, viewWidth, 22.0f);
			UILabel *choiceLabel = [[UILabel alloc] initWithFrame:frame];
			[choiceLabel setText:choice];
			[choiceLabel setFont:[UIFont systemFontOfSize:17.0f]];
			[choiceLabel setBackgroundColor:[UIColor clearColor]];
			[choiceLabel setHighlightedTextColor:[UIColor whiteColor]];
			[choiceLabel setTextAlignment:UITextAlignmentRight];
			[choiceLabel setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
			cell.view = choiceLabel;
			[choiceLabel release];
		}
		else if ([choice isKindOfClass:[IFNamedImage class]])
		{
			CGRect frame = CGRectMake(0.0f, 0.0f, viewWidth, 22.0f);
			UILabel *choiceLabel = [[UILabel alloc] initWithFrame:frame];
			[choiceLabel setText:[choice name]];
			[choiceLabel setFont:[UIFont systemFontOfSize:17.0f]];
			[choiceLabel setBackgroundColor:[UIColor clearColor]];
			[choiceLabel setHighlightedTextColor:[UIColor whiteColor]];
			[choiceLabel setTextAlignment:UITextAlignmentRight];
			[choiceLabel setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
			cell.view = choiceLabel;
			[choiceLabel release];
		}
	}
	
	return cell;
}

@end
