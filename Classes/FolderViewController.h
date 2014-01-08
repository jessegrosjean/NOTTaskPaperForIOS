//
//  FolderViewController.h
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "ItemViewController.h"
#import "FileListingOperation.h"

@class FolderView;

@interface FolderViewController : ItemViewController <UITableViewDataSource, UITableViewDelegate, FileListingOperationDelegate> {
	FileListingOperation *fileListingOperation;
	NSMutableArray *items;
	BOOL animateViewUpdates;
	BOOL refreshSelection;
	BOOL isRoot;
}

- (id)initWithPath:(NSString *)aPath;

- (FolderView *)folderView;

@end
