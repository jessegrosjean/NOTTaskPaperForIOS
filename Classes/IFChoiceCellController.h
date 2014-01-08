//
//  IFChoiceCellController.h
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellModel.h"

#import "IFChoiceTableViewController.h"

@interface IFChoiceCellController : NSObject <IFCellController>
{
	NSString *label;
	NSArray *choices;
	NSArray *choiceValues;
	id<IFCellModel> model;
	NSString *key;

	SEL updateAction;
	id updateTarget;

	NSString *footerNote;
	
	NSInteger indentationLevel;
}

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, retain) NSString *footerNote;
	
@property (nonatomic, assign) NSInteger indentationLevel;

- (id)initWithLabel:(NSString *)newLabel andChoices:(NSArray *)newChoices andChoiceValues:(NSArray *)newChoiceValues atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;

@end
