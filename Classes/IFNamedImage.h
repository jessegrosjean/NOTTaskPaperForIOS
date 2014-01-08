//
//  IFNamedImage.h
//  Thunderbird
//
//  Created by Craig Hockenberry on 1/30/09.
//  Copyright 2009 The Iconfactory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IFNamedImage : NSObject
{
	UIImage *image;
	NSString *name;
}

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSString *name;

+ (IFNamedImage *)image:(UIImage *)newImage withName:(NSString *)newName;

- (id)initWithImage:(UIImage *)newImage andName:(NSString *)newName;

@end
