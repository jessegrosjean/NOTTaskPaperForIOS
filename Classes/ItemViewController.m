//
//  PathContentsViewController.m
// PlainText
//
//  Created by Jesse Grosjean on 6/24/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "ItemViewController.h"
#import "ApplicationController.h"
#import "FolderViewController.h"
#import "SearchViewController.h"
#import "PathViewWrapper.h"
#import "PathController.h"
#import "BrowserView.h"
#import "PathView.h"


@implementation ItemViewController

- (id)init {
	self = [super init];
	pathViewController = [[PathViewController alloc] init];
	pathViewController.delegate = self;
	return self;
}

- (id)initWithPath:(NSString *)aPath {
	self = [self init];	
	[pathViewController setPath:aPath isDirectory:self.isFolderViewController];
	return self;
}

- (void)dealloc {
	pathViewController.delegate = nil;
	[lastModificationDate release];
	[pathViewController release];
	[super dealloc];
}

#pragma mark -
#pragma mark Properties

@synthesize path;

- (NSString *)path {
	return self.pathViewController.path;
}

- (void)setPath:(NSString *)aPath {
	pathViewController.delegate = nil;
	[pathViewController setPath:aPath isDirectory:self.isFolderViewController];
	pathViewController.delegate = self;
	[self saveOpenPathsState];
}

- (MenuView *)actionsMenuView {
	return nil;
}

- (BOOL)isFileViewController {
	return NO;
}

- (BOOL)isFolderViewController {
	return NO;
}

@synthesize pathViewController;
@synthesize searchViewController;

#pragma mark -
#pragma mark Actions

//- (IBAction)cut:(id)sender {
//}
//
//- (IBAction)copy:(id)sender {
//}
//
//- (IBAction)paste:(id)sender {
//}

- (IBAction)rename:(id)sender {
	PathView *pathView = self.pathViewController.pathViewWrapper.pathView;
	[pathView becomeFirstResponder];
	[pathView selectAllWithNoMenuController:sender];
}

- (IBAction)sync:(id)sender {
	[PATH_CONTROLLER beginFullSync];
}

- (IBAction)syncDirectory:(id)sender {
    [PATH_CONTROLLER enqueueFolderSyncPathOperationRequest:self.path];
}

#pragma mark -
#pragma mark Read / Write

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	//[self read:NO];
	[self syncViewWithDisk:animated];
}

- (void)syncViewWithDisk:(BOOL)animated {
	NSError *error;
	[lastModificationDate autorelease];
	lastModificationDate = [[[[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:&error] fileModificationDate] retain];
}

/*- (void)read:(BOOL)animated {
	NSError *error;
	[lastModificationDate autorelease];
	lastModificationDate = [[[[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:&error] fileModificationDate] retain];
}

- (void)save {
	NSError *error;
	[lastModificationDate autorelease];
	lastModificationDate = [[[[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:&error] fileModificationDate] retain];
}
*/

- (void)saveAs:(NSString *)newPath {
	self.path = newPath;
	[self syncViewWithDisk:NO];
	//[self save];
}

- (BOOL)hasChangedOnDisk {
	NSDate *modificationDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:NULL] fileModificationDate];
	
	if (lastModificationDate == modificationDate) {
		return NO;
	} else if (lastModificationDate == nil && modificationDate != nil) {
		return YES;
	}
	
	return ![lastModificationDate isEqualToDate:modificationDate];
}

- (void)saveOpenPathsState {
	if (self.isFileViewController) {
		PATH_CONTROLLER.openFilePath = self.path;
	} else {
		PATH_CONTROLLER.openFolderPath = self.path;
	}
}

#pragma mark -
#pragma mark PathViewController delegate

- (void)pathViewReturnKeypressed:(PathViewController *)aPathViewController {
	if ([self.view canBecomeFirstResponder]) {
		if ([self.view isKindOfClass:[UITextView class]]) {
			[((UITextView *)self.view) setEditable:YES];
		}
        if ([self.view respondsToSelector:@selector(beginFieldEditorForRow:)]) {
            [self.view performSelector:@selector(beginFieldEditorForRow:) withObject:0];
            return;
        }
		[self.view becomeFirstResponder];
	}
}

- (MenuView *)pathViewPopupMenuView:(PathViewController *)aPathTextFieldController {
	return nil;
}

- (void)pathViewChangedTitle:(PathViewController *)aPathTextFieldController {
	self.title = aPathTextFieldController.title;
}

- (void)pathViewWillChangePath:(PathViewController *)aPathTextFieldController from:(NSString *)oldPath to:(NSString *)newPath {
}

- (void)pathViewDidChangePath:(PathViewController *)aPathTextFieldController from:(NSString *)oldPath to:(NSString *)newPath {
	PathController *pathController = PATH_CONTROLLER;

	if ([pathController.openFolderPath isEqualToString:oldPath]) {
		pathController.openFolderPath = newPath;
	}

	if ([pathController.openFilePath isEqualToString:oldPath]) {
		pathController.openFilePath = newPath;
	}
}

#pragma mark -
#pragma mark SearchViewController delegate

- (void)searchViewReturnKeypressed:(SearchViewController *)aSearchViewController {
	if ([self.view canBecomeFirstResponder]) {
		[self.view becomeFirstResponder];
	}
}

#pragma mark -
#pragma mark Undo Manager
- (NSUndoManager *)undoManager {
    return nil;
}

#pragma mark - 
#pragma mark Save & Restore Scroll
- (UIScrollView *)scrollView {
    return (UIScrollView *)[self view];
}

- (void)saveContentOffset {
    UIScrollView *scrollView = self.scrollView;
	NSString *thePath = [self.path lastPathComponent];
    
    if (scrollView != nil && thePath != nil) {
        NSData *offsetData = [[NSUserDefaults standardUserDefaults] objectForKey:OpenDocumentContentOffsetDefaultsKey];
        NSMutableDictionary *offsetDict;
        if (offsetData != nil) {
            @try {
                offsetDict = [NSKeyedUnarchiver unarchiveObjectWithData:offsetData];
            } @catch (NSException *exception) {
                offsetDict = [NSMutableDictionary dictionary];
            }
        } else {
            offsetDict = [NSMutableDictionary dictionary];        
        }
        float offsetY = [[self scrollView] contentOffset].y;
        [offsetDict setObject:[NSValue valueWithCGPoint:CGPointMake([[self scrollView] contentOffset].x, offsetY)] forKey:self.path];
        offsetData = [NSKeyedArchiver archivedDataWithRootObject:offsetDict];
        [[NSUserDefaults standardUserDefaults] setObject:offsetData forKey:OpenDocumentContentOffsetDefaultsKey];
    }
}

- (void)restoreContentOffset {
    NSData *offsetData = [[NSUserDefaults standardUserDefaults] objectForKey:OpenDocumentContentOffsetDefaultsKey];
    UIScrollView *scrollView = self.scrollView;
	NSString *thePath = [self.path lastPathComponent];

    if (offsetData != nil && scrollView != nil && thePath != nil) {
        if ([offsetData isKindOfClass:[NSData class]]) {
            @try {
                NSMutableDictionary *offsetDict = [NSKeyedUnarchiver unarchiveObjectWithData:offsetData];
                NSNumber *offsetValue = [offsetDict valueForKey:self.path];
                if (offsetValue) {
                    CGPoint offsetPoint = [offsetValue CGPointValue];
                    [[self scrollView] setContentOffset:CGPointMake(offsetPoint.x, offsetPoint.y) animated:YES];                
                }
            } @catch (NSException *exception) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSMutableDictionary dictionary]] forKey:OpenDocumentContentOffsetDefaultsKey];
            }
        } else {
			LogWarn(@"Expected NSData but got %@", offsetData);
		}
    }
}

@end


NSString *OpenDocumentContentOffsetDefaultsKey = @"OpenDocumentContentOffsetDefaultsKey";
NSString *OpenDocumentSearchDefaultsKey = @"OpenDocumentSearchDefaultsKey";