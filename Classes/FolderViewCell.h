//
//  FolderViewCell.h
//  PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

@class ShadowMetadata;
@class FolderCellViewContent;

@interface FolderViewCell : UITableViewCell {
	FolderCellViewContent *folderCellViewContent;
	BOOL showingDeleteConfirmation;
}

@property (nonatomic, readonly) FolderCellViewContent *folderCellViewContent;

@end
