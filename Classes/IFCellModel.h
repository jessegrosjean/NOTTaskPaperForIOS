//
//  IFCellModel.h
//  Thunderbird
//
//  Created by Craig Hockenberry on 1/30/09
//  Copyright 2009 The Iconfactory. All rights reserved.
//

@protocol IFCellModel <NSObject>

- (void)setObject:(id)value forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;

@optional
- (void)removeObjectForKey:(NSString *)key;

@end
