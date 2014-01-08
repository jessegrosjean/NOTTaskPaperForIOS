//
//  IFLinkCellController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//
//  Based on work created by Matt Gallagher on 27/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//	For more information: http://cocoawithlove.com/2008/12/heterogeneous-cells-in.html
//

#import "IFLinkCellController.h"

#import "IFGenericTableViewController.h"
#import "IFControlTableViewCell.h"

@implementation IFLinkCellController
@synthesize controller;

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel usingController:(IFGenericTableViewController *)newController inModel:(id<IFCellModel>)newModel
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		controller = [newController retain];
		model = [newModel retain];
	}
	return self;
}

@synthesize choice;
@synthesize image;

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[label release];
	[choice release];
	[image release];
	[controller release];
	[model release];
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
	if ([controller respondsToSelector:@selector(setModel:)]) {
		[controller setModel:model];
	}
	controller.navigationItem.title = label;
	[tableViewController.navigationController pushViewController:controller animated:YES];

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"LinkDataCell";

	IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	cell.textLabel.text = label;
	cell.imageView.image = image;
	/*CGRect f = cell.imageView.frame;
	f.size.width = 30;
	cell.imageView.frame = f;*/
	
	NSInteger indentationLevel = 1;
	CGSize labelSize = [label sizeWithFont:cell.textLabel.font];
	CGFloat viewWidth = 255.0f - (labelSize.width + (20.0f * indentationLevel));
	
	if ([choice isKindOfClass:[NSString class]]) {
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
	
	return cell;
}

@end
