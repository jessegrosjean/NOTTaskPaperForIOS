//
//  IFValueCellController.h
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellModel.h"

@interface IFValueCellController : NSObject <IFCellController>
{
	NSString *label;
	id<IFCellModel> model;
	NSString *key;

	NSInteger indentationLevel;
}

@property (nonatomic, assign) NSInteger indentationLevel;

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;

@end
