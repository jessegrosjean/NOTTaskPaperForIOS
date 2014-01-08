//
//  FolderCellViewContent.h
//  PlainText
//
//  Created by Jesse Grosjean on 3/4/11.
//  Copyright 2011 Hog Bay Software. All rights reserved.
//


@interface FolderCellViewContent : UIView {
	NSString *name;
	UIColor *color;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) UIColor *color;

@end
