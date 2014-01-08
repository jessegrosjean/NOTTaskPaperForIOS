//
//  ApplicationViewController.m
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "ApplicationViewController.h"
#import "NSFileManager_Additions.h"
#import "SettingsViewController.h"
#import "ApplicationController.h"
#import "BrowserViewController.h"
#import "FolderViewController.h"
#import "PathViewController.h"
#import "ItemViewController.h"
#import "UIView_Additions.h"
#import "ApplicationView.h"
#import "PathController.h"
#import "BrowserView.h"
#import "SearchView.h"
#import "Button.h"
#import "UIImage_Additions.h"

#import "SearchViewController.h"


#ifdef TASKPAPER
#import "TaskViewController.h"
#else
#import "FileViewController.h"
#endif

void CGContextAddRoundedRect(CGContextRef c, CGRect rect, int corner_radius) {  
	CGFloat x_left = rect.origin.x;  
	CGFloat x_left_center = rect.origin.x + corner_radius;  
	CGFloat x_right_center = rect.origin.x + rect.size.width - corner_radius;  
	CGFloat x_right = rect.origin.x + rect.size.width;  
	CGFloat y_top = rect.origin.y;  
	CGFloat y_top_center = rect.origin.y + corner_radius;  
	CGFloat y_bottom_center = rect.origin.y + rect.size.height - corner_radius;  
	CGFloat y_bottom = rect.origin.y + rect.size.height;  
	CGContextBeginPath(c);  
	CGContextMoveToPoint(c, x_left, y_top_center);  
	CGContextAddArcToPoint(c, x_left, y_top, x_left_center, y_top, corner_radius);  
	CGContextAddLineToPoint(c, x_right_center, y_top);  
	CGContextAddArcToPoint(c, x_right, y_top, x_right, y_top_center, corner_radius);  
	CGContextAddLineToPoint(c, x_right, y_bottom_center);  
	CGContextAddArcToPoint(c, x_right, y_bottom, x_right_center, y_bottom, corner_radius);  
	CGContextAddLineToPoint(c, x_left_center, y_bottom);  
	CGContextAddArcToPoint(c, x_left, y_bottom, x_left, y_bottom_center, corner_radius);  
	CGContextAddLineToPoint(c, x_left, y_top_center);  
	CGContextClosePath(c);
} 

const CGFloat kMyDrawingFunctionWidth = 44.0;
const CGFloat kMyDrawingFunctionHeight = 44.0;

void DrawFadeFunction(CGContextRef context, CGRect bounds, CGColorRef background, CGFloat angle) {
	CGRect imageBounds = CGRectMake(0.0, 0.0, kMyDrawingFunctionWidth, kMyDrawingFunctionHeight);
	CGFloat alignStroke;
	CGFloat resolution;
	CGMutablePathRef path;
	CGRect drawRect;
	CGGradientRef gradient;
	CFMutableArrayRef colors;
	CGColorRef color;
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGPoint point;
	CGPoint point2;
	CGAffineTransform transform;
	CGMutablePathRef tempPath;
	CGRect pathBounds;
	CGFloat locations[2];
	
	transform = CGContextGetUserSpaceToDeviceSpaceTransform(context);
	resolution = sqrt(fabs(transform.a * transform.d - transform.b * transform.c)) * 0.5 * (bounds.size.width / imageBounds.size.width + bounds.size.height / imageBounds.size.height);
	
	CGContextSaveGState(context);
	CGContextClipToRect(context, bounds);
	CGContextTranslateCTM(context, bounds.origin.x, bounds.origin.y);
	CGContextScaleCTM(context, (bounds.size.width / imageBounds.size.width), (bounds.size.height / imageBounds.size.height));
	
	// Layer 1
	
	alignStroke = 0.0;
	path = CGPathCreateMutable();
	drawRect = CGRectMake(0.0, 0.0, 44.0, 44.0);
	drawRect.origin.x = (round(resolution * drawRect.origin.x + alignStroke) - alignStroke) / resolution;
	drawRect.origin.y = (round(resolution * drawRect.origin.y + alignStroke) - alignStroke) / resolution;
	drawRect.size.width = round(resolution * drawRect.size.width) / resolution;
	drawRect.size.height = round(resolution * drawRect.size.height) / resolution;
	CGPathAddRect(path, NULL, drawRect);
	colors = CFArrayCreateMutable(NULL, 2, &kCFTypeArrayCallBacks);
	//CGFloat colorComponents[4] = {1.0, 1.0, 1.0, 1.0};
	//color = CGColorCreate(space, colorComponents);
	
	CFArrayAppendValue(colors, background);
	
	const CGFloat *backgroundColorComponents = CGColorGetComponents(background);
	//CGColorRelease(color);
	locations[0] = 0.1;
	CGFloat colorComponents2[4] = {backgroundColorComponents[0], backgroundColorComponents[1], backgroundColorComponents[2], 0.0};
	color = CGColorCreate(space, colorComponents2);
	CFArrayAppendValue(colors, color);
	CGColorRelease(color);
	locations[1] = 1.0;
	gradient = CGGradientCreateWithColors(space, colors, locations);
	CGContextAddPath(context, path);
	CGContextSaveGState(context);
	CGContextEOClip(context);
	
	transform = CGAffineTransformMakeRotation(angle);
	
	tempPath = CGPathCreateMutable();
	CGPathAddPath(tempPath, &transform, path);
	pathBounds = CGPathGetBoundingBox(tempPath);
	point = pathBounds.origin;
	point2 = CGPointMake(CGRectGetMaxX(pathBounds), CGRectGetMinY(pathBounds));
	transform = CGAffineTransformInvert(transform);
	point = CGPointApplyAffineTransform(point, transform);
	point2 = CGPointApplyAffineTransform(point2, transform);
	CGPathRelease(tempPath);
	CGContextDrawLinearGradient(context, gradient, point, point2, (kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation));
	CGContextRestoreGState(context);
	CFRelease(colors);
	CGGradientRelease(gradient);
	CGPathRelease(path);
	
	CGContextRestoreGState(context);
	CGColorSpaceRelease(space);
}

@implementation ApplicationViewController

+ (void)initialize {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             // Generic Defaults
															 [NSNumber numberWithBool:YES], AllCapsHeadingsDefaultsKey,
															 [NSNumber numberWithBool:NO], DetectLinksDefaultsKey,
															 [NSNumber numberWithBool:YES], DraggableScrollerDefaultsKey,
															 [NSNumber numberWithInteger:UITextAutocorrectionTypeDefault], AutocorrectionTypeDefaultsKey,
															 [NSNumber numberWithFloat:1.0], SecondaryBrightnessDefaultsKey,
                                                             [NSNumber numberWithInt:18], FontSizeDefaultsKey,
															 [NSKeyedArchiver archivedDataWithRootObject:[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0]], InkColorDefaultsKey,
															 [NSKeyedArchiver archivedDataWithRootObject:[UIColor colorWithRed:252.0/255.0 green:251.0/255.0 blue:250.0/255.0 alpha:1.0]], PaperColorDefaultsKey,
															 [NSNumber numberWithBool:YES], ShowStatusBarDefaultsKey,
                                                             [NSNumber numberWithBool:YES], ScrollsHeadingsDefaultsKey,
															 [NSNumber numberWithBool:NO], ShowFileExtensionsDefaultsKey,
															 [NSNumber numberWithInteger:SortByName], SortByDefaultsKey,
                                                             [NSNumber numberWithBool:NO], TextRightToLeftDefaultsKey,
                                                             
#ifdef WRITEROOM                                             // WriteRoom Specific
															 [NSKeyedArchiver archivedDataWithRootObject:[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0]], InkColorDefaultsKey,
															 [NSKeyedArchiver archivedDataWithRootObject:[UIColor colorWithRed:252.0/255.0 green:251.0/255.0 blue:250.0/255.0 alpha:1.0]], PaperColorDefaultsKey,
															 [NSNumber numberWithBool:NO], ShowStatusBarDefaultsKey, // Also TaskPaper
                                                             @"AmericanTypewriter", FontNameDefaultsKey,
                                                             [NSNumber numberWithInt:20], FontSizeDefaultsKey,
                                                             [NSNumber numberWithBool:IS_IPAD], ExtendedKeyboardDefaultsKey,
															 @"-:;()'\"", ExtendedKeyboardKeysDefaultsKey,

#elif TASKPAPER                                              // TaskPaper Specific
                                                             @"Helvetica", FontNameDefaultsKey,   
                                                             [NSNumber numberWithInt:18], FontSizeDefaultsKey,
                                                             [NSNumber numberWithBool:IS_IPAD], ExtendedKeyboardDefaultsKey,
                                                             @":-@()=\"", ExtendedKeyboardKeysDefaultsKey,
                                                             [NSNumber numberWithBool:NO], ScrollsHeadingsDefaultsKey,
                                                             [NSNumber numberWithBool:NO], ShowIconBadgeNumberDefaultsKey,

#else                                                        // PlainText Specific
                                                             @"Georgia", FontNameDefaultsKey,
                                                             [NSNumber numberWithInt:18], FontSizeDefaultsKey,
                                                             [NSNumber numberWithBool:YES], AllowFlurryDefaultsKey,
#endif
															 nil]];
	if (IS_IPAD) {
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.3], LineHeightMultipleDefaultsKey, nil]];
	} else {
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.1], LineHeightMultipleDefaultsKey, nil]];
	}
}

- (id)init {
	self = [super init];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	primaryBrowser = [[BrowserViewController alloc] init];
	inkColorByPercentDictionary = [[NSMutableDictionary alloc] init];
	tintCursor = [defaults boolForKey:TintCursorDefaultsKey];
	showFileExtensions = [defaults boolForKey:ShowFileExtensionsDefaultsKey];
	scrollsHeadings = [defaults boolForKey:ScrollsHeadingsDefaultsKey];
#ifdef TASKPAPER
    scrollsHeadings = NO;
    iconBadgeNumberEnabled = [defaults boolForKey:ShowIconBadgeNumberDefaultsKey];
    if (iconBadgeNumberEnabled == NO) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
#endif
	allCapsHeadings = [defaults boolForKey:AllCapsHeadingsDefaultsKey];
	detectLinks = [defaults boolForKey:DetectLinksDefaultsKey];
	showStatusBar = [defaults boolForKey:ShowStatusBarDefaultsKey];
	textExpanderEnabled = [defaults boolForKey:TextExpanderEnabledDefaultsKey];
	autocorrectionType = [defaults integerForKey:AutocorrectionTypeDefaultsKey];
	sortBy = [defaults integerForKey:SortByDefaultsKey];
	sortFolders = [defaults integerForKey:SortFoldersDefaultsKey];
	
	secondaryBrightness = [defaults floatForKey:SecondaryBrightnessDefaultsKey];
    textRightToLeft = [defaults boolForKey:TextRightToLeftDefaultsKey];
	
	if (IS_IPAD) {
		secondaryBrowser = [[BrowserViewController alloc] init];
	}
    	
	return self;
}

- (NSUndoManager *)undoManager {
    if ([primaryBrowser.currentItemViewController isFileViewController]) {
        return [primaryBrowser.currentItemViewController undoManager];
    } else if ([secondaryBrowser.currentItemViewController isFileViewController]) {
        return [secondaryBrowser.currentItemViewController undoManager];        
    }
    return  nil;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[inkColorByPercentDictionary release];
	[primaryBrowser release];
	[secondaryBrowser release];
	[super dealloc];
}

- (UIFont *)font {
	if (!font) {
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		font = [[UIFont fontWithName:[userDefaults stringForKey:FontNameDefaultsKey] size:[userDefaults floatForKey:FontSizeDefaultsKey]] retain];
		if (!font) {
			font = [[UIFont systemFontOfSize:[userDefaults floatForKey:FontSizeDefaultsKey]] retain];
		}
	}
	return font;
}

- (UIFont *)projectFont {
    NSString *fontName = [self font].fontName;
    
    NSUInteger projectFontSize = self.font.pointSize + 2;

    if (!projectFont) {
        projectFont = [UIFont fontWithName:[fontName stringByAppendingString:@"-Bold"] size:projectFontSize];
        if (projectFont) {
            [projectFont retain];
        }
    }
    
    if (!projectFont) {
        projectFont = [UIFont fontWithName:[fontName stringByAppendingString:@"-BoldMT"] size:projectFontSize];
        if (projectFont) {
            [projectFont retain];
        }
    }
    
    if (!projectFont) {
        projectFont = [UIFont fontWithName:[fontName stringByAppendingString:@"Bold"] size:projectFontSize];
        if (projectFont) {
            [projectFont retain];
        }
    }
    
    if (!projectFont) {
        projectFont = [UIFont fontWithName:[fontName stringByAppendingString:@"BoldMT"] size:projectFontSize];
        if (projectFont) {
            [projectFont retain];
        }
    }
    
    if (!projectFont) {
        NSRange rangeOfHyphen = [fontName rangeOfString:@"-"];
        if (rangeOfHyphen.location != NSNotFound) {
            NSString *familyName = [fontName substringToIndex:rangeOfHyphen.location];
            if (!projectFont) {
                projectFont = [UIFont fontWithName:[familyName stringByAppendingString:@"-Bold"] size:projectFontSize];
            }
            
            if (!projectFont) {
                projectFont = [UIFont fontWithName:[familyName stringByAppendingString:@"-BoldMT"] size:projectFontSize];
            }
            
            if (!projectFont) {
                projectFont = [UIFont fontWithName:[familyName stringByAppendingString:@"Bold"] size:projectFontSize];
            }
            
            if (!projectFont) {
                projectFont = [UIFont fontWithName:[familyName stringByAppendingString:@"BoldMT"] size:projectFontSize];
            }
            
            if (projectFont) {
                [projectFont retain];
            }
        }
    }

    if (!projectFont) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        projectFont = [[UIFont fontWithName:[userDefaults stringForKey:FontNameDefaultsKey] size:projectFontSize] retain];
    }
        
    return projectFont;
}

- (UIFont *)menuFont {
	if (!menuFont) {
		menuFont = [[UIFont fontWithName:@"Georgia-Italic" size:18] retain];
		if (!menuFont) {
			menuFont = [[UIFont boldSystemFontOfSize:15] retain];
		}
	}
	return menuFont;
}

- (CGFloat)lineHeightMultiple {
	if (lineHeightMultiple == 0) {
		lineHeightMultiple = [[NSUserDefaults standardUserDefaults] floatForKey:LineHeightMultipleDefaultsKey];
	}
	return lineHeightMultiple;
}

- (CGFloat)leading {
	CGFloat multiple = [self lineHeightMultiple];
	CGFloat leading = [[self font] leading];
	
	if (multiple > 1.0 && !IS_IPAD && UIInterfaceOrientationIsLandscape([APP_VIEW_CONTROLLER interfaceOrientation])) {
		return leading;
	} else {
		return leading * multiple;
	}
}

- (CGFloat)unadjustedLeading {
	return [[self font] leading] * [self lineHeightMultiple];
}

- (UIColor *)inkColor {
	if (!inkColor) {
		inkColor = [[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:InkColorDefaultsKey]] retain];
		if (!inkColor) {
			inkColor = [[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0] retain];
		}
	}
	return inkColor;
}

- (UIColor *)paperColor {
	if (!paperColor) {
		paperColor = [[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:PaperColorDefaultsKey]] retain];
		if (!paperColor) {
			paperColor = [[UIColor colorWithRed:252.0/255.0 green:251.0/255.0 blue:250.0/255.0 alpha:1.0] retain];
		}
	}
	return paperColor;
}

- (UIColor *)highlightColor {
	return [UIColor redColor];
}

- (UIImage *)gradientLine {
    if (!gradientLine) {
        gradientLine = [[UIImage colorizeImage:[UIImage imageNamed:@"gradientline.png"] color:[APP_VIEW_CONTROLLER inkColorByPercent:0.50]] retain];
    }
    return gradientLine;
}

- (UIImage *)bullet {
    if (!bullet) {
        bullet = [[UIImage colorizeImage:[UIImage imageNamed:@"handle.png"] color:[APP_VIEW_CONTROLLER inkColor]] retain];
    }
    return bullet;
}

- (UIKeyboardAppearance)keyboardAppearance {
	return UIKeyboardAppearanceDefault;
}

- (UIColor *)inkColorByPercent:(CGFloat)percent {
	percent *= secondaryBrightness;
	
	if (percent > 1) {
		percent = 1;
	} else if (percent < 0) {
		percent = 0;
	}
	
	NSNumber *number = [NSNumber numberWithFloat:percent];
	UIColor *color = [inkColorByPercentDictionary objectForKey:number];
	if (!color) {
		const CGFloat *a = CGColorGetComponents([[self paperColor] CGColor]);
		const CGFloat *b = CGColorGetComponents([[self inkColor] CGColor]);
		color = [UIColor colorWithRed:a[0] + ((b[0] - a[0]) * percent)
								green:a[1] + ((b[1] - a[1]) * percent)
								 blue:a[2] + ((b[2] - a[2]) * percent)
								alpha:1.0];
		[inkColorByPercentDictionary setObject:color forKey:number];
	}
	return color;
}

- (void)clearDefaultsCaches:(BOOL)andRefreshResponders {
	[inkColorByPercentDictionary removeAllObjects];
	[font release];
	font = nil;
    [projectFont release];
    projectFont = nil;
	[inkColor release];
	inkColor = nil;
	[paperColor release];
	paperColor = nil;
    [gradientLine release];
    gradientLine = nil;
    [bullet release];
    bullet = nil;
	lineHeightMultiple = 0;
	tintCursor = [[NSUserDefaults standardUserDefaults] boolForKey:TintCursorDefaultsKey];
	secondaryBrightness = [[NSUserDefaults standardUserDefaults] floatForKey:SecondaryBrightnessDefaultsKey];
    
	if (andRefreshResponders) {
		for (UIWindow *eachWindow in [[UIApplication sharedApplication] windows]) {
			[eachWindow refreshSelfAndSubviewsFromDefaults];
		}
		
		if (!self.view.window) {
			[self.view refreshSelfAndSubviewsFromDefaults];
		}
	}
}

- (BOOL)lockOrientation {
	if (IS_IPAD) {
		return NO;
	}
    
    //return !IS_IPAD && ([[[UIDevice currentDevice] systemVersion] isEqualToString:@"3.0"] || [[NSUserDefaults standardUserDefaults] boolForKey:LockOrientationDefaultsKey]);

	return [[NSUserDefaults standardUserDefaults] boolForKey:LockOrientationDefaultsKey];
}

- (UIInterfaceOrientation)lockedOrientation {
	return [[NSUserDefaults standardUserDefaults] integerForKey:LockedOrientationDefaultsKey];
}

@synthesize tintCursor;

- (BOOL)tintCursor {
	return tintCursor && self.modalViewController == nil;
}

- (void)setTintCursor:(BOOL)aBool {
	tintCursor = aBool;
	[[NSUserDefaults standardUserDefaults] setBool:aBool forKey:TintCursorDefaultsKey];
	[self clearDefaultsCaches:YES];
}

- (UIImage *)selectionDragDotImage {
	static UIImage *original = nil;
	
	if (!original) {
		UITextView *tv = [[[UITextView alloc] init] autorelease];
		original = [[tv performSelector:@selector(selectionDragDotImage)] retain];
	}
	
	if (tintCursor) {
		return [UIImage colorizeImagePixels:original color:[self inkColor]];
	}
	
	return original;
}

- (UIColor *)selectionHighlightColor {
	if (tintCursor) {
		return [[self inkColor] colorWithAlphaComponent:0.2];
	}
	return [UIColor colorWithRed:0 green:0.33 blue:0.65 alpha:0.2];
}

- (UIColor *)selectionBarColor {
	if (tintCursor) {
		return [[self inkColor] colorWithAlphaComponent:0.5];
	}
	return [UIColor colorWithRed:0.26 green:0.42 blue:0.95 alpha:1];
}

- (UIColor *)insertionPointColor {
	if (tintCursor) {
		return [self inkColor];
	}
	return [UIColor colorWithRed:0.26 green:0.42 blue:0.95 alpha:1];
}

- (BOOL)showFileExtensions {
	return showFileExtensions;
}

- (void)setShowFileExtensions:(BOOL)aBool {
	showFileExtensions = aBool;
	[[NSUserDefaults standardUserDefaults] setBool:aBool forKey:ShowFileExtensionsDefaultsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ShowFileExtensionsChangedNotification object:self];
}

- (BOOL)scrollsHeadings {
	return scrollsHeadings;
}

- (void)setScrollsHeadings:(BOOL)aBool {
	scrollsHeadings = aBool;
	[[NSUserDefaults standardUserDefaults] setBool:aBool forKey:ScrollsHeadingsDefaultsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ScrollsHeadingsChangedNotification object:self];
}

- (BOOL)iconBadgeNumberEnabled {
    return iconBadgeNumberEnabled;
}

- (void)setIconBadgeNumberEnabled:(BOOL)aBool {
    iconBadgeNumberEnabled = aBool;
	[[NSUserDefaults standardUserDefaults] setBool:aBool forKey:ShowIconBadgeNumberDefaultsKey];
    if (aBool == NO) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:ShowIconBadgeNumberChangedNotification object:self];
    
}

- (BOOL)allCapsHeadings {
	return allCapsHeadings;
}

- (void)setAllCapsHeadings:(BOOL)aBool {
	allCapsHeadings = aBool;
	[[NSUserDefaults standardUserDefaults] setBool:aBool forKey:ShowIconBadgeNumberDefaultsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:AllCapsHeadingsChangedNotification object:self];
}

- (BOOL)detectLinks {
	return detectLinks;
}

- (void)setDetectLinks:(BOOL)aBool {
	detectLinks = aBool;
	[[NSUserDefaults standardUserDefaults] setBool:aBool forKey:DetectLinksDefaultsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:DetectLinksChangedNotification object:self];
}

- (BOOL)textRightToLeft {
    return textRightToLeft;
}

- (void)setTextRightToLeft:(BOOL)aTextRightToLeft {
    textRightToLeft = aTextRightToLeft;
    [[NSUserDefaults standardUserDefaults] setBool:aTextRightToLeft forKey:TextRightToLeftDefaultsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:TextRightToLeftChangedNotification object:self];
}

- (BOOL)showStatusBar {
	return showStatusBar;
}

- (void)setShowStatusBar:(BOOL)aBool {
	showStatusBar = aBool;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[[NSUserDefaults standardUserDefaults] setBool:aBool forKey:ShowStatusBarDefaultsKey];
	[[UIApplication sharedApplication] setStatusBarHidden:!aBool];
	//if ([[UIApplication sharedApplication] respondsToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
	//	[[UIApplication sharedApplication] setStatusBarHidden:!aBool withAnimation:UIStatusBarAnimationNone];
	//}
	//[[UIApplication sharedApplication] setStatusBarHidden:!aBool withAnimation:UIStatusBarAnimationFade];
	[self.view setNeedsLayout];
	[self.view layoutIfNeeded];
	[UIView commitAnimations];
}

- (BOOL)textExpanderEnabled {
	return textExpanderEnabled;
}

- (void)setTextExpanderEnabled:(BOOL)enabled {
	textExpanderEnabled = enabled;
	[[NSUserDefaults standardUserDefaults] setBool:enabled forKey:TextExpanderEnabledDefaultsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:TextExpanderEnabledChangedNotification object:self];
}

- (UITextAutocorrectionType)autocorrectionType {
	return autocorrectionType;
}

- (void)setAutocorrectionType:(UITextAutocorrectionType)aType {
	autocorrectionType = aType;
	[[NSUserDefaults standardUserDefaults] setInteger:aType forKey:AutocorrectionTypeDefaultsKey];
	[self clearDefaultsCaches:YES];
}

@synthesize animatingKeyboardOrDocumentFocusMode;
@synthesize isHardwareKeyboard;
@synthesize isClosingKeyboard;
@synthesize keyboardHeight;
@synthesize adsHeight;

- (SortBy)sortBy {
	return sortBy;
}

- (void)setSortBy:(SortBy)aSortBy {
	sortBy = aSortBy;
	[[NSUserDefaults standardUserDefaults] setInteger:aSortBy forKey:SortByDefaultsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SortByChangedNotification object:self];
}

- (SortFolders)sortFolders {
	return sortFolders;
	//return [[NSUserDefaults standardUserDefaults] integerForKey:SortFoldersDefaultsKey];
}

- (void)setSortFolders:(SortFolders)aSortFolders {
	sortFolders = aSortFolders;
	[[NSUserDefaults standardUserDefaults] setInteger:aSortFolders forKey:SortFoldersDefaultsKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SortFoldersChangedNotification object:self];
}

- (NSString *)displayNameForPath:(NSString *)aPath isDirectory:(BOOL)isDirectory {
	NSString *displayName = [aPath lastPathComponent];

	if (!isDirectory && !self.showFileExtensions) {
		displayName = [displayName stringByDeletingPathExtension];
	}
	
	if ([aPath isEqualToString:[[NSFileManager defaultManager] readOnlyInboxDirectory]]) {
		displayName = [displayName stringByAppendingFormat:@" %@", NSLocalizedString(@" (Read only)", nil)];
	}
	
	return displayName;
}

- (FolderViewController *)visibleFolderContentsViewController {
	FolderViewController *visibleFolderContentsViewController = (id) primaryBrowser.currentItemViewController;
	if ([visibleFolderContentsViewController isKindOfClass:[FolderViewController class]]) {
		return visibleFolderContentsViewController;
	} else {
		return nil;
	}
}

- (ApplicationView *)applicationView {
	return (id) self.view;
}

- (void)loadView {
	CGRect frame = [[UIScreen mainScreen] bounds];
	
	ApplicationView *applicationView = [[[ApplicationView alloc] initWithFrame:frame] autorelease];
	
	applicationView.autoresizingMask = 18;
	
	primaryBrowser.browserView.isPrimaryBrowser = YES;
	
	[primaryBrowser viewWillAppear:NO];
	
	applicationView.primaryView = primaryBrowser.browserView;

	if (IS_IPAD) {
		//primaryBrowser.browserView.contentInnerInsets = UIEdgeInsetsMake(0, 0, 0, 0);
		//secondaryBrowser.browserView.contentInnerInsets = UIEdgeInsetsMake(0, 10, 0, 10);		
		[secondaryBrowser viewWillAppear:NO];
		applicationView.secondaryView = secondaryBrowser.browserView;
	} else {
		//primaryBrowser.browserView.contentInnerInsets = UIEdgeInsetsMake(0, 10, 0, 10);
	}
	
	self.view = applicationView;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}


- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([APP_VIEW_CONTROLLER lockOrientation]) {
		return interfaceOrientation == [APP_VIEW_CONTROLLER lockedOrientation];
	} else {
		return YES;
	}
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([APP_VIEW_CONTROLLER lockOrientation]) {
        if ([APP_VIEW_CONTROLLER lockedOrientation] == UIDeviceOrientationPortrait)
            return UIInterfaceOrientationMaskPortrait;
        else if ([APP_VIEW_CONTROLLER lockedOrientation] == UIInterfaceOrientationPortraitUpsideDown)
            return UIInterfaceOrientationMaskPortraitUpsideDown;
        else if ([APP_VIEW_CONTROLLER lockedOrientation] == UIInterfaceOrientationLandscapeLeft)
            return UIInterfaceOrientationMaskLandscapeLeft;
        else if ([APP_VIEW_CONTROLLER lockedOrientation] == UIInterfaceOrientationLandscapeRight)
            return UIInterfaceOrientationMaskLandscapeRight;
        else
            return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskAll;
}

- (void)search:(NSString *)searchText {
    [primaryBrowser.currentItemViewController.searchViewController updateSearchText:searchText];
    [primaryBrowser.currentItemViewController.searchViewController  notifiySearchFieldChangedAfterDelay:[NSNumber numberWithFloat:0.0000001]];
}

- (IBAction)newFile:(id)sender {
	self.applicationView.ignoreNextkeyboardHideShowIfKeyboardIsShowing = YES;
	
	NSError *error;
	NSString *path = [PATH_CONTROLLER createItemAtPath:nil folder:NO error:&error];
	if (path) {
		[self openItem:path editingPath:YES allowAutosync:NO animated:YES];
	} else {
		[self presentError:error];
	}
}


//- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
//    if ([primaryBrowser.currentItemViewController respondsToSelector:@selector(canPerformAction:withSender:)]) {
//        return [primaryBrowser.currentItemViewController canPerformAction:action withSender:sender];
//    }
//    
//    if ([secondaryBrowser.currentItemViewController respondsToSelector:@selector(canPerformAction:withSender:)]) {
//        return [secondaryBrowser.currentItemViewController canPerformAction:action withSender:sender];
//    }
//
//    return [super canPerformAction:action withSender:sender];
//}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	ApplicationView *applicationView = (id) self.view;
	[applicationView setNeedsLayout];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:ApplicationViewWillRotateNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:toInterfaceOrientation] forKey:ToOrientation]]];

    if ([primaryBrowser.currentItemViewController respondsToSelector:@selector(willRotateToInterfaceOrientation:duration:)]) {
        [primaryBrowser.currentItemViewController performSelector:@selector(willRotateToInterfaceOrientation:duration:) withObject:[NSNumber numberWithInt:toInterfaceOrientation] withObject:[NSNumber numberWithDouble:duration]];
    }
    
    if ([secondaryBrowser.currentItemViewController respondsToSelector:@selector(willRotateToInterfaceOrientation:duration:)]) {
        [secondaryBrowser.currentItemViewController performSelector:@selector(willRotateToInterfaceOrientation:duration:) withObject:[NSNumber numberWithInt:toInterfaceOrientation] withObject:[NSNumber numberWithDouble:duration]];
    }

}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if ([primaryBrowser.currentItemViewController respondsToSelector:@selector(didRotateFromInterfaceOrientation:)]) {
        [primaryBrowser.currentItemViewController performSelector:@selector(didRotateFromInterfaceOrientation:) withObject:[NSNumber numberWithInt:fromInterfaceOrientation]];
    }
    
    if ([secondaryBrowser.currentItemViewController respondsToSelector:@selector(didRotateFromInterfaceOrientation:)]) {
        [secondaryBrowser.currentItemViewController performSelector:@selector(didRotateFromInterfaceOrientation:) withObject:[NSNumber numberWithInt:fromInterfaceOrientation]];
    }
}

- (IBAction)newFolder:(id)sender {
	self.applicationView.ignoreNextkeyboardHideShowIfKeyboardIsShowing = YES;
	
	NSError *error;
	NSString *path = [PATH_CONTROLLER createItemAtPath:nil folder:YES error:&error];
	if (path) {
		[self openItem:path editingPath:YES allowAutosync:NO animated:YES];
	} else {
		[self presentError:error];
	}
}

- (IBAction)showSettings:(id)sender {
	[self hideKeyboard];
    [self resignFirstResponder];
	[self presentModalViewController:[SettingsViewController viewControllerForDisplayingSettings] animated:YES];
}

- (void)browser:(BrowserViewController *)browserController pushItemsForPath:(NSString *)aPath {	
}

- (BOOL)openItem:(NSString *)aPath animated:(BOOL)animated {
	return [self openItem:aPath editingPath:NO allowAutosync:YES animated:animated];
}

- (BOOL)openItem:(NSString *)aPath editingPath:(BOOL)editingPath allowAutosync:(BOOL)allowAutosync animated:(BOOL)animated {
	if (disableOpenItems) {
		return NO;
	}
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDirectory;
	BOOL fileExists = [fileManager fileExistsAtPath:aPath isDirectory:&isDirectory];
	PathController *pathController = PATH_CONTROLLER;

	if (fileExists) {
		if (isDirectory) {
			NSString *newPath = aPath;
			NSString *existingPath = [primaryBrowser currentItemViewController].path;
			if (!existingPath) existingPath = [[fileManager documentDirectory] stringByDeletingLastPathComponent];
			NSString *commonPrefix = [newPath commonPrefixWithString:existingPath options:0];
			NSString *pathToPop = [existingPath substringFromIndex:[commonPrefix length]];
			NSArray *pathComponentsToPop = [pathToPop pathComponents];
			NSString *pathToPush = [newPath substringFromIndex:[commonPrefix length]];
			NSArray *pathComponentsToPush = [pathToPush pathComponents];
            
            disableOpenItems = YES;
			[primaryBrowser beginUpdates];
			
			for (NSString *each in pathComponentsToPop) {
				if (![each isEqualToString:@"/"]) {
					[primaryBrowser pop:animated];
				}
			}
			
			for (NSString *each in pathComponentsToPush) {
				if (![each isEqualToString:@"/"]) {
					commonPrefix = [commonPrefix stringByAppendingPathComponent:each];
					[primaryBrowser push:[[[FolderViewController alloc] initWithPath:commonPrefix] autorelease] animated:animated];
				}
			}
			
			[primaryBrowser endUpdates:editingPath];
			disableOpenItems = NO;
			
			PathController *pathController = PATH_CONTROLLER;
			if (allowAutosync && pathController.syncAutomatically) {
				if (animated) {
					[pathController performSelector:@selector(enqueueFolderSyncPathOperationRequest:) withObject:aPath afterDelay:BROWSER_ANIMATION_DURATION];
				} else {
					[pathController enqueueFolderSyncPathOperationRequest:aPath];
				}
			}
		} else {
			if (IS_IPAD) {
				[secondaryBrowser beginUpdates];
				if ([secondaryBrowser currentItemViewController]) {
					[secondaryBrowser pop:NO];
				}
#ifdef TASKPAPER
				[secondaryBrowser push:[[[TaskViewController alloc] initWithPath:aPath] autorelease] animated:NO];                
#else
				[secondaryBrowser push:[[[FileViewController alloc] initWithPath:aPath] autorelease] animated:NO];
#endif
				[secondaryBrowser endUpdates:editingPath];
			} else {
				[primaryBrowser beginUpdates];
#ifdef TASKPAPER
                [primaryBrowser push:[[[TaskViewController alloc] initWithPath:aPath] autorelease] animated:animated];
#else
				[primaryBrowser push:[[[FileViewController alloc] initWithPath:aPath] autorelease] animated:animated];
#endif
				[primaryBrowser endUpdates:editingPath];
			}
			
			if (allowAutosync && pathController.syncAutomatically) {
				if (animated) {
					[pathController performSelector:@selector(enqueueFolderSyncPathOperationRequest:) withObject:[aPath stringByDeletingLastPathComponent] afterDelay:BROWSER_ANIMATION_DURATION];
				} else {
					[pathController enqueueFolderSyncPathOperationRequest:[aPath stringByDeletingLastPathComponent]];
				}
			}
		}
		
		return YES;
	} else {
		if ([aPath length] > [pathController.localRoot length]) {
			return [self openItem:[aPath stringByDeletingLastPathComponent] editingPath:editingPath allowAutosync:allowAutosync animated:animated];
		}
	}
	
	return NO;
}

- (void)saveState {
	[[primaryBrowser currentItemViewController] syncViewWithDisk:NO];
	[[secondaryBrowser currentItemViewController] syncViewWithDisk:NO];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)reloadData {
#ifdef TASKPAPER
    if ([[primaryBrowser currentItemViewController].view respondsToSelector:@selector(reloadData)]) {
        [[primaryBrowser currentItemViewController].view performSelector:@selector(reloadData) withObject:nil];
    }
    if ([[secondaryBrowser currentItemViewController].view respondsToSelector:@selector(reloadData)]) {
        [[secondaryBrowser currentItemViewController].view performSelector:@selector(reloadData) withObject:nil];
    }
#endif
}

- (void)hideKeyboard {
	[self becomeFirstResponder];
}

- (void)hideKeyboardDarnIt {
	[self hideKeyboard];
	// Hide keyboard doesnt' seem to work in settings view... not sure why. But this
	// private api seems to always work.
	id keyboardImpl = [NSClassFromString([@"UIKe" stringByAppendingString:@"yboardImpl"]) sharedInstance];
	SEL dismiss = NSSelectorFromString([@"dismi" stringByAppendingString:@"ssKeyboard"]);
	if ([keyboardImpl respondsToSelector:dismiss]) {
		[keyboardImpl performSelector:dismiss];
	}
}

- (void)presentError:(NSError *)error {
	if (error) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
		[alertView show];
		[alertView release];
	}
}

@end

@implementation UIView (ApplicationViewController)

- (void)refreshSelfAndSubviewsFromDefaults {
	for (UIView *each in [self allMySubviews]) {
		if ([each respondsToSelector:@selector(refreshFromDefaults)]) {
			[each refreshFromDefaults];
		}
	}
}

@end


NSString *DocumentFocusModeDefaultsKey = @"DocumentFocusModeDefaultsKey";
NSString *LockOrientationDefaultsKey = @"LockOrientationDefaultsKey";
NSString *LockedOrientationDefaultsKey = @"LockedOrientationDefaultsKey";
NSString *DetectLinksDefaultsKey = @"DetectLinksDefaultsKey";
NSString *ShowStatusBarDefaultsKey = @"ShowStatusBarDefaultsKey";
NSString *ShowFileExtensionsDefaultsKey = @"ShowFileExtensionsDefaultsKey";
NSString *ScrollsHeadingsDefaultsKey = @"ScrollsHeadingsDefaultsKey";
NSString *ExtendedKeyboardDefaultsKey = @"ExtendedKeyboardDefaultsKey";
NSString *ExtendedKeyboardKeysDefaultsKey = @"ExtendedKeyboardKeysDefaultsKey";
NSString *DraggableScrollerDefaultsKey = @"DraggableScrollerDefaultsKey";
NSString *AllCapsHeadingsDefaultsKey = @"AllCapsHeadingsDefaultsKey";
NSString *TextExpanderEnabledDefaultsKey = @"TextExpanderEnabledDefaultsKey";
NSString *AutocorrectionTypeDefaultsKey = @"AutocorrectionTypeDefaultsKey";
NSString *SecondaryBrightnessDefaultsKey = @"SecondaryBrightnessDefaultsKey";
NSString *InkColorDefaultsKey = @"InkColorDefaultsKey";
NSString *PaperColorDefaultsKey = @"PaperColorDefaultsKey";
NSString *TintCursorDefaultsKey = @"TintCursorDefaultsKey";
NSString *SortByDefaultsKey = @"SortByDefaultsKey";
NSString *FontNameDefaultsKey = @"FontNameDefaultsKey";
NSString *FontSizeDefaultsKey = @"FontSizeDefaultsKey";
NSString *LineHeightMultipleDefaultsKey = @"LineHeightMultipleDefaultsKey";
NSString *SortFoldersDefaultsKey = @"SortFoldersDefaultsKey";
NSString *TextRightToLeftDefaultsKey = @"TextRightToLeftDefaultsKey";
NSString *ShowIconBadgeNumberDefaultsKey = @"ShowIconBadgeNumberDefaultsKey";
NSString *AllowFlurryDefaultsKey = @"AllowFlurryDefaultsKey";

NSString *KeyboardWillHideNotification = @"KeyboardWillHideNotification";
NSString *KeyboardWillShowNotification = @"KeyboardWillShowNotification";
NSString *ApplicationViewWillRotateNotification = @"ApplicationViewWillRotateNotification";
NSString *DocumentFocusModeAnimationWillStart = @"DocumentFocusModeAnimationWillStart";
NSString *DocumentFocusModeAnimationDidStop = @"DocumentFocusModeAnimationDidStop";
NSString *TextExpanderEnabledChangedNotification = @"TextExpanderEnabledChangedNotification";
NSString *ShowFileExtensionsChangedNotification = @"ShowFileExtensionsChangedNotification";
NSString *ScrollsHeadingsChangedNotification = @"ScrollsHeadingsChangedNotification";
NSString *AllCapsHeadingsChangedNotification = @"AllCapsHeadingsChangedNotification";
NSString *SortByChangedNotification = @"SortByChangedNotification";
NSString *SortFoldersChangedNotification = @"SortFoldersChangedNotification";
NSString *DetectLinksChangedNotification = @"DetectLinksChangedNotification";
NSString *TextRightToLeftChangedNotification = @"TextRightToLeftChangedNotification";
NSString *ShowIconBadgeNumberChangedNotification = @"ShowIconBadgeNumberChangedNotification";

NSString *ToOrientation = @"ToOrientation";