//
//  IFSwitchCellController.h
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellModel.h"

@interface IFSwitchCellController : NSObject <IFCellController>
{
	BOOL enabled;
	NSString *label;
	id<IFCellModel> model;
	NSString *key;

	SEL updateAction;
	id updateTarget;
}

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;

@end




