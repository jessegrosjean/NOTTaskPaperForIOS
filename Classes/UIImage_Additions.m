//
//  UIImage_Additions.m
//  PlainText
//
//  Created by Jesse Grosjean on 5/21/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "UIImage_Additions.h"
#import "ColorPickerViewController.h"


@implementation UIImage (Additions)

+ (UIImage *)colorizeImage:(UIImage *)baseImage color:(UIColor *)theColor {
	if (!baseImage) {
		return nil;
	}

	CGFloat baseScale = [baseImage respondsToSelector:@selector(scale)] ? baseImage.scale : 1.0;
	CGSize baseSize = baseImage.size;

    UIGraphicsBeginImageContext(CGSizeMake(baseSize.width * baseScale, baseSize.height * baseScale));
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, baseSize.width * baseScale, baseSize.height * baseScale);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, area, baseImage.CGImage);
    [theColor set];
    CGContextFillRect(ctx, area);
    CGContextRestoreGState(ctx);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

	if (baseScale != 1.0) {
		return [UIImage imageWithCGImage:newImage.CGImage scale:baseScale orientation:UIImageOrientationUp];
	} else {
		return newImage;
	}
}

+ (UIImage *)colorizeImagePixels:(UIImage *)baseImage color:(UIColor *)theColor {
	if (!baseImage || !theColor) {
		return nil;
	}
		
	//theColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
	
	CGFloat baseScale = baseImage.scale;
	UIImageOrientation baseOrientation = baseImage.imageOrientation;
	NSInteger baseLeftCapWidth = baseImage.leftCapWidth;
	NSInteger baseTopCapHeight = baseImage.topCapHeight;
	
	CGContextRef context = CreateARGBBitmapContext(baseImage.CGImage);
	if (context!=NULL) { 
		size_t imageWidth = CGImageGetWidth(baseImage.CGImage);
		size_t imageHeight = CGImageGetHeight(baseImage.CGImage);
		CGRect imageRect = CGRectMake(0,0,imageWidth,imageHeight);
		CGContextDrawImage(context, imageRect, baseImage.CGImage); 
	}
	
	UBYTE *data = CGBitmapContextGetData(context);
	int width=CGImageGetWidth(baseImage.CGImage);
	int height=CGImageGetHeight(baseImage.CGImage);
	const CGFloat *colorComponents = CGColorGetComponents([theColor CGColor]);
	CGFloat colorBrightness = MAX(MAX(colorComponents[0], colorComponents[1]), colorComponents[2]);
	CGFloat brighten = 0;

	if (colorBrightness < 0.5) {
		brighten = 1.0 - colorBrightness;
		//colorComponents[0] += brighten;
		//colorComponents[1] += brighten;
		//colorComponents[2] += brighten;
		//CGFloat minValue = MIN(MIN(colorComponents[0], colorComponents[1]), colorComponents[2]);
		//CGFloat delta = maxValue - minValue;
	}
	
	for(int x=0;x<width;x++) {
		for(int y=0;y<height;y++) {
			UBYTE pixelBrightness = MAX(MAX(data[x*4+y*width*4+1], data[x*4+y*width*4+2]), data[x*4+y*width*4+3]);
			data[x*4+y*width*4+3] = (colorComponents[0] + brighten) * pixelBrightness;
			data[x*4+y*width*4+2] = (colorComponents[1] + brighten) * pixelBrightness;
			data[x*4+y*width*4+1] = (colorComponents[2] + brighten) * pixelBrightness;
		}
	}
	
	CGImageRef newImageRef=CGBitmapContextCreateImage(context);
	UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
	CGImageRelease(newImageRef);
		
	newImage = [UIImage imageWithCGImage:newImage.CGImage scale:baseScale orientation:baseOrientation];
	newImage = [newImage stretchableImageWithLeftCapWidth:baseLeftCapWidth topCapHeight:baseTopCapHeight];
	
	return newImage;
}

@end
