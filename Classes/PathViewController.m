//
//  BrowserViewController.m
// PlainText
//
//  Created by Jesse Grosjean on 6/24/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "PathViewController.h"
#import "ApplicationViewController.h"
#import "NSFileManager_Additions.h"
#import "ApplicationController.h"
#import "NSString_Additions.h"
#import "PathViewWrapper.h"
#import "PathController.h"
#import "PathView.h"
#import "MenuView.h"
#import "Button.h"


@implementation PathViewController

- (id)init {
	self = [super init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFileExtensionsChangedNotification:) name:ShowFileExtensionsChangedNotification object:nil];
	return self;
}

- (void)dealloc {
	if (textExpander) {
		[[NSNotificationCenter defaultCenter] removeObserver:textExpander];
		[textExpander setNextDelegate:nil];
		[textExpander release];
		textExpander = nil;
	}
	self.pathViewWrapper.pathView.delegate = nil;
	[path release];
	[super dealloc];
}

- (void)showFileExtensionsChangedNotification:(NSNotification *)aNotification {
	[self setPath:self.path isDirectory:isDirectory];
}

@synthesize path;

- (UITextField *)textField {
	return (id) self.pathViewWrapper.pathView;
}

- (PathViewWrapper *)pathViewWrapper {
	return (id) self.view;
}

- (void)setPath:(NSString *)aPath isDirectory:(BOOL)aBool {
	isDirectory = aBool;
	
	NSString *oldPath = path;

	if (![oldPath isEqualToString:aPath]) {
		[(id)delegate pathViewWillChangePath:self from:oldPath to:aPath];
	}
	
	[path autorelease];
	path = [aPath retain];
	
	self.title = [APP_VIEW_CONTROLLER displayNameForPath:aPath isDirectory:isDirectory];
	
	if (![oldPath isEqualToString:aPath]) {
		[(id)delegate pathViewDidChangePath:self from:oldPath to:aPath];
	}
}

- (NSString *)pathFromTitle:(NSString *)aTitle {
	if ([aTitle length] == 0) {
		aTitle = NSLocalizedString(@"Untitled", nil);
	} else if ([aTitle characterAtIndex:0] == '.') {
		aTitle = [NSLocalizedString(@"Untitled", nil) stringByAppendingPathExtension:aTitle];
	}
	
	aTitle = [aTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	aTitle = [aTitle stringByReplacingOccurrencesOfString:@";" withString:@"-"]; // dropbox limitation
	aTitle = [aTitle stringByReplacingOccurrencesOfString:@"~" withString:@"-"]; // dropbox limitation
	aTitle = [aTitle stringByReplacingOccurrencesOfString:@"\\" withString:@":"]; // dropbox limitation	
	aTitle = [aTitle stringByReplacingOccurrencesOfString:@"/" withString:@":"]; // ios limitation	
		
	if ([APP_VIEW_CONTROLLER showFileExtensions]) {
		if (!isDirectory) {
            if ([[aTitle pathExtension] isEqualToString:@""]) {
				aTitle = [aTitle stringByAppendingPathExtension:[PathController defaultTextFileType]];
            }
		}
		return [[self.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:aTitle];
	} else {
		NSString *extension = [self.path pathExtension];
		NSString *result = [[self.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:aTitle];
		if ([extension length] > 0 && ![[result pathExtension] isEqualToString:extension]) {
			result = [result stringByAppendingPathExtension:extension];
		}
		return result;
	}
}

- (BOOL)isValidPath:(NSString *)aPath {
	if ([path isEqualToDropboxPath:aPath]) {
		return YES;
	} else {
		NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[aPath stringByDeletingLastPathComponent] error:NULL];
		NSString *name = [aPath lastPathComponent];
		
		for (NSString *each in contents) {
			if ([each isEqualToDropboxPath:name]) {
				return NO;
			}
		}
	}
	return YES;
}

- (void)updateTextColorForNewTitle:(NSString *)newTitle {
	PathView *pathView = self.pathViewWrapper.pathView;
	
	if ([self isValidPath:[self pathFromTitle:newTitle]]) {
		pathView.textColor = [APP_VIEW_CONTROLLER inkColor];
	} else {
		pathView.textColor = [APP_VIEW_CONTROLLER highlightColor];
	}
}

- (void)setTitle:(NSString *)aTitle {
	NSString *oldTitle = self.title;
	[super setTitle:aTitle];
	self.pathViewWrapper.pathView.text = aTitle;
	if (![oldTitle isEqualToString:aTitle]) {
		[(id)delegate pathViewChangedTitle:self];
	}
	[self updateTextColorForNewTitle:aTitle];
}

#pragma mark -
#pragma mark Popup Menu

- (void)showPopupMenu:(id)sender {	
	MenuView *menuView = [(id)delegate pathViewPopupMenuView:self];
	
	menuView.anchorView = self.pathViewWrapper.pathView;
	menuView.offsetPosition = CGPointMake(0, (NSUInteger)([APP_VIEW_CONTROLLER leading] / 2));
	menuView.anchorRelativePosition = PositionDown;
	
	[menuView show];	
}

#pragma mark -
#pragma mark View lifecycle

- (void)textExpanderEnabledChanged:(NSNotification *)aNotification {
	BOOL iOS4OrLater = [APP_CONTROLLER isIOS4OrLater];
	PathView *pathView = self.pathViewWrapper.pathView;
	
	if (textExpander) {
		if (iOS4OrLater) {
			[[NSNotificationCenter defaultCenter] removeObserver:textExpander name:UIApplicationWillEnterForegroundNotification object:nil];
		}
		pathView.delegate = self;
		[textExpander setNextDelegate:nil];
		[textExpander release];
		textExpander = nil;
	}
	
	if ([APP_VIEW_CONTROLLER textExpanderEnabled]) {
		textExpander = [[SMTEDelegateController alloc] init];
		[textExpander setNextDelegate:pathView.delegate];
		pathView.delegate = textExpander;
		if (iOS4OrLater) {
			[[NSNotificationCenter defaultCenter] addObserver:textExpander selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
		}
	}
}

- (void)loadView {
	PathViewWrapper *pathViewWrapper = [[[PathViewWrapper alloc] init] autorelease];
	pathViewWrapper.pathView.delegate = self;
	pathViewWrapper.pathView.text = self.title;
	[pathViewWrapper.popupMenuButton addTarget:self action:@selector(showPopupMenu:) forControlEvents:UIControlEventTouchUpInside];
	self.view = pathViewWrapper;
	/*
	PathView *pathView = [[[PathView alloc] init] autorelease];
	pathView.delegate = self;
	pathView.text = self.title;
	[pathView.popupMenuButton addTarget:self action:@selector(showPopupMenu:) forControlEvents:UIControlEventTouchUpInside];
	self.view = pathView;*/
	[super loadView];
}

#pragma mark -
#pragma mark Title textField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self.delegate pathViewReturnKeypressed:self];
	if ([textField isFirstResponder]) {
		[textField resignFirstResponder];
	}	
	return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	textField.rightViewMode = UITextFieldViewModeNever;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	NSString *newTitle = textField.text;
	NSString *newPath = [self pathFromTitle:newTitle];
	
	if ([self isValidPath:newPath]) {
		if (![newPath isEqualToString:self.path]) {
			NSError *error;
			if (![PATH_CONTROLLER moveItemAtPath:self.path toPath:newPath error:&error]) {
				[APP_VIEW_CONTROLLER presentError:error];
				[self setPath:self.path isDirectory:isDirectory];
			}
		}
	} else {
		UIAlertView *renameAlert = [[[UIAlertView alloc] initWithTitle:nil
															   message:[NSString stringWithFormat:NSLocalizedString(@"The name “%@” is already taken or invalid. Please choose a different name.", nil), newTitle]
															  delegate:nil
													 cancelButtonTitle:NSLocalizedString(@"OK", nil)
													 otherButtonTitles:nil, nil] autorelease];
		[renameAlert show];
		[self setPath:self.path isDirectory:isDirectory];
	}
	
	textField.textColor = [APP_VIEW_CONTROLLER inkColor];
	textField.rightViewMode = UITextFieldViewModeUnlessEditing;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if ([path isEqualToString:[PATH_CONTROLLER localRoot]]) {
		[APP_VIEW_CONTROLLER presentError:[PathController documentsFolderCannotBeRenamedError]];
		return NO;
	}
	
	NSString *newTitle = [textField.text stringByReplacingCharactersInRange:range withString:string];
	
	[self updateTextColorForNewTitle:newTitle];
	
	return YES;
}

@end
