//
//  PathContentsViewController.h
// PlainText
//
//  Created by Jesse Grosjean on 6/24/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "ViewController.h"
#import "PathViewController.h"

@class MenuView;
@class SearchViewController;

@interface ItemViewController : ViewController <PathViewControllerDelegate> {
	PathViewController *pathViewController;
	SearchViewController *searchViewController;
	NSDate *lastModificationDate;
}

- (id)initWithPath:(NSString *)aPath;

#pragma mark -
#pragma mark Properties

@property (nonatomic, retain) NSString *path;
@property (nonatomic, readonly) MenuView *actionsMenuView;
@property (nonatomic, readonly) BOOL isFileViewController;
@property (nonatomic, readonly) BOOL isFolderViewController;
@property (nonatomic, readonly) PathViewController *pathViewController;
@property (nonatomic, readonly) SearchViewController *searchViewController;

#pragma mark -
#pragma mark Actions

//- (IBAction)cut:(id)sender;
//- (IBAction)copy:(id)sender;
//- (IBAction)paste:(id)sender;
- (IBAction)rename:(id)sender;
- (IBAction)sync:(id)sender;
- (IBAction)syncDirectory:(id)sender;

#pragma mark -
#pragma mark Read / Write

- (void)syncViewWithDisk:(BOOL)animated;

//- (void)read:(BOOL)animated;
//- (void)save;
- (void)saveAs:(NSString *)newPath;
- (BOOL)hasChangedOnDisk;
- (void)saveOpenPathsState;

- (NSUndoManager *)undoManager;

- (void)saveContentOffset;
- (void)restoreContentOffset;

@end

@interface UIView (ItemViewController)

@property (nonatomic, assign) UIEdgeInsets padding;

@end

extern NSString *OpenDocumentContentOffsetDefaultsKey;
extern NSString *OpenDocumentSearchDefaultsKey;