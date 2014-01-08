//
//  IFSliderCellController.m
//  PlainText
//
//  Created by Jesse Grosjean on 4/18/11.
//

#import "IFSliderCellController.h"
#import "IFControlTableViewCell.h"


@implementation IFSliderCellController

@synthesize enabled, updateTarget, updateAction;

- (id)initWithLabel:(NSString *)newLabel minValue:(CGFloat)aMinValue maxValue:(CGFloat)aMaxValue atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel {
	self = [super init];
	if (self != nil) {
		label = [newLabel retain];
		key = [newKey retain];
		model = [newModel retain];
		enabled = YES;
		minValue = aMinValue;
		maxValue = aMaxValue;
	}
	return self;
}

- (void)dealloc {
	[label release];
	[key release];
	[model release];
	[super dealloc];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"SliderDataCell";
	
	IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];		
	}
	
	cell.textLabel.text = label;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	CGRect frame = CGRectMake(0.0, 0.0, 150.0, 27.0);
	UISlider *sliderControl = [[UISlider alloc] initWithFrame:frame];
	sliderControl.minimumValue = minValue;
	sliderControl.maximumValue = maxValue;
	[sliderControl addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
	NSNumber *value = [model objectForKey:key];
	[sliderControl setValue:[value floatValue]];
	sliderControl.enabled = enabled;
	cell.view = sliderControl;
	[sliderControl release];
	
	return cell;
}

- (void)sliderAction:(id)sender {
	NSNumber *newValue = [NSNumber numberWithFloat:[(UISlider *)sender value]];
	
	[model setObject:newValue forKey:key];
	
	if (updateTarget && [updateTarget respondsToSelector:updateAction]) {
		[updateTarget performSelector:updateAction withObject:sender];
	}
}

@end
