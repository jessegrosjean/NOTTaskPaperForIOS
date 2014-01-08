//
//  IFTemporaryModel.h
//  Thunderbird
//
//  Created by Craig Hockenberry on 1/30/09.
//  Copyright 2009 The Iconfactory. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IFCellModel.h"

@interface IFTemporaryModel : NSObject <IFCellModel>
{
	NSMutableDictionary *_temporaryModel;
}

- (id)initWithDictionary:(NSMutableDictionary *)dictionary;

- (void)setObject:(id)value forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;

- (NSMutableDictionary *)dictionary;

@end
