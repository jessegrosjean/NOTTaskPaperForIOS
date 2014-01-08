//
//  IFUpDownCellController.m
//  PlainText
//
//  Created by Jesse Grosjean on 4/17/11.
//

#import "IFUpDownCellController.h"
#import	"IFControlTableViewCell.h"
#import "CMUpDownControl.h"


@implementation IFUpDownCellController

@synthesize enabled, updateTarget, updateAction;

- (id)initWithLabel:(NSString *)newLabel stepValue:(CGFloat)aStepValue minValue:(CGFloat)aMinValue maxValue:(CGFloat)aMaxValue valueFormatter:(NSNumberFormatter *)aValueFormatter units:(NSString *)aUnits atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel {
	self = [super init];
	if (self != nil) {
		label = [newLabel retain];
		key = [newKey retain];
		model = [newModel retain];
		enabled = YES;
		stepValue = aStepValue;
		minValue = aMinValue;
		maxValue = aMaxValue;
		valueFormatter = [aValueFormatter retain];
		units = [aUnits retain];
	}
	return self;
}

- (void)dealloc {
	[label release];
	[key release];
	[model release];
	[valueFormatter release];
	[units release];
	[super dealloc];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"UpDownDataCell";
	
	IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];		
	}
	
	cell.textLabel.text = label;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 70.0);
	CMUpDownControl *upDownController = [[[CMUpDownControl alloc] initWithFrame:frame] autorelease];
	[upDownController addTarget:self action:@selector(upDownAction:) forControlEvents:UIControlEventValueChanged];
	upDownController.opaque = NO;
	upDownController.stepValue = stepValue;
	upDownController.minimumAllowedValue = minValue;
	upDownController.maximumAllowedValue = maxValue;
	upDownController.valueFormatter = valueFormatter;
	upDownController.units = units;
	[upDownController setValue:[[model objectForKey:key] floatValue]];
	upDownController.enabled = enabled;
	cell.view = upDownController;
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 90;
}

- (void)upDownAction:(CMUpDownControl *)sender {
	NSNumber *newValue = [NSNumber numberWithFloat:[sender value]];
	
	[model setObject:newValue forKey:key];
	
	if (updateTarget && [updateTarget respondsToSelector:updateAction]) {
		[updateTarget performSelector:updateAction withObject:sender];
	}
}

@end
