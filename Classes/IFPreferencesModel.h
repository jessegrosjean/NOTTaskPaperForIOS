//
//  IFPreferencesModel.h
//  Thunderbird
//
//  Created by Craig Hockenberry on 1/30/09.
//  Copyright 2009 The Iconfactory. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IFCellModel.h"

@interface IFPreferencesModel : NSObject <IFCellModel>
{
}

- (void)setObject:(id)value forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;

@end
