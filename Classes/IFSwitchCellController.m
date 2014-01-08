//
//  IFSwitchCellController.h
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFSwitchCellController.h"

#import	"IFControlTableViewCell.h"

@implementation IFSwitchCellController

@synthesize enabled, updateTarget, updateAction;

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		key = [newKey retain];
		model = [newModel retain];
		enabled = YES;
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
	[key release];
	[model release];
	
	[super dealloc];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"SwitchDataCell";
	
	IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];		
	}
	
	cell.textLabel.text = label;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	CGRect frame = CGRectMake(0.0, 0.0, 94.0, 27.0);
	UISwitch *switchControl = [[UISwitch alloc] initWithFrame:frame];
	[switchControl addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
	NSNumber *value = [model objectForKey:key];
	[switchControl setOn:[value boolValue]];
	switchControl.enabled = enabled;
	cell.view = switchControl;
	[switchControl release];

	return cell;
}

- (void)switchAction:(id)sender
{
	// update the model with the switch change

	NSNumber *oldValue = [model objectForKey:key];
	NSNumber *newValue = [NSNumber numberWithBool:! [oldValue boolValue]];

	[model setObject:newValue forKey:key];

	if (updateTarget && [updateTarget respondsToSelector:updateAction])
	{
		[updateTarget performSelector:updateAction withObject:sender];
	}
}

@end
