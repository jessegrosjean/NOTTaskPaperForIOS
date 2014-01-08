//
//  IFValueCellController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFValueCellController.h"

#import "IFControlTableViewCell.h"
#import "IFNamedImage.h"

@implementation IFValueCellController

@synthesize indentationLevel;

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		key = [newKey retain];
		model = [newModel retain];
		
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
	[key release];
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
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"DataDataCell";

	IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
		
	}
	
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.indentationLevel = indentationLevel;
	
	// NOTE: The documentation states that the indentation width is 10 "points". It's more like 20
	// pixels and changing the property has no effect on the indentation. We'll use 20.0f here
	// and cross our fingers that this doesn't screw things up in the future.
	
	cell.textLabel.text = label;

	CGSize labelSize = [label sizeWithFont:cell.textLabel.font];
	CGFloat viewWidth = 255.0f - (labelSize.width + (20.0f * indentationLevel));
	
	id value = [model objectForKey:key];
	if ([value isKindOfClass:[NSString class]])
	{
		CGRect frame = CGRectMake(0.0f, 0.0f, viewWidth, 22.0f);
		UILabel *valueLabel = [[UILabel alloc] initWithFrame:frame];
		[valueLabel setText:value];
		[valueLabel setFont:[UIFont systemFontOfSize:17.0f]];
		[valueLabel setBackgroundColor:[UIColor whiteColor]];
		[valueLabel setHighlightedTextColor:[UIColor whiteColor]];
		[valueLabel setTextAlignment:UITextAlignmentRight];
		[valueLabel setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
		cell.view = valueLabel;
		[valueLabel release];
	}
	else if ([value isKindOfClass:[NSNumber class]])
	{
		CGRect frame = CGRectMake(0.0f, 0.0f, viewWidth, 22.0f);
		UILabel *valueLabel = [[UILabel alloc] initWithFrame:frame];
		[valueLabel setText:[value stringValue]];
		[valueLabel setFont:[UIFont systemFontOfSize:17.0f]];
		[valueLabel setBackgroundColor:[UIColor whiteColor]];
		[valueLabel setHighlightedTextColor:[UIColor whiteColor]];
		[valueLabel setTextAlignment:UITextAlignmentRight];
		[valueLabel setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
		cell.view = valueLabel;
		[valueLabel release];
	}
	else
	{
		CGRect frame = CGRectMake(0.0f, 0.0f, viewWidth, 22.0f);
		UILabel *valueLabel = [[UILabel alloc] initWithFrame:frame];
		[valueLabel setText:@"—"];
		[valueLabel setFont:[UIFont systemFontOfSize:17.0f]];
		[valueLabel setBackgroundColor:[UIColor whiteColor]];
		[valueLabel setHighlightedTextColor:[UIColor whiteColor]];
		[valueLabel setTextAlignment:UITextAlignmentRight];
		[valueLabel setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
		cell.view = valueLabel;
		[valueLabel release];
	}
	
	return cell;
}

@end
