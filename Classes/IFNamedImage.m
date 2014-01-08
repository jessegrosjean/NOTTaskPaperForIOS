//
//  IFNamedImage.m
//  Thunderbird
//
//  Created by Craig Hockenberry on 1/30/09.
//  Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFNamedImage.h"


@implementation IFNamedImage

@synthesize image, name;

+ (IFNamedImage *)image:(UIImage *)newImage withName:(NSString *)newName;
{
	return [[[IFNamedImage alloc] initWithImage:newImage andName:newName] autorelease];
}

- (id)initWithImage:(UIImage *)newImage andName:(NSString *)newName
{
	self = [super init];
	if (self != nil)
	{
		name = [newName retain];
		image = [newImage retain];
	}
	return self;
}

- (void)dealloc
{
	[name release];
	[image release];
	
	[super dealloc];
}

@end
