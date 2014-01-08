//
//  IFColorCellController.m
//  PlainText
//
//  Created by Jesse Grosjean on 4/17/11.
//

#import "IFColorCellController.h"
#import "ApplicationViewController.h"
#import "IFControlTableViewCell.h"
#import "ApplicationController.h"
#import "CMColourBlockView.h"

@implementation IFColorCellController

@synthesize enabled, updateTarget, updateAction;

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel {
	self = [super init];
	if (self != nil) {
		label = [newLabel retain];
		key = [newKey retain];
		model = [newModel retain];
		enabled = YES;
	}
	return self;
}

- (void)dealloc {
	[label release];
	[key release];
	[model release];
	[super dealloc];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewController *tableViewController = (UITableViewController *)tableView.dataSource;
	ColorPickerViewController *colorPickerViewController = [[[ColorPickerViewController alloc] initWithNibName:@"ColorPicker" bundle:nil tag:1 color:[NSKeyedUnarchiver unarchiveObjectWithData:[model objectForKey:key]]] autorelease];
	colorPickerViewController.navigationItem.title = label;
	colorPickerViewController.delegate = self;
	UIBarButtonItem *current = tableViewController.navigationItem.rightBarButtonItem;
	colorPickerViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:current.title style:current.style target:current.target action:current.action] autorelease];		
	[tableViewController.navigationController pushViewController:colorPickerViewController animated:YES];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"ColorDataCell";
	
	IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	cell.textLabel.text = label;

	CGRect frame = CGRectMake(0.0, 0.0, 80, 27);
	CMColourBlockView *colourView = [[CMColourBlockView alloc] initWithFrame:frame];
	colourView.colour = [NSKeyedUnarchiver unarchiveObjectWithData:[model objectForKey:key]];
	cell.view = colourView;
	
	return cell;
}

- (void)colorPicker:(ColorPickerViewController *)colorPicker didSelectColorWithTag:(NSInteger)usertag Red:(NSUInteger)red Green:(NSUInteger)green Blue:(NSUInteger)blue Alpha:(NSUInteger)alpha {
	[model setObject:[NSKeyedArchiver archivedDataWithRootObject:colorPicker.color] forKey:key];
	
	if (updateTarget && [updateTarget respondsToSelector:updateAction]) {
		[updateTarget performSelector:updateAction withObject:colorPicker];
	}
}

@end
