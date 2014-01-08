//
//  CMUpDownControl.m
//  CMTextStylePicker
//
//  Created by Chris Miles on 18/10/10.
//  Copyright (c) Chris Miles 2010.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "CMUpDownControl.h"

#define kCornerRadius	4.0
#define kArrowWidth		10.0
#define kArrowHeight	10.0


@implementation CMUpDownControl

@synthesize maximumAllowedValue, minimumAllowedValue, stepValue, value, valueFormatter, units;

- (void)processTouchUp {
	BOOL valueChanged = NO;
	
	if (_topHalfSelected) {
		// Attempt to increment value
		if (value < maximumAllowedValue) {
			value += stepValue;
			valueChanged = YES;
		}
	}
	else {
		// Attempt to decrement value
		if (value > minimumAllowedValue) {
			value -= stepValue;
			valueChanged = YES;
		}
	}

	if (valueChanged) {
		[self setNeedsDisplay];
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}
}

- (void)drawRect:(CGRect)rect {
	BOOL highlightTopHalf = NO;
	BOOL highlightBottomHalf = NO;
	
	if (_touchNeedsDisplay || _selected) {
		if (_topHalfSelected) {
			highlightTopHalf = YES;
		}
		else {
			highlightBottomHalf = YES;
		}

		_touchNeedsDisplay = NO;
	}
	
	CGContextRef c = UIGraphicsGetCurrentContext(); 

	CGRect bounds = self.bounds;
	
	CGMutablePathRef boundaryPath = CGPathCreateMutable();
	CGPathMoveToPoint(boundaryPath, NULL, bounds.origin.x+kCornerRadius, bounds.origin.y);
	// Top border
	CGPathAddLineToPoint(boundaryPath, NULL, bounds.origin.x+bounds.size.width-kCornerRadius, bounds.origin.y);
	// Top/Right curve
	CGPathAddArcToPoint(boundaryPath, NULL,
						bounds.origin.x+bounds.size.width, bounds.origin.y,
						bounds.origin.x+bounds.size.width, bounds.origin.y+kCornerRadius,
						kCornerRadius);
	// Right border
	CGPathAddLineToPoint(boundaryPath, NULL, bounds.origin.x+bounds.size.width, bounds.origin.y+bounds.size.height-kCornerRadius);
	// Bottom/Right curve
	CGPathAddArcToPoint(boundaryPath, NULL,
						bounds.origin.x+bounds.size.width, bounds.origin.y+bounds.size.height,
						bounds.origin.x+bounds.size.width-kCornerRadius, bounds.origin.y+bounds.size.height,
						kCornerRadius);
	// Bottom border
	CGPathAddLineToPoint(boundaryPath, NULL, bounds.origin.x+kCornerRadius, bounds.origin.y+bounds.size.height);
	// Bottom/Left curve
	CGPathAddArcToPoint(boundaryPath, NULL,
						bounds.origin.x, bounds.origin.y+bounds.size.height,
						bounds.origin.x, bounds.origin.y+bounds.size.height-kCornerRadius,
						kCornerRadius);
	// Left border
	CGPathAddLineToPoint(boundaryPath, NULL, bounds.origin.x, bounds.origin.y+kCornerRadius);
	// Top/Left curve
	CGPathAddArcToPoint(boundaryPath, NULL,
						bounds.origin.x, bounds.origin.y,
						bounds.origin.x+kCornerRadius, bounds.origin.y,
						kCornerRadius);
	
	CGPathCloseSubpath(boundaryPath);

	// Draw clipped background gradient
	CGContextAddPath(c, boundaryPath);
	CGContextClip(c);

	CGGradientRef myGradient;
	CGColorSpaceRef myColorSpace;
	size_t locationCount = 2;
	CGFloat locationList[] = {0.0, 1.0};
	
	UIColor *topColor = [UIColor colorWithRed:214.0/255.0 green:214.0/255.0 blue:214.0/255.0 alpha:1.0];
	UIColor *bottomColor = [UIColor colorWithRed:252.0/255.0 green:252.0/255.0 blue:252.0/255.0 alpha:1.0];
	const CGFloat *topColorComponents = CGColorGetComponents([topColor CGColor]);
	const CGFloat *bottomColorComponents = CGColorGetComponents([bottomColor CGColor]);
	CGFloat colorList[] = {
		//red, green, blue, alpha 
		topColorComponents[0],    topColorComponents[1],    topColorComponents[2],    topColorComponents[3],
		bottomColorComponents[0], bottomColorComponents[1], bottomColorComponents[2], bottomColorComponents[3]
	};
	
	myColorSpace = CGColorSpaceCreateDeviceRGB();
	myGradient = CGGradientCreateWithColorComponents(myColorSpace, colorList, locationList, locationCount);
	CGPoint startPoint, endPoint;
	startPoint.x = 0;
	startPoint.y = 0;
	endPoint.x = 0;
	endPoint.y = CGRectGetMaxY(self.bounds);
	
	CGContextDrawLinearGradient(c, myGradient, startPoint, endPoint,0);
	CGGradientRelease(myGradient);
	CGColorSpaceRelease(myColorSpace);
	
	if (highlightBottomHalf) {
		// "Highlight" the bottom half with a darker gradient
		size_t locationCount = 2;
		CGFloat locationList[] = {0.0, 1.0};
		
		UIColor *topColor = [UIColor colorWithRed:225.0/255.0 green:225.0/255.0 blue:225.0/255.0 alpha:1.0];
		UIColor *bottomColor = [UIColor colorWithRed:252.0/255.0 green:252.0/255.0 blue:252.0/255.0 alpha:1.0];
		topColorComponents = CGColorGetComponents([topColor CGColor]);
		bottomColorComponents = CGColorGetComponents([bottomColor CGColor]);
		CGFloat colorList[] = {
			//red, green, blue, alpha 
			topColorComponents[0],    topColorComponents[1],    topColorComponents[2],    topColorComponents[3],
			bottomColorComponents[0], bottomColorComponents[1], bottomColorComponents[2], bottomColorComponents[3]
		};
		
		myColorSpace = CGColorSpaceCreateDeviceRGB();
		myGradient = CGGradientCreateWithColorComponents(myColorSpace, colorList, locationList, locationCount);
		CGPoint startPoint, endPoint;
		startPoint.x = 0;
		startPoint.y = CGRectGetMaxY(self.bounds)/2;
		endPoint.x = 0;
		endPoint.y = CGRectGetMaxY(self.bounds);
		
		CGContextDrawLinearGradient(c, myGradient, startPoint, endPoint,0);
		CGGradientRelease(myGradient);
		CGColorSpaceRelease(myColorSpace);
	}
	
	if (highlightTopHalf) {
		// "Highlight" the top half with a darker gradient
		size_t locationCount = 2;
		CGFloat locationList[] = {0.0, 1.0};
		
		UIColor *topColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0];
		UIColor *bottomColor = [UIColor colorWithRed:233.0/255.0 green:233.0/255.0 blue:233.0/255.0 alpha:1.0];
		topColorComponents = CGColorGetComponents([topColor CGColor]);
		bottomColorComponents = CGColorGetComponents([bottomColor CGColor]);
		CGFloat colorList[] = {
			//red, green, blue, alpha 
			topColorComponents[0],    topColorComponents[1],    topColorComponents[2],    topColorComponents[3],
			bottomColorComponents[0], bottomColorComponents[1], bottomColorComponents[2], bottomColorComponents[3]
		};
		
		myColorSpace = CGColorSpaceCreateDeviceRGB();
		myGradient = CGGradientCreateWithColorComponents(myColorSpace, colorList, locationList, locationCount);
		CGPoint startPoint, endPoint;
		startPoint.x = 0;
		startPoint.y = 0;
		endPoint.x = 0;
		endPoint.y = CGRectGetMaxY(self.bounds)/2;
		
		CGContextDrawLinearGradient(c, myGradient, startPoint, endPoint,0);
		CGGradientRelease(myGradient);
		CGColorSpaceRelease(myColorSpace);
	}
	
	
	if (!highlightTopHalf) {
		// Draw top highlight (just below top boundary)
		CGMutablePathRef topHighlightPath = CGPathCreateMutable();
		CGPathMoveToPoint(topHighlightPath, NULL, bounds.origin.x+kCornerRadius/2, bounds.origin.y+1.0);
		CGPathAddLineToPoint(topHighlightPath, NULL, bounds.origin.x+bounds.size.width-kCornerRadius/2, bounds.origin.y+1.0);
		CGContextSetRGBStrokeColor(c, 234.0/255.0, 234.0/255.0, 234.0/255.0, 1.0);
		CGContextAddPath(c, topHighlightPath);
		CGContextDrawPath(c, kCGPathStroke);
		CGPathRelease(topHighlightPath);
	}
	

	// Draw middle highlight (just below horizontal divider)
	CGMutablePathRef middleHighlightPath = CGPathCreateMutable();
	CGPathMoveToPoint(middleHighlightPath, NULL, bounds.origin.x+1.0, bounds.origin.y+bounds.size.height/2+1);
	CGPathAddLineToPoint(middleHighlightPath, NULL, bounds.origin.x+bounds.size.width-1.0, bounds.origin.y+bounds.size.height/2+1);
	CGContextSetRGBStrokeColor(c, 244.0/255.0, 244.0/255.0, 244.0/255.0, 1.0);
	CGContextAddPath(c, middleHighlightPath);
	CGContextDrawPath(c, kCGPathStroke);
	CGPathRelease(middleHighlightPath);
	
	
	
	// Create stroke path, which includes the horizontal divider
	CGMutablePathRef strokePath = CGPathCreateMutable();
	CGPathMoveToPoint(strokePath, NULL, bounds.origin.x, bounds.origin.y+bounds.size.height/2);
	// Left border: top half
	CGPathAddLineToPoint(strokePath, NULL, bounds.origin.x, bounds.origin.y+kCornerRadius);
	// Top/Left curve
	CGPathAddArcToPoint(strokePath, NULL,
						bounds.origin.x, bounds.origin.y,
						bounds.origin.x+kCornerRadius, bounds.origin.y,
						kCornerRadius);
	// Top border
	CGPathAddLineToPoint(strokePath, NULL, bounds.origin.x+bounds.size.width-kCornerRadius, bounds.origin.y);
	// Top/Right curve
	CGPathAddArcToPoint(strokePath, NULL,
						bounds.origin.x+bounds.size.width, bounds.origin.y,
						bounds.origin.x+bounds.size.width, bounds.origin.y+kCornerRadius,
						kCornerRadius);
	// Right border: top half
	CGPathAddLineToPoint(strokePath, NULL, bounds.origin.x+bounds.size.width, bounds.origin.y+bounds.size.height/2);
	// Horizontal divider
	CGPathAddLineToPoint(strokePath, NULL, bounds.origin.x, bounds.origin.y+bounds.size.height/2);
	// Left border: bottom half
	CGPathAddLineToPoint(strokePath, NULL, bounds.origin.x, bounds.origin.y+bounds.size.height-kCornerRadius);
	// Bottom/Left curve
	CGPathAddArcToPoint(strokePath, NULL,
						bounds.origin.x, bounds.origin.y+bounds.size.height,
						bounds.origin.x+kCornerRadius, bounds.origin.y+bounds.size.height,
						kCornerRadius);
	// Bottom border
	CGPathAddLineToPoint(strokePath, NULL, bounds.origin.x+bounds.size.width-kCornerRadius, bounds.origin.y+bounds.size.height);
	// Bottom/Right curve
	CGPathAddArcToPoint(strokePath, NULL,
						bounds.origin.x+bounds.size.width, bounds.origin.y+bounds.size.height,
						bounds.origin.x+bounds.size.width, bounds.origin.y+bounds.size.height-kCornerRadius,
						kCornerRadius);
	// Right border: bottom half
	CGPathAddLineToPoint(strokePath, NULL, bounds.origin.x+bounds.size.width, bounds.origin.y+bounds.size.height/2);
	

	// Draw stroke path
	CGContextSetRGBStrokeColor(c, 184.0/255.0, 184.0/255.0, 184.0/255.0, 1.0);
	CGContextSetLineWidth(c, 1.0);
	
	CGContextAddPath(c, strokePath);
	CGContextDrawPath(c, kCGPathStroke);
	
	CGPathRelease(strokePath);
	CGPathRelease(boundaryPath);

	
	
	// Draw Up Arrow
	CGRect upArrowRect = CGRectMake(bounds.origin.x+bounds.size.width-12.0-kArrowWidth,
									bounds.origin.x+(bounds.size.height*0.25-kArrowHeight/2),
									kArrowWidth,
									kArrowHeight);
	CGMutablePathRef upArrowPath = CGPathCreateMutable();
	// Top point
	CGPathMoveToPoint(upArrowPath, NULL, upArrowRect.origin.x+upArrowRect.size.width/2, upArrowRect.origin.y);
	// Right side
	CGPathAddLineToPoint(upArrowPath, NULL, upArrowRect.origin.x+upArrowRect.size.width, upArrowRect.origin.y+upArrowRect.size.height);
	// Bottom side
	CGPathAddLineToPoint(upArrowPath, NULL, upArrowRect.origin.x, upArrowRect.origin.y+upArrowRect.size.height);
	CGPathCloseSubpath(upArrowPath);
	if (value >= maximumAllowedValue) {
		// "Disabled"
		CGContextSetRGBFillColor(c, 195.0/255.0, 199.0/255.0, 204.0/255.0, 1.0);
	}
	else {
		CGContextSetRGBFillColor(c, 105.0/255.0, 109.0/255.0, 114.0/255.0, 1.0);
	}
	CGContextAddPath(c, upArrowPath);
	
    CGContextSaveGState(c);
	CGContextSetShadowWithColor(c, CGSizeMake(0, 1), 1.0, [UIColor whiteColor].CGColor);
	
	CGContextDrawPath(c, kCGPathFill);
    CGContextRestoreGState(c);
	CGPathRelease(upArrowPath);
	
	

	
	
	// Draw Down Arrow
	CGRect downArrowRect = CGRectMake(bounds.origin.x+bounds.size.width-12.0-kArrowWidth,
									bounds.origin.x+(bounds.size.height*0.75-kArrowHeight/2),
									kArrowWidth,
									kArrowHeight);
	CGMutablePathRef downArrowPath = CGPathCreateMutable();
	// Bottom point
	CGPathMoveToPoint(downArrowPath, NULL, downArrowRect.origin.x+downArrowRect.size.width/2, downArrowRect.origin.y+downArrowRect.size.height);
	// Left side
	CGPathAddLineToPoint(downArrowPath, NULL, downArrowRect.origin.x, downArrowRect.origin.y);
	// Top side
	CGPathAddLineToPoint(downArrowPath, NULL, downArrowRect.origin.x+downArrowRect.size.width, downArrowRect.origin.y);
	CGPathCloseSubpath(downArrowPath);
	if (value <= minimumAllowedValue) {
		// "Disabled"
		CGContextSetRGBFillColor(c, 195.0/255.0, 199.0/255.0, 204.0/255.0, 1.0);
	}
	else {
		CGContextSetRGBFillColor(c, 105.0/255.0, 109.0/255.0, 114.0/255.0, 1.0);
	}
	CGContextAddPath(c, downArrowPath);
	
    CGContextSaveGState(c);
	CGContextSetShadowWithColor(c, CGSizeMake(0, 1), 1.0, [UIColor whiteColor].CGColor);
	
	CGContextDrawPath(c, kCGPathFill);
    CGContextRestoreGState(c);
	CGPathRelease(downArrowPath);
	
	// Draw text
	NSString *valueStr = [valueFormatter stringFromNumber:[NSNumber numberWithFloat:value]];
	
	[[UIColor colorWithRed:66.0/255.0 green:66.0/255.0 blue:66.0/255.0 alpha:1.0] set];
	UIFont *valueFont = [UIFont systemFontOfSize:36.0];
	UIFont *unitsFont = [UIFont boldSystemFontOfSize:14.0];
	
	CGSize valueSize = [valueStr sizeWithFont:valueFont];
	CGSize unitsSize = [units sizeWithFont:unitsFont];

	CGPoint valuePoint = CGPointMake(10.0, (bounds.size.height-valueSize.height)/2);
	CGPoint unitsPoint = CGPointMake(valuePoint.x+valueSize.width+3.0, (valuePoint.y+valueSize.height)-unitsSize.height-5.0);
	
	[valueStr drawAtPoint:valuePoint forWidth:valueSize.width withFont:valueFont minFontSize:valueFont.pointSize actualFontSize:NULL lineBreakMode:UILineBreakModeClip baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
	[units drawAtPoint:unitsPoint forWidth:unitsSize.width withFont:unitsFont minFontSize:unitsFont.pointSize actualFontSize:NULL lineBreakMode:UILineBreakModeClip baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint location = [touch locationInView:self];
	
	if (location.y < self.bounds.size.height/2) {
		_topHalfSelected = YES;
	}
	else {
		_topHalfSelected = NO;
	}

	// "Disable" press if at min or max
	if (_topHalfSelected && value >= maximumAllowedValue) {
		return NO;
	}
	else if (!_topHalfSelected && value <= minimumAllowedValue) {
		return NO;
	}
	
	_selected = YES;
	_touchNeedsDisplay = YES;
	[self setNeedsDisplay];
	
	return YES;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
	_selected = NO;
	[self setNeedsDisplay];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	if (self.touchInside && !_selected) {
		_selected = YES;
		[self setNeedsDisplay];
	}
	else if (!self.touchInside && _selected) {
		_selected = NO;
		[self setNeedsDisplay];
	}
	
	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	if (self.touchInside) {
		[self processTouchUp];
	}
	
	_selected = NO;
	[self setNeedsDisplay];
	
	if (_touchNeedsDisplay) {
		[self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:0.1];
	}
}

@end
