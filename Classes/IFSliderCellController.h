//
//  IFSliderCellController.h
//  PlainText
//
//  Created by Jesse Grosjean on 4/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "IFCellController.h"
#import "IFCellModel.h"

@interface IFSliderCellController : NSObject <IFCellController>
{
	BOOL enabled;
	CGFloat minValue;
	CGFloat maxValue;
	NSString *label;
	id<IFCellModel> model;
	NSString *key;
	
	SEL updateAction;
	id updateTarget;
}

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

- (id)initWithLabel:(NSString *)newLabel minValue:(CGFloat)minValue maxValue:(CGFloat)maxValue atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;

@end