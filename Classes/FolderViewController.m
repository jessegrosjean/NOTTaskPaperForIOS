//
//  FolderViewController.m
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "FolderViewController.h"
#import "ApplicationViewController.h"
#import "FolderViewCellSelectedBackground.h"
#import "FolderViewCellDirectoryAccessoryView.h"
#import "NSFileManager_Additions.h"
#import "ApplicationController.h"
#import "FolderCellViewContent.h"
#import "BrowserViewController.h"
#import "FileListingOperation.h"
#import "SearchViewController.h"
#import "SyncSpinnerView.h"
#import "SearchTextField.h"
#import "PathController.h"
#import "FolderViewCell.h"
#import "SearchView.h"
#import "FolderView.h"
#import "PathModel.h"
#import "MenuView.h"
#import "Toolbar.h"
#import "Button.h"
#import "BrowserViewController.h"
#import "BrowserView.h"
#import "Searchbar.h"
#import "ShadowMetadata.h"

#include <dirent.h>

struct SortOptions {
	NSInteger sortBy;
	NSInteger sortFolders;
};
typedef struct SortOptions SortOptions;

@interface FolderViewController (Private)

- (NSInteger)rowForItemNamed:(NSString *)aName;
	
@end

@implementation FolderViewController

#pragma mark -
#pragma mark Init

- (id)initWithPath:(NSString *)aPath {
	refreshSelection = YES;
	items = [[NSMutableArray alloc] init];
	isRoot = [aPath isEqualToString:[[NSFileManager defaultManager] documentDirectory]];
	self = [super initWithPath:aPath];
	self.title = [aPath lastPathComponent];
	searchViewController = [[SearchViewController alloc] init];
	searchViewController.delegate = self;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pathsChangedNotification:) name:PathsChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFileExtensionsChangedNotification:) name:ShowFileExtensionsChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sortByChangedNotification:) name:SortByChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sortFoldersChangedNotification:) name:SortFoldersChangedNotification object:nil];
	return self;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.folderView.delegate = nil;
	searchViewController.delegate = nil;
	[fileListingOperation cancel];
	[fileListingOperation release];
	fileListingOperation = nil;
	[items autorelease];
	[super dealloc];
}

#pragma mark -
#pragma mark Attributes

- (BOOL)isFolderViewController {
	return YES;
}

- (NSArray *)toolbarItems {
	Button *beginSearchButton = searchViewController.beginSearchButton;

	return [NSArray arrayWithObjects:
			[Button buttonWithImage:[UIImage imageNamed:@"showSettings.png"] accessibilityLabel:NSLocalizedString(@"Settings", nil) accessibilityHint:nil target:APP_VIEW_CONTROLLER action:@selector(showSettings:) edgeInsets:UIEdgeInsetsMake(0, 5, 0, 15)],
			[Toolbar flexibleSpace],
			beginSearchButton,
			[Toolbar flexibleSpace],
			[Button buttonWithImage:[UIImage imageNamed:@"newFolder.png"] accessibilityLabel:NSLocalizedString(@"New folder", nil) accessibilityHint:nil target:APP_VIEW_CONTROLLER action:@selector(newFolder:) edgeInsets:UIEdgeInsetsMake(0, 15, 0, 15)],
			[Toolbar flexibleSpace],
			[Button buttonWithImage:[UIImage imageNamed:@"newDocument.png"] accessibilityLabel:NSLocalizedString(@"New document", nil) accessibilityHint:nil target:APP_VIEW_CONTROLLER action:@selector(newFile:) edgeInsets:UIEdgeInsetsMake(0, 15, 0, 5)],
			nil];	
}

- (FolderView *)folderView {
	return (id) self.view;
}

#pragma mark -
#pragma mark View lifecycle

- (void)loadView {
	FolderView *folderView = [[[FolderView alloc] init] autorelease];
	folderView.delegate = self;
	folderView.dataSource = self;	
	folderView.accessibilityLabel = NSLocalizedString(@"Folder contents", nil);
	pathViewController.view.accessibilityLabel = NSLocalizedString(@"Folder title", nil);
	pathViewController.view.accessibilityHint = NSLocalizedString(@"Renames the folder", nil);
	self.view = folderView;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	NSIndexPath *indexPath = [self.folderView indexPathForSelectedRow];
	if (indexPath) {
		[self.folderView deselectRowAtIndexPath:indexPath animated:NO];
	} 
	
    self.browserViewController.browserView.searchbar.rightButton = nil;
    self.browserViewController.browserView.searchbar.leftButton = nil;

    
	if (IS_IPAD && refreshSelection) {
		[self performSelector:@selector(refreshSelection) withObject:nil afterDelay:0];
	}
}

#pragma mark -
#pragma mark Actions

- (void)refreshSelection {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshSelection) object:nil];
	
	NSString *openFilePath = [PATH_CONTROLLER openFilePath];
	NSUInteger row = [self rowForItemNamed:[openFilePath lastPathComponent]];
	if (row != NSNotFound && [self.path isEqualToString:[openFilePath stringByDeletingLastPathComponent]]) {
		[self.folderView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
		//[self.folderView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionNone animated:YES];
	}
}

- (MenuView *)pathViewPopupMenuView:(PathViewController *)aPathTextFieldController {
	MenuView *menuView = [MenuView sharedInstance];
	
	[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Rename", nil) indentationLevel:1 enabled:YES checked:NO userData:@"rename"]];
	[menuView addItem:[MenuViewItem separatorItem]];
	[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Sync All Now", nil) indentationLevel:1 enabled:YES checked:NO userData:@"sync"]];
    [menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Sync This Folder", nil) indentationLevel:1 enabled:YES checked:NO userData:@"sync-directory"]];

	
	menuView.target = self;
	menuView.action = @selector(pathViewPopupMenuViewChoice:);
	
	return menuView;
}

- (void)pathViewPopupMenuViewChoice:(MenuView *)menuView {
	MenuViewItem *selectedItem = [menuView.selectedItems lastObject];
	if (selectedItem) {
		NSString *userData = selectedItem.userData;
		if ([userData isEqualToString:@"cut"]) {
			[self cut:nil];
		} else if ([userData isEqualToString:@"copy"]) {
			[self copy:nil];
		} else if ([userData isEqualToString:@"paste"]) {
			[self paste:nil];
		} else if ([userData isEqualToString:@"rename"]) {
			[self rename:nil];
		} else if ([userData isEqualToString:@"sync"]) {
			[self sync:nil];
		} else if ([userData isEqualToString:@"sync-directory"]) {
            [self syncDirectory:nil];
        }
	}
	
	[menuView close];
}

#pragma mark -
#pragma mark Read / Write

NSInteger sort(PathModel *a, PathModel *b, void* context) {
    ShadowMetadata *metadataA = [PATH_CONTROLLER shadowMetadataForLocalPath:a.path createNewLocalIfNeeded:NO];
    ShadowMetadata *metadataB = [PATH_CONTROLLER shadowMetadataForLocalPath:b.path createNewLocalIfNeeded:NO];
    
	SortOptions *sortOptions = ((SortOptions *)context);
	SortFolders sortFolders = sortOptions->sortFolders;
	SortBy sortBy = sortOptions->sortBy;
	
	if (sortFolders == SortFoldersToTop) {
		BOOL aIsDirectory = a.isDirectory;
		if (aIsDirectory != b.isDirectory) {
			if (aIsDirectory) {
				return NSOrderedAscending;
			} else {
				return NSOrderedDescending;
			}
		}
	} else if (sortFolders == SortFoldersToBottom) {
		BOOL aIsDirectory = a.isDirectory;
		if (aIsDirectory != b.isDirectory) {
			if (aIsDirectory) {
				return NSOrderedDescending;
			} else {
				return NSOrderedAscending;
			}
		}
	}
	
	switch (sortBy) {
		case SortByNameDescending:
            return [b.name localizedStandardCompare:a.name];
			//return [b.name compare:a.name options:NSNumericSearch | NSCaseInsensitiveSearch];
		case SortByModified:
            if (metadataA && metadataB) {
                return [metadataA.clientMTime compare:metadataB.clientMTime];
            } else {
                return [a.modified compare:b.modified];
            }
		case SortByModifiedDescending:
            if (metadataA && metadataB) {
                return [metadataB.clientMTime compare:metadataA.clientMTime];
            } else {
                return [b.modified compare:a.modified];
            }
			// Created file system attribute not yet supported by iOS
			/*case SortByCreated:
			 return [a.created compare:b.created];
			 case SortByCreatedDescending:
			 return [b.created compare:a.created];*/
		default:
            return [a.name localizedStandardCompare:b.name];
			//return [a.name compare:b.name options:NSNumericSearch | NSCaseInsensitiveSearch];
	}
}

- (void)syncViewWithDisk:(BOOL)animated {
	[super syncViewWithDisk:animated];
	animateViewUpdates = animated;	
	[fileListingOperation cancel];
	[fileListingOperation release];
	fileListingOperation = [[FileListingOperation alloc] initWithPath:self.path isRecursive:YES filter:searchViewController.searchView.text delegate:self];
	[fileListingOperation start];
}

#pragma mark -
#pragma mark Table file listing operation delegate

- (void)fileListingOperationStarted:(FileListingOperation *)aFileListingOperation {
}

- (void)fileListingOperationCompleted:(FileListingOperation *)aFileListingOperation { // background thread.
	FolderView *folderView = self.folderView;
	
	if (refreshSelection) {
		NSIndexPath *selectedIndexPath = [folderView indexPathForSelectedRow];
		if (selectedIndexPath) {
			[folderView deselectRowAtIndexPath:selectedIndexPath animated:NO];
		}		
	}
	
	NSMutableArray *newItems = [[aFileListingOperation.results mutableCopy] autorelease];
	if (newItems) {		
		SortOptions options;
		options.sortBy = [APP_VIEW_CONTROLLER sortBy];
		options.sortFolders = [APP_VIEW_CONTROLLER sortFolders];
		[newItems sortUsingFunction:&sort context:(void *)&options];
		
		if (animateViewUpdates) {
			NSArray *oldItems = items;
			NSSet *oldSet = [NSSet setWithArray:oldItems];
			NSSet *newSet = [NSSet setWithArray:newItems];
			NSMutableSet *pendingDeletes = [NSMutableSet set];
			NSMutableArray *insertedIndexPaths = [NSMutableArray array];
			NSMutableArray *deletedIndexPaths = [NSMutableArray array];
			NSMutableIndexSet *oldListDeletedIndexes = [NSMutableIndexSet indexSet];
			NSMutableIndexSet *oldListInsertedIndexes = [NSMutableIndexSet indexSet];
			NSMutableIndexSet *newListInsertIndexes = [NSMutableIndexSet indexSet];
			NSUInteger oldCount = [oldItems count];
			NSUInteger newCount = [newItems count];
			NSUInteger oldIndex = 0, newIndex = 0;
			NSInteger delta = 0;
			id eachOld, eachNew;
			
			while (oldIndex < oldCount && newIndex < newCount) {
				eachOld = [oldItems objectAtIndex:oldIndex];
				eachNew = [newItems objectAtIndex:newIndex];
				
				if ([eachOld isEqual:eachNew]) {
					oldIndex++;
					newIndex++;
				} else {
					if (![oldSet containsObject:eachNew]) {
						// Insert new item.
						[insertedIndexPaths addObject:[NSIndexPath indexPathForRow:oldIndex + delta inSection:0]];
						[oldListInsertedIndexes addIndex:oldIndex + delta];
						[newListInsertIndexes addIndex:newIndex];
						newIndex++;
						delta++;
					} else if (![newSet containsObject:eachOld]) {
						// Deleted old item.
						[deletedIndexPaths addObject:[NSIndexPath indexPathForRow:oldIndex inSection:0]];
						[oldListDeletedIndexes addIndex:oldIndex];
						oldIndex++;
						delta--;
					} else {
						if ([pendingDeletes containsObject:eachOld]) {
							// Delete old item.
							[deletedIndexPaths addObject:[NSIndexPath indexPathForRow:oldIndex inSection:0]];
							[oldListDeletedIndexes addIndex:oldIndex];
							oldIndex++;
							delta--;
						} else {
							// Insert new item, but also record it for delete later.
							[pendingDeletes addObject:eachNew];
							[insertedIndexPaths addObject:[NSIndexPath indexPathForRow:oldIndex + delta inSection:0]];
							[oldListInsertedIndexes addIndex:oldIndex + delta];
							[newListInsertIndexes addIndex:newIndex];
							newIndex++;
							delta++;
						}
					}
				}
			}
			
			while (oldIndex < oldCount) {
				[deletedIndexPaths addObject:[NSIndexPath indexPathForRow:oldIndex inSection:0]];
				[oldListDeletedIndexes addIndex:oldIndex];
				oldIndex++;
				delta--;
			}
			
			while (newIndex < newCount) {
				[insertedIndexPaths addObject:[NSIndexPath indexPathForRow:oldIndex + delta inSection:0]];
				[oldListInsertedIndexes addIndex:oldIndex + delta];
				[newListInsertIndexes addIndex:newIndex];
				newIndex++;
				delta++;
			}
			
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationBeginsFromCurrentState:YES];

			if ([deletedIndexPaths count] > 0) {
				[items removeObjectsAtIndexes:oldListDeletedIndexes];
				[folderView beginUpdates];
				[folderView deleteRowsAtIndexPaths:deletedIndexPaths withRowAnimation:UITableViewRowAnimationNone];
				[folderView endUpdates];
			}
			
			if ([insertedIndexPaths count] > 0) {
				NSArray *insertedObjects = [newItems objectsAtIndexes:newListInsertIndexes];
				[items insertObjects:insertedObjects atIndexes:oldListInsertedIndexes];					
				[folderView beginUpdates];
				[folderView insertRowsAtIndexPaths:insertedIndexPaths withRowAnimation:UITableViewRowAnimationNone];
				[folderView endUpdates];
			}
			
			[UIView commitAnimations];
		} else {
			[items removeAllObjects];
			[items addObjectsFromArray:newItems];
			[folderView reloadData];
		}
	} else {
		[APP_VIEW_CONTROLLER openItem:[self.path stringByDeletingLastPathComponent] animated:animateViewUpdates];
		return;
	}
	
	if ([items count] > 0) {
		if (IS_IPAD && refreshSelection) {
			[self performSelector:@selector(refreshSelection) withObject:nil afterDelay:0];
		}
	}
}

#pragma mark -
#pragma mark SearchViewController delegate

- (void)searchViewTextDidChange:(SearchViewController *)aSearchViewController {
	[self syncViewWithDisk:NO];
}

#pragma mark -
#pragma mark shadowMetadata managedObjectContext

- (void)pathsChangedNotification:(NSNotification *)aNotification {
	NSSet *stateChangedPaths = [[aNotification userInfo] objectForKey:StateChangedPathsKey];
	NSSet *activityChangedPaths = [[aNotification userInfo] objectForKey:ActivityChangedPathsKey];
	NSSet *allChangedPaths = [stateChangedPaths setByAddingObjectsFromSet:activityChangedPaths];
	
	FolderView *folderView = self.folderView;
	NSString *folderPath = self.path;
	
	for (NSString *eachChanged in allChangedPaths) {
		NSString *changedFolder = [eachChanged stringByDeletingLastPathComponent];
		
		if ([changedFolder isEqualToString:folderPath]) {
			NSString *changedName = [eachChanged lastPathComponent];
			NSUInteger index = [self rowForItemNamed:changedName];
			if (index != NSNotFound) {
				NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
				[folderView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
			}
		}
	}
}

- (void)sortByChangedNotification:(NSNotification *)aNotification {
	[self syncViewWithDisk:NO];
}

- (void)sortFoldersChangedNotification:(NSNotification *)aNotification {
	[self syncViewWithDisk:NO];
}

- (void)showFileExtensionsChangedNotification:(NSNotification *)aNotification {
	[self.folderView reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSArray *)items {
	return items;
}

- (NSInteger)rowForItemNamed:(NSString *)aName {
	NSUInteger result = 0;
	for (PathModel *each in self.items) {
		if ([each.name isEqual:aName]) {
			return result;
		}
		result++;
	}
	return NSNotFound;
}

- (PathModel *)itemForIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		return [self.items objectAtIndex:indexPath.row];
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	return [self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"CellIdentifier";
	
	FolderViewCell *cell = (id) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[FolderViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.selectedBackgroundView = [[[FolderViewCellSelectedBackground alloc] init] autorelease];
	}
	
	ApplicationViewController *appViewController = APP_VIEW_CONTROLLER;
	PathController *pathController = PATH_CONTROLLER;
	FolderCellViewContent *folderCellViewContent = cell.folderCellViewContent;
	PathModel *item = [self itemForIndexPath:indexPath];
	NSString *localPath = item.path;
	NSString *displayName = [appViewController displayNameForPath:localPath isDirectory:item.isDirectory];
	PathState pathState = [pathController stateForPath:localPath];
	PathActivity pathActivity = [pathController pathActivityForPath:localPath];
	BOOL showPathActivity = NO;

	folderCellViewContent.name = displayName;
	
	switch (pathActivity) {
		case RefreshPathActivity:
		case GetPathActivity:
		case PutPathActivity:
			showPathActivity = YES;
			break;
	}
	
	if (showPathActivity) {
		SyncSpinnerView *syncSpinnerView = [[[SyncSpinnerView alloc] init] autorelease];
		cell.accessoryView = syncSpinnerView;
		[syncSpinnerView startAnimating];
	} else {
		if (item.isDirectory) {
			cell.accessoryView = [[[FolderViewCellDirectoryAccessoryView alloc] init] autorelease];
		} else {
			cell.accessoryView = nil;
		}
	}
	
	switch (pathState) {
		case UnsyncedPathState:
			folderCellViewContent.color = [appViewController inkColor];
			break;
		case SyncedPathState:
			folderCellViewContent.color = [appViewController inkColor];
			break;
		case SyncErrorPathState:
			folderCellViewContent.color = [appViewController highlightColor];
			break;
		case TemporaryPlaceholderPathState:
			folderCellViewContent.color = [appViewController inkColorByPercent:0.5];
			break;
		case PermanentPlaceholderPathState:
			folderCellViewContent.color = [appViewController inkColorByPercent:0.15];
			break;
		default:
			break;
	}

	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		PathModel *item = [self itemForIndexPath:indexPath];
		NSString *removePath = item.path;
		NSError *error;
		
		if ([indexPath isEqual:[tableView indexPathForSelectedRow]]) {
			// commit any in progress editing, so that 
		}
		
		if (![PATH_CONTROLLER removeItemAtPath:removePath error:&error]) {
			[APP_VIEW_CONTROLLER presentError:error];
		}
	}
}

#pragma mark -
#pragma mark Table view delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleDelete;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	PathModel *item = [self itemForIndexPath:indexPath];
	NSString *willSelectPath = item.path;
	PathState willSelectPathState = [PATH_CONTROLLER stateForPath:willSelectPath];
	NSString *alertMessage = nil;
	NSIndexPath *result = nil;
	
	switch (willSelectPathState) {
		case TemporaryPlaceholderPathState:
			
			alertMessage = [NSString stringWithFormat:NSLocalizedString(@"“%@” is downloading from Dropbox and can't be opened until the download is complete.", nil), item.name];
			break;
		case PermanentPlaceholderPathState:
#if TASKPAPER
			alertMessage = [NSString stringWithFormat:NSLocalizedString(@"“%@” did not have a recognized file extension and won't be downloaded. You can add custom extensions in the View preferences.", nil), item.name];            
#else
			alertMessage = [NSString stringWithFormat:NSLocalizedString(@"“%@” does not have a recognized plain text file extension and won't be downloaded.", nil), item.name];
#endif
			break;
			
		case SyncErrorPathState: {
			NSError *pathError = [PATH_CONTROLLER errorForPath:willSelectPath];
			NSString *errorInfo = @"";
			
			if (pathError) {
				errorInfo = [NSString stringWithFormat:@"\n %@", [pathError localizedDescription]];
			}
			
			[[[[UIAlertView alloc] initWithTitle:nil 
										 message:[NSString stringWithFormat:NSLocalizedString(@"There was an error syncing “%@”. It may be out of date.%@", nil), item.name, errorInfo, nil]
										delegate:nil 
							   cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease] show];
			break;
		}
	}
	
	if (alertMessage) {
		[[[[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease] show];
	} else {
		result = indexPath;		
	}
	
	return result;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	PathModel *item = [self itemForIndexPath:indexPath];
	NSString *selectedPath = item.path;
	
	if (![[PATH_CONTROLLER openFilePath] isEqualToString:selectedPath]) {
		refreshSelection = NO;
		[APP_VIEW_CONTROLLER openItem:selectedPath animated:YES];
		refreshSelection = YES;
	}
}

@end