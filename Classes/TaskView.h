//
//  TaskView.h
//  SimpleText
//
//  Created by Kim Young Hoo on 11. 3. 13..
//  Copyright 2011 CodingRobots. All rights reserved.
//

@class IPhoneDocumentViewCell;
@class IPhoneDocumentViewFieldEditor;
@class Section;
@class SMTEDelegateController;
@protocol TaskViewDelegate;


@interface TaskView : UIScrollView <UITextViewDelegate> {
	UIEdgeInsets padding;
	UIEdgeInsets lastLayoutPadding;
    
    SMTEDelegateController *fieldEditorTextExpander;
    
    NSUInteger updating;
	NSMutableArray *rowDatas;
	NSUInteger firstInvalidRowData;
	NSMutableIndexSet *rowsToInsert;
	NSMutableIndexSet *rowsToReload;
	NSMutableIndexSet *rowsToRemove;
	BOOL animateReloadRows;
	NSMutableSet *animatingCells;
	NSMutableArray *reusableCells;
	NSMutableIndexSet *selectedRows;
	NSMutableIndexSet *selectedRowsCover;
	NSUInteger editedRow;
	CGPoint startTouchPosition;
	CGPoint lastTouchPosition;
	CGPoint touchesEndedLocation;
	NSUInteger swipedRow;
	NSUInteger deletedRow;
	NSUInteger draggedRow;
	NSUInteger droppedRow;
	NSInteger dragStartLevel;
	NSInteger dropLevel;
	BOOL droppedAbove;

    UIView *dragIndicatorView;
	NSTimer *autoscrollTimer;
	CGFloat autoscrollDistance;
	UILabel *placeHolderLabel;
    
    id<TaskViewDelegate> taskDelegate;
}

+ (UIColor *)selectionColor;
- (IPhoneDocumentViewCell *)dequeueReusableCell;

@property(retain, nonatomic) NSString *placeholderText;

- (void)processDrag;

#pragma mark Geometry
- (CGRect)rowsVisibleRect;
- (CGRect)rectForRow:(NSUInteger)row;
- (NSRange)rowsInRect:(CGRect)rect;
- (NSUInteger)rowAtPoint:(CGPoint)point;
- (NSUInteger)rowForSection:(Section *)aSection;
- (Section *)sectionForRow:(NSUInteger)row;
- (IPhoneDocumentViewCell *)cellForRow:(NSUInteger)row;

@property (nonatomic, assign) id<TaskViewDelegate> taskDelegate;

#pragma mark Rows

@property(readonly, nonatomic) NSUInteger numberOfRows;

#pragma mark Selection

@property(retain, nonatomic) NSIndexSet *selectedRows;
@property(readonly) NSIndexSet *selectedRowsCover;
@property(readonly) NSArray *selectedSections;

#pragma mark Editing

@property(assign, nonatomic) NSUInteger editedRow;
@property(assign, nonatomic) Section *editedSection;

#pragma mark FieldEditor

- (void)commitFieldEditor;
- (void)removeFieldEditor;
- (void)commitAndRemoveFieldEditor;
- (void)beginFieldEditorForRow:(NSUInteger)row;
- (void)beginFieldEditorForRowAtPoint:(CGPoint)aPoint;
- (void)scrollFieldEditorToVisible:(BOOL)animated;

#pragma mark Updates

- (void)beginUpdates;
@property(readonly) BOOL isUpdating;
- (void)endUpdates;
- (void)endUpdatesAnimated:(BOOL)animated;
- (void)insertRows:(NSIndexSet *)rows animated:(BOOL)animated;
- (void)removeRows:(NSIndexSet *)rows animated:(BOOL)animated;
- (void)reloadRows:(NSIndexSet *)rows animated:(BOOL)animated;
- (void)reloadData;

#pragma mark Events

@property(assign, nonatomic) NSUInteger swipedRow;
@property(assign, nonatomic) NSUInteger draggedRow;
@property(assign, nonatomic) NSUInteger droppedRow;
@property(assign, nonatomic) NSInteger dropLevel;
@property(assign, nonatomic) BOOL droppedAbove;

#pragma Item view
@property (assign, nonatomic) UIEdgeInsets padding;

@end

@protocol TaskViewDelegate

- (IBAction)cut:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)delete:(id)sender;


- (NSUInteger)numberOfRowsInDocumentView:(TaskView *)documentView;
- (Section *)documentView:(TaskView *)documentView sectionForRow:(NSUInteger)row;
- (NSUInteger)documentView:(TaskView *)documentView rowForSection:(Section *)aSection;
- (IPhoneDocumentViewCell *)documentView:(TaskView *)documentView cellForRow:(NSUInteger)row;
- (void)documentView:(TaskView *)documentView tapAtPoint:(CGPoint)aPoint;
- (void)documentView:(TaskView *)documentView touchAtPoint:(CGPoint)aPoint;
- (void)documentView:(TaskView *)documentView doubleTapAtPoint:(CGPoint)aPoint;
- (void)documentView:(TaskView *)documentView swipeRightFromPoint:(CGPoint)aPoint;
- (void)documentView:(TaskView *)documentView swipeLeftFromPoint:(CGPoint)aPoint;
- (void)documentView:(TaskView *)documentView deleteRow:(NSUInteger)aRow;
- (BOOL)documentView:(TaskView *)documentView fieldEditor:(IPhoneDocumentViewFieldEditor *)fieldEditor shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)documentViewStartedDrag:(TaskView *)documentView;
- (void)documentViewEndedDrag:(TaskView *)documentView;


@end

CGPoint midpointBetweenPoints(CGPoint a, CGPoint b);
