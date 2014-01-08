//
//  IFChoiceTableViewController.h
//  Thunderbird
//
//  Created by Craig Hockenberry on 1/29/09.
//  Copyright 2009 The Iconfactory. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellModel.h"

@class IFChoiceTableViewController;

@interface IFChoiceTableViewController : UITableViewController
{
	SEL updateAction;
	id updateTarget;

	NSString *footerNote;
	
	NSArray *choices;
	NSArray *choiceValues;
	id<IFCellModel> model;
	NSString *key;
}

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, retain) NSString *footerNote;
	
@property (nonatomic, retain) NSArray *choices;
@property (nonatomic, retain) NSArray *choiceValues;
@property (nonatomic, retain) id<IFCellModel> model;
@property (nonatomic, retain) NSString *key;

@end

