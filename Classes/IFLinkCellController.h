//
//  IFLinkCellController.h
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//
//  Based on work created by Matt Gallagher on 27/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//	For more information: http://cocoawithlove.com/2008/12/heterogeneous-cells-in.html
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellModel.h"
#import "IFGenericTableViewController.h"

@interface IFLinkCellController : NSObject <IFCellController>
{
	NSString *label;
	NSString *choice;
	UIImage *image;
	IFGenericTableViewController *controller;
	id<IFCellModel> model;
}

- (id)initWithLabel:(NSString *)newLabel usingController:(IFGenericTableViewController *)newController inModel:(id<IFCellModel>)newModel;

@property (nonatomic, retain) NSString *choice;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, readonly) IFGenericTableViewController *controller;

@end
