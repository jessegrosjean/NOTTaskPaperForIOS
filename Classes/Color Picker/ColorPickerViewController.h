//
//  ColorPicker.h
//  ColorPicker
//
//  Created by Claus Bönnhoff on 01.03.11.
//  Copyright 2011 CBC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef unsigned char UBYTE; // color component

@class ColorPickerViewController;

// my color struct
struct rgbhsvColor  {
	UBYTE red,green,blue;				// 0-255 keep rgb in format for raw image data
	float hue,saturation,vvalue,alpha;  // hue 0.0-360.0°; saturation,vvalue and alpha 0.0-1.0
	float cyan,magenta,yellow,key;      // all 0-100%
};

// delegate functions
@protocol ColorPickerDelegate <NSObject>
- (void)colorPicker:(ColorPickerViewController *)colorPicker didSelectColorWithTag:(NSInteger)usertag Red:(NSUInteger)red Green:(NSUInteger)green Blue:(NSUInteger)blue Alpha:(NSUInteger)alpha;
@end

@interface ColorPickerViewController : UIViewController {
    id<ColorPickerDelegate> delegate;
	NSInteger userTag;                                      // identify in delegate method
	UILabel *previewLabel;									// view for the color preview
	UIImageView *twoComponentView,*oneComponentView;		// the two color picker views
	UIImageView *arrowParentView;							// view to position the select arrows on the one component view
	UIImageView *circleView,*arrowView;                     // view for the two selctor images circle and arrows	
	CGContextRef twoComponentContext,oneComponentContext;	// ImageContext to draw directly into images
	struct rgbhsvColor actualColor;                         // actual set color
}

@property (nonatomic, assign) id<ColorPickerDelegate> delegate;

@property (readonly) UIColor *color;
@property (nonatomic, retain) IBOutlet UILabel *previewLabel;
@property (nonatomic, retain) IBOutlet UIImageView *twoComponentView;
@property (nonatomic, retain) IBOutlet UIImageView *oneComponentView;
@property (nonatomic, retain) IBOutlet UIImageView *arrowParentView;
@property (nonatomic, retain) IBOutlet UIImageView *circleView;
@property (nonatomic, retain) IBOutlet UIImageView *arrowView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil tag:(NSInteger)tag color:(UIColor*)newColor;

- (void)rgbToHSV:(struct rgbhsvColor*)color;
- (void)hsvToRGB:(struct rgbhsvColor*)color;
- (void)rgbToCMYK:(struct rgbhsvColor *)color;
- (void)cmykToRGB:(struct rgbhsvColor *)color;
- (void)changeColor;

CGContextRef CreateARGBBitmapContext (CGImageRef inImage);

@end
