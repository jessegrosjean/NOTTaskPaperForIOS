//
//  UIColor_Additions.m
//  PlainText
//
//  Created by Jesse Grosjean on 5/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "InterfaceTint_Additions.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "NSObject_Additions.h"
#import "UIImage_Additions.h"

@implementation UIColor (InterfaceTintAdditions)

+ (void)load {
    if (self == [UIColor class]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[UIColor replaceClassMethod:@selector(selectionTintColor) withMethod:@selector(my_selectionTintColor)];
		[UIColor replaceClassMethod:@selector(textCaretColor) withMethod:@selector(my_textCaretColor)];
		//[UIColor replaceClassMethod:@selector(selectionCaretColor) withMethod:@selector(my_selectionCaretColor)];
		//[UIColor replaceClassMethod:@selector(selectionHighlightColor) withMethod:@selector(my_selectionHighlightColor)];
		//[NSClassFromString([@"UISelect" stringByAppendingString:@"ionGrabberDot"]) replaceInstanceMethod:@selector(drawRect:) withMethod:@selector(my_selectionGrabberDotDrawRect:)];
		//[NSClassFromString([@"UIAutocor" stringByAppendingString:@"rectTextView"]) replaceInstanceMethod:@selector(drawRect:) withMethod:@selector(autocorrectTextView_drawRect:)];
		[pool release];
    }
}

// As of iOS 5 these don't seem to be called anymore, so setting directly using UITextInputTraits private method.
+ (UIColor *)my_selectionTintColor {
	ApplicationViewController *appViewController = APP_VIEW_CONTROLLER;
	if ([appViewController tintCursor]) {
		return [[appViewController inkColor] colorWithAlphaComponent:0.2];
	} else {
		return [self my_selectionTintColor];
	}
}

// As of iOS 5 these don't seem to be called anymore, so setting directly using UITextInputTraits private method.
+ (UIColor *)my_textCaretColor {
	ApplicationViewController *appViewController = APP_VIEW_CONTROLLER;
	if ([appViewController tintCursor]) {
		return [appViewController inkColor];
	} else {
		return [self my_textCaretColor];
	}
}

/*
+ (UIColor *)my_selectionCaretColor {
	ApplicationViewController *appViewController = APP_VIEW_CONTROLLER;
	if ([appViewController tintCursor]) {
		return [appViewController inkColor];
	} else {
		return [self my_selectionCaretColor];
	}
}

+ (UIColor *)my_selectionHighlightColor {
	ApplicationViewController *appViewController = APP_VIEW_CONTROLLER;
	if ([appViewController tintCursor]) {
		return [appViewController inkColor];
	} else {
		return [self my_selectionHighlightColor];
	}
}*/

@end

@implementation NSObject (InterfaceTintAdditions)

- (void)my_selectionGrabberDotDrawRect:(CGRect)rect {
	ApplicationViewController *appViewController = APP_VIEW_CONTROLLER;
	
	if ([appViewController tintCursor]) {
		UIView *view = (id) self;
		UIGraphicsBeginImageContext(view.bounds.size);
		[self my_selectionGrabberDotDrawRect:rect];
		UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		viewImage = [UIImage colorizeImagePixels:viewImage color:[APP_VIEW_CONTROLLER inkColor]];
		[viewImage drawInRect:view.bounds];
	} else {
		[self my_selectionGrabberDotDrawRect:rect];
	}
}

- (void)autocorrectTextView_drawRect:(CGRect)rect {
	ApplicationViewController *appViewController = APP_VIEW_CONTROLLER;
	if ([appViewController tintCursor]) {
		UIView *view = (id) self;
		UIGraphicsBeginImageContext(view.bounds.size);
		[self autocorrectTextView_drawRect:rect];
		UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		viewImage = [UIImage colorizeImagePixels:viewImage color:[APP_VIEW_CONTROLLER inkColor]];
		
		
		[viewImage drawInRect:view.bounds];
	} else {
		[self autocorrectTextView_drawRect:rect];
	}
}

/*
 
 Code for tinting color of UIMenuController popup menu... but doesn't look so good.
 
 //[NSClassFromString(@"UICalloutBarOverlay") replaceInstanceMethod:@selector(drawRect:) withMethod:@selector(my_calloutBarDrawRect:)];
 //[NSClassFromString(@"UICalloutBarButton") replaceInstanceMethod:@selector(setImage:forState:) withMethod:@selector(my_setImage:forState:)];
 //[NSClassFromString(@"UICalloutBarButton") replaceInstanceMethod:@selector(setBackgroundImage:forState:) withMethod:@selector(my_setBackgroundImage:forState:)];
 //[NSClassFromString(@"UICalloutBarButton") replaceInstanceMethod:@selector(setTitleColor:forState:) withMethod:@selector(my_setTitleColor:forState:)];
 //[NSClassFromString(@"UICalloutBarButton") replaceInstanceMethod:@selector(willMoveToWindow:) withMethod:@selector(my_willMoveToWindow:)];

- (void)my_calloutBarDrawRect:(CGRect)rect {
	ApplicationViewController *appViewController = APP_VIEW_CONTROLLER;
	if ([appViewController tintTextSelection]) {
		UIView *view = (id) self;
		UIGraphicsBeginImageContext(view.bounds.size);
		[self my_calloutBarDrawRect:rect];
		UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		viewImage = [UIImage colorizeImagePixels:viewImage color:[APP_VIEW_CONTROLLER inkColor]];
		
		for (UIView *each in view.subviews) {
			each.hidden = YES;
		}
		
		[viewImage drawInRect:view.bounds];
	} else {
		[self my_calloutBarDrawRect:rect];
	}
}

- (void)my_setImage:(UIImage *)image forState:(UIControlState)state {
	UIImage *i = [UIImage colorizeImagePixels:image color:[APP_VIEW_CONTROLLER inkColor]];
	[self my_setImage:i forState:state];
	UIButton *b = (id) self;
	[b setTitleColor:nil forState:state];
	[b setTitleColor:nil forState:UIControlStateNormal];
}

- (void)my_setBackgroundImage:(UIImage *)image forState:(UIControlState)state {
	UIImage *i = [UIImage colorizeImagePixels:image color:[APP_VIEW_CONTROLLER inkColor]];
	[self my_setBackgroundImage:i forState:state];
	UIButton *b = (id) self;
	[b setTitleColor:nil forState:state];
	[b setTitleColor:nil forState:UIControlStateNormal];
}

- (void)my_setTitleColor:(UIColor *)color forState:(UIControlState)state {
	[self my_setTitleColor:[APP_VIEW_CONTROLLER inkColor] forState:state];
}*/

@end