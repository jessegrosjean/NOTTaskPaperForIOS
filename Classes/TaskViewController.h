//
//  TaskViewController.h
//  SimpleText
//
//  Created by Kim Young Hoo on 11. 3. 13..
//  Copyright 2011 CodingRobots. All rights reserved.
//

#import "ItemViewController.h"
#import "MessageUI/MFMailComposeViewController.h"
#import "TaskView.h"
#import "Tree.h"

@class TaskView;

@interface TaskViewController : ItemViewController <UIScrollViewDelegate, TaskViewDelegate, TreeDelegate, MFMailComposeViewControllerDelegate, UIPrintInteractionControllerDelegate> {
    NSStringEncoding stringEncoding;
    Tree *tree;
	NSMutableArray *sections;
    BOOL shiftKeyDown;
    BOOL selectionChangedWhileShiftKeyDown;
    
    NSTimer *syncWithDiskTimer;

    BOOL savingTextContentToDisk;
	BOOL hasUnsavedChanges;
	NSString *lastFileContents;
	NSString *lineEnding;
    
    NSString *sectionSearchString;
    
    CGFloat keyboardSize;
    
    NSString *sectionsAsStringOnDragging;
    
    BOOL saveToDiskWhenKeyboardDidHide;
    BOOL keyboardHide;
}

- (id)initWithPath:(NSString *)aPath;
- (void)saveToDisk;
- (void)updateIconBadgeNumberCount;

@property (nonatomic, assign) BOOL hasUnsavedChanges;
@property (nonatomic, assign) BOOL saveToDiskWhenKeyboardDidHide;
@property (nonatomic, retain) NSString *sectionSearchString;



@end

extern NSString *DefaultTagsKey;
extern NSString *AddDateToDoneTagKey;
extern NSString *LiveSearchEnabledKey;