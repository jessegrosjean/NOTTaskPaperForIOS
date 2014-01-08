//
//  ColorPicker.m
//  ColorPicker
//
//  Created by Claus Bönnhoff on 01.03.11.
//  Copyright 2011 CBC. All rights reserved.
//

#import "ColorPickerViewController.h"

@implementation ColorPickerViewController

- (UIColor *)color {
	return [UIColor colorWithRed:actualColor.red / 255.0 green:actualColor.green / 255.0 blue:actualColor.blue / 255.0 alpha:1.0];
}

@synthesize delegate;
@synthesize previewLabel;
@synthesize twoComponentView,oneComponentView,arrowParentView;
@synthesize arrowView,circleView;

#pragma mark -
#pragma mark Change UI orientation

- (void)rotateBackground:(UIInterfaceOrientation)toInterfaceOrientation {
	[self changeColor];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[self rotateBackground:toInterfaceOrientation];
}

-(void)viewWillAppear:(BOOL)animated {
	[self rotateBackground:self.interfaceOrientation];
}

#pragma mark -
#pragma mark Handle Touches

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {  
	// oneComponent view
	UITouch *touch = [[event touchesForView:self.arrowParentView] anyObject];
	if (touch.view) {
		CGPoint point=[touch locationInView:self.arrowParentView];
		// scale size of picker to 0-255
		point.x=(point.x*255.0/oneComponentView.frame.size.width);
		if(point.x>255)
			point.x=255;
		if(point.x<0)
			point.x=0;
		// r,g,b,h,s,v
		actualColor.hue=point.x*360.0/255.0;
		[self hsvToRGB:&actualColor];
		[self rgbToCMYK:&actualColor];
		[self changeColor];
	}

	// two component view
	touch = [[event touchesForView:self.twoComponentView] anyObject];
	if (touch.view) {
		CGPoint point=[touch locationInView:self.twoComponentView];
		// scale size of picker to 0-255
		point.x=(point.x*255.0/twoComponentView.frame.size.width);
		point.y=(point.y*255.0/twoComponentView.frame.size.height);
		if(point.x>255)
			point.x=255;
		if(point.x<0)
			point.x=0;
		if(point.y>255)
			point.y=255;
		if(point.y<0)
			point.y=0;
		actualColor.vvalue=1.0-point.y/255.0;
		actualColor.saturation=point.x/255.0;
		[self hsvToRGB:&actualColor];
		[self rgbToCMYK:&actualColor];
		[self changeColor];
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	// one component view
	UITouch *touch = [[event touchesForView:self.arrowParentView] anyObject];
	if (touch.tapCount) {
		CGPoint point=[touch locationInView:self.arrowParentView];
		// scale size of picker to 0-255
		point.x=(point.x*255.0/oneComponentView.frame.size.width);
		actualColor.hue=point.x*360.0/255.0;
		[self hsvToRGB:&actualColor];
		[self rgbToCMYK:&actualColor];
		[self changeColor];
	}	
	// two component view
	touch = [[event touchesForView:self.twoComponentView] anyObject];
	if (touch.tapCount) {
		CGPoint point=[touch locationInView:self.twoComponentView];
		// scale size of picker to 0-255
		point.x=(point.x*255.0/twoComponentView.frame.size.width);
		point.y=(point.y*255.0/twoComponentView.frame.size.height);
		actualColor.vvalue=1.0-point.y/255.0;
		actualColor.saturation=point.x/255.0;
		[self hsvToRGB:&actualColor];
		[self rgbToCMYK:&actualColor];
		[self changeColor];
	}
}

#pragma mark -
#pragma mark Convert colors

-(void)rgbToCMYK:(struct rgbhsvColor *)color {
	float cyan = 1-((float)color->red/255.0);
	float magenta = 1-((float)color->green/255.0);
	float yellow = 1-((float)color->blue/255.0);
	float key=1;
	
	if (cyan<key) key=cyan;
	if (magenta<key) key=magenta;
	if (yellow<key) key=yellow;
	if (key==1) {
		cyan=magenta=yellow=0;
	} else {
		cyan=(cyan-key)/(1-key);
		magenta=(magenta-key)/(1-key);
		yellow=(yellow-key)/(1-key);
	}
	
	color->cyan=cyan;
	color->magenta=magenta;
	color->yellow=yellow;
	color->key=key;
}

-(void)cmykToRGB:(struct rgbhsvColor *)color {
	float cyan = (color->cyan*(1-color->key)+color->key);
	float magenta = (color->magenta*(1-color->key)+color->key);
	float yellow = (color->yellow*(1-color->key)+color->key);
	
	color->red = round((1-cyan)*255.0);
	color->green = round((1-magenta)*255.0);
	color->blue = round((1-yellow)*255.0);
}

-(void)hsvToRGB:(struct rgbhsvColor*)color {
	if (color->saturation == 0.0) {
		color->red=round(color->vvalue*255.0);
		color->green=round(color->vvalue*255.0);
		color->blue=round(color->vvalue*255.0);
	} else {
		float hTemp=0.0;
		
		if (color->hue==360.0)
			hTemp=0.0;
		else
			hTemp=color->hue/60.0;
		
		int i = trunc(hTemp);
		float f = hTemp-i;
		float p = color->vvalue*(1.0-color->saturation);
		float q = color->vvalue*(1.0-(color->saturation*f));
		float t = color->vvalue*(1.0-(color->saturation*(1.0-f)));
		
		switch (i) {
			default:
			case 0:
			case 6:
				color->red=round(color->vvalue*255.0);
				color->green=round(t*255.0);
				color->blue=round(p*255.0);
				break;
			case 1:
				color->red=round(q*255.0);
				color->green=round(color->vvalue*255.0);
				color->blue=round(p*255.0);
				break;
			case 2:
				color->red=round(p*255.0);
				color->green=round(color->vvalue*255.0);
				color->blue=round(t*255.0);
				break;
			case 3:
				color->red=round(p*255.0);
				color->green=round(q*255.0);
				color->blue=round(color->vvalue*255.0);
				break;
			case 4:
				color->red=round(t*255.0);
				color->green=round(p*255.0);
				color->blue=round(color->vvalue*255.0);
				break;
			case 5:
				color->red=round(color->vvalue*255.0);
				color->green=round(p*255.0);
				color->blue=round(q*255.0);
				break;
		}
	}
	return;
}

-(void)rgbToHSV:(struct rgbhsvColor*)color {
	UBYTE maxRGBValue = MAX(MAX(color->red,color->green),color->blue);
	float minValue = MIN(MIN(color->red,color->green),color->blue);
	float maxValue = maxRGBValue;
	float hue,saturation,vvalue,delta;
	
	minValue = minValue/255.0;
	maxValue = maxValue/255.0;
	
	vvalue = maxValue;
	delta = vvalue-minValue;
	
	if(delta == 0)
		saturation = 0;
	else 
		saturation = delta/vvalue;
	
    
    hue = 0;
    
	if (saturation == 0)
		hue=0;
	else {
		if(color->red==maxRGBValue)
			hue = 60.0*(float)(color->green-color->blue)/255.0/delta;
		else {
			if(color->green==maxRGBValue)
				hue = 120.0+60.0*(float)(color->blue-color->red)/255.0/delta;
			else {
				if (color->blue==maxRGBValue)
					hue = 240.0+60.0*(float)(color->red-color->green)/255.0/delta;
			}
		}
		if(hue<0.0)
			hue+=360.0;
	}
	color->hue = hue;
	color->saturation = saturation;
	color->vvalue = vvalue;
	return;	
}

#pragma mark -
#pragma mark Draw color views

-(void)drawOneComponentImage {
	int width=CGImageGetWidth(oneComponentView.image.CGImage);
	int height=CGImageGetHeight(oneComponentView.image.CGImage);
	struct rgbhsvColor color;
	
	oneComponentView.image=nil;
	
	UBYTE *data = CGBitmapContextGetData (oneComponentContext);
	CGRect frame;
	
	color.hue=0;
	color.saturation=1.0;
	color.vvalue=1.0;
	for(int x=0;x<width;x++) {
		[self hsvToRGB:&color];
		for(int y=0;y<height;y++) {
			data[x*4+y*width*4]=255;
			data[x*4+y*width*4+1]=color.blue;
			data[x*4+y*width*4+2]=color.green;
			data[x*4+y*width*4+3]=color.red;
		}
		color.hue+=(360.0/255.0);
	}
	
	frame=CGRectMake(((float)actualColor.hue*oneComponentView.frame.size.width/360.0)-10, 0, arrowView.frame.size.width, arrowView.frame.size.height);
	arrowView.frame=frame;
	
	CGImageRef newimage=CGBitmapContextCreateImage(oneComponentContext);
	oneComponentView.image=[UIImage imageWithCGImage:newimage];
	CGImageRelease(newimage);
}

-(void)drawTwoComponentImage {
	int width=CGImageGetWidth(twoComponentView.image.CGImage);
	int height=CGImageGetHeight(twoComponentView.image.CGImage);
	
	twoComponentView.image=nil;
	
	UBYTE *data = CGBitmapContextGetData (twoComponentContext);
	struct rgbhsvColor color;
	
	color.hue=actualColor.hue;
	color.saturation=color.vvalue=0.0;
	for(int x=0;x<width;x++) {
		color.vvalue=1.0;
		for(int y=0;y<height;y++) {
			[self hsvToRGB:&color];
			data[x*4+y*width*4]=255;
			data[x*4+y*width*4+1]=color.blue;
			data[x*4+y*width*4+2]=color.green;
			data[x*4+y*width*4+3]=color.red;
			color.vvalue-=(1.0/255.0);
		}
		color.saturation+=(1.0/255.0);
	}
	
	circleView.frame = CGRectMake(roundf((actualColor.saturation*width)-10),
								  roundf((height-actualColor.vvalue*height)-10),
								  circleView.frame.size.width,
								  circleView.frame.size.height);
	
	CGImageRef newimage=CGBitmapContextCreateImage(twoComponentContext);
	twoComponentView.image=[UIImage imageWithCGImage:newimage];
	CGImageRelease(newimage);
}

CGContextRef CreateARGBBitmapContext (CGImageRef inImage) {
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    UBYTE *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
	
	// Get image width, height. We'll use the entire image.
    int pixelsWide = CGImageGetWidth(inImage);
    int pixelsHigh = CGImageGetHeight(inImage);
	
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (pixelsWide * 4);
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
	
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL) {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
	
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = calloc( bitmapByteCount, sizeof(UBYTE) );
    if (bitmapData == NULL)  {
        fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
	
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits 
    // per component. Regardless of what the source image format is 
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
									 pixelsWide,
									 pixelsHigh,
									 8,      // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedLast);
    if (context == NULL) {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
    }
	
    // Make sure and release colorspace before returning
    CGColorSpaceRelease( colorSpace );
	
    return context;
}

#pragma mark -
#pragma mark Handle textfields

// convert hex value to decimal
-(NSInteger)hexToDec:(NSString *)chr {
	char c=[chr characterAtIndex:(NSUInteger)0];
	switch (c) {
		case 'a':
			return 10;
			break;
		case 'b':
			return 11;
			break;
		case 'c':
			return 12;
			break;
		case 'd':
			return 13;
			break;
		case 'e':
			return 14;
			break;
		case 'f':
			return 15;
			break;
		default:
			return [chr intValue];
			break;
	}
	return 0;
}

-(void)changeColor {
	[self drawOneComponentImage];
	[self drawTwoComponentImage];
    [delegate colorPicker:self didSelectColorWithTag:userTag Red:actualColor.red Green:actualColor.green Blue:actualColor.blue Alpha:round(actualColor.alpha*255.0)];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil tag:(NSInteger)tag color:(UIColor*)color {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		userTag=tag;
        // default color is black
		actualColor.red=actualColor.green=actualColor.blue=0;
		actualColor.alpha=255;
		// must suport rgb color
		if(CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor))==kCGColorSpaceModelRGB) {
			const CGFloat *c = CGColorGetComponents(color.CGColor);
            // RGBA
			actualColor.red=round(c[0]*255);
			actualColor.green=round(c[1]*255);
			actualColor.blue=round(c[2]*255);
			actualColor.alpha=c[3];
            // calc to HSV and CMYK
			[self rgbToHSV:&actualColor];
			[self rgbToCMYK:&actualColor];
		}
        else
            return nil;
	}
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	previewLabel.layer.borderColor = [[UIColor blackColor] CGColor];
	previewLabel.layer.borderWidth = 3;

	// get base image for the two component picker
	UIImage *twoComponentImage=[UIImage imageNamed:@"colorpicker_twocomponent.png"];
	if(twoComponentImage) {
		twoComponentView.layer.borderColor = [[UIColor blackColor] CGColor];
		twoComponentView.layer.borderWidth = 3;
		twoComponentView.image=twoComponentImage;
		// get the bitmap
		twoComponentContext = CreateARGBBitmapContext(twoComponentImage.CGImage);
		if (twoComponentContext!=NULL) 
		{ 
			// Get image width, height. We'll use the entire image.
			size_t imageWidth = CGImageGetWidth(twoComponentImage.CGImage);
			size_t imageHeight = CGImageGetHeight(twoComponentImage.CGImage);
			CGRect imageRect = CGRectMake(0,0,imageWidth,imageHeight); 
			
			// Draw the image to the bitmap context. Once we draw, the memory 
			// allocated for the context for rendering will then contain the 
			// raw image data in the specified color space.
			CGContextDrawImage(twoComponentContext, imageRect, twoComponentImage.CGImage); 
		}
	}
	// get base image for the one component picker
	UIImage *oneComponentImage=[UIImage imageNamed:@"colorpicker_onecomponent.png"];
	if(oneComponentImage)
	{
		oneComponentView.layer.borderColor = [[UIColor blackColor] CGColor];
		oneComponentView.layer.borderWidth = 3;
		oneComponentView.image=oneComponentImage;
		// get the bitmap
		oneComponentContext = CreateARGBBitmapContext(oneComponentImage.CGImage);
		if (oneComponentContext!=NULL) 
		{ 
			// Get image width, height. We'll use the entire image.
			size_t imageWidth = CGImageGetWidth(oneComponentImage.CGImage);
			size_t imageHeight = CGImageGetHeight(oneComponentImage.CGImage);
			CGRect imageRect = CGRectMake(0,0,imageWidth,imageHeight);
			
			// Draw the image to the bitmap context. Once we draw, the memory 
			// allocated for the context for rendering will then contain the 
			// raw image data in the specified color space.
			CGContextDrawImage(oneComponentContext, imageRect, oneComponentImage.CGImage); 
		}
	}
	
	// selector images. circle for two component and arrow for one component
	circleView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"circle.png"]];
	circleView.contentMode=UIViewContentModeScaleToFill;
	arrowView=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrows.png"]];
	
	// add selectors to views
	[twoComponentView addSubview:circleView];
	[arrowParentView addSubview:arrowView];
	
	// draw all
	[self changeColor];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)viewDidUnload {
    [super viewDidUnload];
	if (twoComponentContext) CGContextRelease(twoComponentContext), twoComponentContext=nil; 
	if (oneComponentContext) CGContextRelease(oneComponentContext), oneComponentContext=nil; 
}

- (void)dealloc {
	self.arrowParentView=nil;
	self.oneComponentView=nil;
	self.twoComponentView=nil;
	self.previewLabel=nil;
	self.arrowView=nil;
	self.circleView=nil;
	[super dealloc];
}

@end
