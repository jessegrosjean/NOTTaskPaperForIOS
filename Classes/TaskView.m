//
//  TaskView.m
//  SimpleText
//
//  Created by Kim Young Hoo on 11. 3. 13..
//  Copyright 2011 CodingRobots. All rights reserved.
//

#import <MobileCoreServices/UTCoreTypes.h>

#import "TaskView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "NSString_Additions.h"
#import "UIView_Additions.h"
#import "BrowserView.h"
#import "Button.h"
#import "UIScrollView_Additions.h"

#import "UITextView_Additions.h"

#import "TaskViewController.h"

#import "IPhoneDocumentViewCell.h"
#import "IPhoneDocumentViewFieldEditor.h"
#import "Tree.h"

#define SEARCH_BAR_HEIGHT 0.0
#define DOUBLE_TAP_DELAY 0.35
#define SWIPE_DISTANCE 12
#define DRAG_START_DELAY 0.25
#define DRAG_INDICATOR_HEIGHT 12.0
#define DRAG_INDICATOR_STROKE 3.0
#define AUTOSCROLL_THRESHOLD 120.0
#define FIELD_EDITOR_PADDING 30.0

static float initialOffsetY;

@interface RowData : NSObject {
@public
	NSUInteger row;
	CGRect rowRect;
	CGRect lastRowRect;
@protected
	IPhoneDocumentViewCell *cell;
}

+ (NSMutableArray *)rowDatasWithCapacity:(NSUInteger)capacity;
@property(assign, nonatomic) IPhoneDocumentViewCell *cell;
- (void)invalidateCachedRowRect;
@end

@interface DragIndicatorView : UIView {
}
@end

@interface TaskView (TaskViewPrivate)
- (void)validateRowDatasToRow:(NSUInteger)fixToRow;
- (void)updatedFieldEditorForRow:(NSUInteger)row;
@end


@implementation TaskView

@synthesize taskDelegate;

- (void)refreshFromDefaults {
    self.backgroundColor = [APP_VIEW_CONTROLLER paperColor];
    [(TaskViewController *)self.taskDelegate updateIconBadgeNumberCount];
    [self setNeedsDisplay];
}

+ (UIColor *)selectionColor {
	static UIColor *selectionColor = nil;
	if (!selectionColor) {
		selectionColor = [[UIColor colorWithRed:56.0/255.0 green:117.0/255.0 blue:215.0/255.0 alpha:1.0] retain];
	}
	return selectionColor;
}

- (void)commonInit {
 	rowDatas = [[RowData rowDatasWithCapacity:[self numberOfRows]] retain];
	rowsToInsert = [[NSMutableIndexSet alloc] init];
	rowsToReload = [[NSMutableIndexSet alloc] init];
	rowsToRemove = [[NSMutableIndexSet alloc] init];
	reusableCells = [[NSMutableArray alloc] init];
	animatingCells = [[NSMutableSet alloc] init];
	selectedRows = [[NSMutableIndexSet alloc] init];
	selectedRowsCover = [[NSMutableIndexSet alloc] init];
	deletedRow = NSNotFound;
	editedRow = NSNotFound;

    self.alwaysBounceVertical = YES;
	self.scrollsToTop = YES;
	self.autoresizesSubviews = YES;
	self.canCancelContentTouches = YES;
	self.delaysContentTouches = YES;
    
    self.backgroundColor = [APP_VIEW_CONTROLLER paperColor];
}

- (id)init {
	self = [super init];
    self.taskDelegate = nil;
    lastLayoutPadding = UIEdgeInsetsMake(-1, -1, -1, -1);

	[self commonInit];
	return self;
}

- (void)dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [fieldEditorTextExpander setNextDelegate:nil];
	[fieldEditorTextExpander release];
    [placeHolderLabel release];
	[rowDatas release];
	[rowsToInsert release];
	[rowsToReload release];
	[rowsToRemove release];
	[reusableCells release];
	[animatingCells release];
	[dragIndicatorView release];
	[selectedRows release];
	[selectedRowsCover release];
	[autoscrollTimer invalidate];
	[autoscrollTimer release];
	[super dealloc];
}

- (IPhoneDocumentViewCell *)dequeueReusableCell {
	if ([reusableCells count] > 0) {
		IPhoneDocumentViewCell *result = [[[reusableCells lastObject] retain] autorelease];
		[reusableCells removeLastObject];
		return result;
	}
	return [[[IPhoneDocumentViewCell alloc] init] autorelease];
}

- (NSString *)placeholderText {
	return placeHolderLabel.text;
}

- (void)setPlaceholderText:(NSString *)aString {
	if ([aString length] > 0) {
		if (!placeHolderLabel) {
			placeHolderLabel = [[UILabel alloc] init];
			placeHolderLabel.textColor = [APP_VIEW_CONTROLLER inkColorByPercent:0.30];
			placeHolderLabel.font = [UIFont boldSystemFontOfSize:20];
			placeHolderLabel.backgroundColor = [UIColor clearColor];
		}
		placeHolderLabel.text = aString;
		[placeHolderLabel sizeToFit];
		placeHolderLabel.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds) + SEARCH_BAR_HEIGHT / 2);
		[self addSubview:placeHolderLabel];
	} else {
		[placeHolderLabel removeFromSuperview];
	}
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

#pragma mark Geometry

- (void)setFrame:(CGRect)aFrame {
	[super setFrame:aFrame];
}

- (CGRect)rectForStartOfRows {
	return CGRectMake(0, SEARCH_BAR_HEIGHT, self.bounds.size.width, 0);
}

- (CGRect)rowsVisibleRect {
	CGRect visibleRect = [self frame];
	CGPoint contentOffset = self.contentOffset;
	visibleRect.origin.x = contentOffset.x;
	visibleRect.origin.y = contentOffset.y;
	return visibleRect;
}

- (CGRect)rectForRow:(NSUInteger)row {
	if (row >= firstInvalidRowData) [self validateRowDatasToRow:row];
	RowData *rowData = [rowDatas objectAtIndex:row];
	return rowData->rowRect;
}

- (NSRange)rowsInRect:(CGRect)rect {
	NSUInteger rowDatasCount = [rowDatas count];
    
	if (rowDatasCount == 0) return NSMakeRange(NSNotFound, 0);
	if (firstInvalidRowData != NSNotFound) [self validateRowDatasToRow:NSNotFound];
	
	CGFloat rowsTop = CGRectGetMinY([self rectForRow:0]);
	CGFloat rowsBottom = CGRectGetMaxY([self rectForRow:rowDatasCount - 1]);
	
	if (rect.origin.y < rowsTop) {
		rect.size.height -= rowsTop - rect.origin.y;
		rect.origin.y = rowsTop;
	}
	
	if (CGRectGetMaxY(rect) > rowsBottom) {
		rect.size.height -= CGRectGetMaxY(rect) - rowsBottom;
	}
	
	NSUInteger startRow = [self rowAtPoint:CGPointMake(0, CGRectGetMinY(rect))];
	if (startRow == NSNotFound) return NSMakeRange(NSNotFound, 0);
	
	NSUInteger endRow = [self rowAtPoint:CGPointMake(0, CGRectGetMaxY(rect))];
	if (endRow == NSNotFound) endRow = rowDatasCount - 1;
    
	return NSMakeRange(startRow, endRow - startRow);
}

- (NSUInteger)rowAtPoint:(CGPoint)point {
	if (point.y < SEARCH_BAR_HEIGHT) {
		return NSNotFound;
	}
	
	NSUInteger rowDatasCount = [rowDatas count];
	NSUInteger low = 0;
	NSUInteger high = rowDatasCount;
	NSUInteger index = low;
	
	while (index < high) {
		NSUInteger mid = (index + high) / 2;
		RowData *test = [rowDatas objectAtIndex:mid];
		CGRect testRect = test->rowRect;
		CGFloat testPosition = testRect.origin.y;
		CGFloat testHeight = testRect.size.height;
		
		if (testPosition + testHeight >= point.y) {
			high = mid;
		} else {
			index = mid + 1;
		}
	}
	
	if (index == rowDatasCount) {
		return NSNotFound;
	} else {
		return index;
	}
}

- (NSUInteger)rowForSection:(Section *)aSection {
	return [(id)self.taskDelegate documentView:self rowForSection:aSection];
}

- (Section *)sectionForRow:(NSUInteger)row {
	return [(id)self.taskDelegate documentView:self sectionForRow:row];
}

- (IPhoneDocumentViewCell *)cellForRow:(NSUInteger)row {
	if (row != NSNotFound) {
		return [[rowDatas objectAtIndex:row] cell];
	}
	return nil;
}



#pragma mark Layout
- (NSMutableArray *)rowsWithCellsOnSurface {
	NSArray *subviews = self.subviews;
	Class documentViewCellClass = [IPhoneDocumentViewCell class];
    int rowsCapacity = [subviews count] - 2;
	NSMutableArray *rowsWithCells = [NSMutableArray arrayWithCapacity:rowsCapacity > 0 ? rowsCapacity : 0];
	for (IPhoneDocumentViewCell *each in subviews) {
		if ([each isKindOfClass:documentViewCellClass] && ![animatingCells containsObject:each]) {
			[rowsWithCells addObject:each.rowData];
		}
	}
	return rowsWithCells;
}

- (void)updateContentSize:(BOOL)animate {
	
	CGRect bounds = self.bounds;
	NSUInteger rowDatasCount = [rowDatas count];
	CGSize newContentSize = CGSizeMake(bounds.size.width, 0);
	if (rowDatasCount > 0) newContentSize = CGSizeMake(bounds.size.width, CGRectGetMaxY([self rectForRow:rowDatasCount - 1]) + FIELD_EDITOR_PADDING);

	if (newContentSize.height < bounds.size.height) {
		newContentSize.height = bounds.size.height;
	}
	
	if (!CGSizeEqualToSize(newContentSize, self.contentSize)) {
		if (animate) {
			[UIView beginAnimations:nil context:NULL];
			self.contentSize = newContentSize;
			[UIView commitAnimations];
		} else {
			self.contentSize = newContentSize;
		}
	}	
}

- (void)layoutSubviews {
	[super layoutSubviews];
    
    if (placeHolderLabel.superview == self) {
		self.placeholderText = self.placeholderText;
	}
	CGRect visibleRect = [self rowsVisibleRect];
	IPhoneDocumentViewCell *eachRowDataCell;
	RowData *eachRowData;
	for (eachRowData in [self rowsWithCellsOnSurface]) {
		eachRowDataCell = eachRowData.cell;
		if (!CGRectIntersectsRect(eachRowDataCell.frame, visibleRect)) {
			[reusableCells addObject:eachRowDataCell];
			[eachRowDataCell removeFromSuperview];
			eachRowData.cell = nil;
		}
	}
    
    NSRange visibleRows = [self rowsInRect:visibleRect];
	if (visibleRows.location != NSNotFound) {
		for (NSUInteger i = visibleRows.location; i <= NSMaxRange(visibleRows); i++) {
			eachRowData = [rowDatas objectAtIndex:i];
			eachRowDataCell = eachRowData.cell;
			
			if (!eachRowDataCell) {
                eachRowDataCell = [(TaskViewController *)self.taskDelegate documentView:self cellForRow:i];
                eachRowDataCell.frame = eachRowData->rowRect;
                eachRowData.cell = eachRowDataCell;
                [self insertSubview:eachRowDataCell atIndex:0];
			} else {
				eachRowDataCell.frame = eachRowData->rowRect;
			}
		}
	}
    
    IPhoneDocumentViewFieldEditor *editor = [IPhoneDocumentViewFieldEditor sharedInstance];
	if (editor.superview == self) {
		if ([self.subviews lastObject] != editor) {
			NSArray *subviews = self.subviews;
			NSUInteger editorIndex = [subviews indexOfObject:editor];
			NSUInteger count = [subviews count];
			
			for (NSUInteger i = editorIndex; i < count; i++) {
				UIView *v = [subviews objectAtIndex:i];
				if ([v isKindOfClass:[IPhoneDocumentViewCell class]]) {
					[self exchangeSubviewAtIndex:editorIndex withSubviewAtIndex:i];
					editorIndex = i;
				}
			}
		}
	}	
	[self updateContentSize:NO];
}

- (void)animateLayoutSubviews {	
	// 1. Figure out which rowData's need to be removed and added. Also
	// keep track of rows on surface that aren't being removed or added, 
	// because they will need to be animated to new positions.
	NSMutableArray *rowDatasWithCellsToRemove = [NSMutableArray array];
	NSMutableArray *rowDatasWithCellsToAdd = [NSMutableArray array];
	NSMutableArray *remainingLastVisibleRows = [self rowsWithCellsOnSurface];
    
	if ([rowsToReload count] > 0) {
		[rowsToReload removeIndexesInRange:NSMakeRange([rowDatas count], ([rowDatas count] - [rowsToReload lastIndex]) + 1)];
		NSArray *rowDatasToReload = [rowDatas objectsAtIndexes:rowsToReload];
		[rowDatasToReload makeObjectsPerformSelector:@selector(invalidateCachedRowRect)];
		[rowDatasWithCellsToRemove addObjectsFromArray:rowDatasToReload];
		[rowDatasWithCellsToAdd addObjectsFromArray:rowDatasToReload];
		[rowsToReload removeAllIndexes];
	}	
	
	if ([rowsToRemove count] > 0) {
		[rowDatasWithCellsToRemove addObjectsFromArray:[rowDatas objectsAtIndexes:rowsToRemove]];
		[rowDatas removeObjectsAtIndexes:rowsToRemove];
		[rowsToRemove removeAllIndexes];
	}
	
	if ([rowsToInsert count] > 0) {
		[rowDatas insertObjects:[RowData rowDatasWithCapacity:[rowsToInsert count]] atIndexes:rowsToInsert];
		[rowDatasWithCellsToAdd addObjectsFromArray:[rowDatas objectsAtIndexes:rowsToInsert]];
		[rowsToInsert removeAllIndexes];
	}
	
	// 3. Now that rowData collection is updated revalidate all rows. This seems
	// excesive, but is needed because lastRowRect needs to be valid for all rows
	// to cover all animation cases.
	firstInvalidRowData = 0;
	[self validateRowDatasToRow:[rowDatas count]];
	
	// 4. Next grab cells from changed rows figure out where and how
	// they need to be animated.
	NSMutableArray *animatedCellRemoves = [NSMutableArray array];
	NSMutableArray *animatedCellAdds = [NSMutableArray array];
	NSMutableArray *animatedRowDataMoves = [NSMutableArray array];
	NSUInteger numberOfRows = [self numberOfRows];
	CGRect visibleRect = [self rowsVisibleRect];
	IPhoneDocumentViewCell *eachRowDataCell;
	RowData *eachRowData;
	
	for (eachRowData in rowDatasWithCellsToRemove) {
		eachRowDataCell = eachRowData.cell;
		if (eachRowDataCell) {
			[animatedCellRemoves addObject:eachRowDataCell];
			[self sendSubviewToBack:eachRowDataCell];
			eachRowData.cell = nil;
			[remainingLastVisibleRows removeObject:eachRowData];
		}
	}
	
	for (eachRowData in rowDatasWithCellsToAdd) {
		if (CGRectIntersectsRect(eachRowData->rowRect, visibleRect)) {
			NSUInteger row = eachRowData->row;
			if (row < numberOfRows) {
				eachRowDataCell = [(TaskViewController *)self.taskDelegate documentView:self cellForRow:row];
				eachRowData.cell = eachRowDataCell;
				eachRowDataCell.frame = eachRowData->rowRect;
				eachRowDataCell.alpha = 0.0;
				[animatedCellAdds addObject:eachRowDataCell];
				[self insertSubview:eachRowDataCell atIndex:0];
			}
		}
	}
	
	NSRange visibleRows = [self rowsInRect:visibleRect];
	if (visibleRows.location != NSNotFound) {
		for (NSUInteger i = visibleRows.location; i <= NSMaxRange(visibleRows); i++) {
			eachRowData = [rowDatas objectAtIndex:i];
			eachRowDataCell = eachRowData.cell;
			
			[remainingLastVisibleRows removeObject:eachRowData];
			
			if (![animatedCellAdds containsObject:eachRowDataCell]) {
				if (!eachRowDataCell) {
                    eachRowDataCell = [(TaskViewController *)self.taskDelegate documentView:self cellForRow:i];
                    eachRowData.cell = eachRowDataCell;
                    [self insertSubview:eachRowDataCell atIndex:0];
				}
				eachRowDataCell.frame = eachRowData->lastRowRect;
				[animatedRowDataMoves addObject:eachRowData];
			}
		}
	}
	
	[animatedRowDataMoves addObjectsFromArray:remainingLastVisibleRows];
	
	// 4. Perform animations or direct moves.
	if (animateReloadRows) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationWillStartSelector:@selector(layoutSubviewsAnimationWillStart:context:)];
		[UIView setAnimationDidStopSelector:@selector(layoutSubviewsAnimationDidStop:context:)];
		[UIView setAnimationDelegate:self];
		
		if (animateReloadRows) {
			for (UIView *eachView in animatedCellRemoves) {
				[animatingCells addObject:eachView];
				eachView.alpha = 0.0;
			}
			
			for (UIView *eachView in animatedCellAdds) {
				[animatingCells addObject:eachView];
				eachView.alpha = 1.0;
			}
			
			for (eachRowData in animatedRowDataMoves) {
				if (!CGRectEqualToRect(eachRowData->lastRowRect, eachRowData->rowRect)) {
					eachRowData.cell.frame = eachRowData->rowRect;
					[animatingCells addObject:eachRowData.cell];
				}
			}
		}
		
		[UIView commitAnimations];
	} else {
		for (IPhoneDocumentViewCell *eachView in animatedCellRemoves) {
			[reusableCells addObject:eachView];
			[eachView removeFromSuperview];
			eachView.rowData.cell = nil;
		}
		
		for (UIView *eachView in animatedCellAdds) {
			eachView.alpha = 1.0;
		}
		
		for (eachRowData in animatedRowDataMoves) {
			if (!CGRectEqualToRect(eachRowData->lastRowRect, eachRowData->rowRect)) {
				eachRowData.cell.frame = eachRowData->rowRect;
			}
		}		
	}
	
	[self updateContentSize:animateReloadRows];
    [self updatedFieldEditorForRow:self.editedRow];
}

- (void)layoutSubviewsAnimationWillStart:(NSString *)animationID context:(void *)context {
}

- (void)layoutSubviewsAnimationDidStop:(NSString *)animationID context:(void *)context {
	Class c = [IPhoneDocumentViewCell class];
	CGRect visibleRect = [self rowsVisibleRect];
	for (IPhoneDocumentViewCell *each in self.subviews) {
		if ([each isKindOfClass:c]) {
			if (!CGRectIntersectsRect(each.frame, visibleRect) || each.alpha == 0.0) {
				[reusableCells addObject:each];
				[each removeFromSuperview];
				each.alpha = 1.0;
				each.rowData.cell = nil;
			}
			[animatingCells removeObject:each];
		}
	}
	[animatingCells removeAllObjects]; // hack didn't expect this case. problem happens when a row is added (animate layout) and then right after selected (and another animate layout is run). result is
	// animating cells gets dangling object that creates problems later in rowsWithCellsOnSurface.
}

#pragma mark Rows

- (NSUInteger)numberOfRows {
	return [(TaskViewController *)self.taskDelegate numberOfRowsInDocumentView:self];
}

#pragma mark Selection

@synthesize selectedRows;

- (void)setSelectedRows:(NSIndexSet *)newSelectedRows {
	NSMutableIndexSet *reloadIndexes = [NSMutableIndexSet indexSet];
	
	[reloadIndexes addIndexes:selectedRows];
	[reloadIndexes addIndexes:selectedRowsCover];
	
	[selectedRowsCover removeAllIndexes];
	[selectedRows removeAllIndexes];
	[selectedRows addIndexes:newSelectedRows];
	
	if (editedRow == NSNotFound) {
		NSUInteger numberOfRows = [self numberOfRows];
		for (NSUInteger r = [selectedRows firstIndex]; r != NSNotFound; r = [selectedRows indexGreaterThanIndex:r]) {
			NSUInteger selectedLevel = [self sectionForRow:r].level;
			NSUInteger i = r + 1;
			
			while (i < numberOfRows) {
				Section *section = [self sectionForRow:i];
				if (section.level > selectedLevel) {
					[selectedRowsCover addIndex:i];
					i++;
				} else {
					i = NSNotFound;
				}
			}
		}
	}
    
	[reloadIndexes addIndexes:selectedRows];
	[reloadIndexes addIndexes:selectedRowsCover];
    
	if (![selectedRows containsIndex:editedRow]) {
        [self commitAndRemoveFieldEditor];
	}
	
	[self reloadRows:reloadIndexes animated:NO];
}

@synthesize selectedRowsCover;

- (NSArray *)selectedSections {
	NSMutableArray *selectedSections = [NSMutableArray arrayWithCapacity:[selectedRows count]];
	for (NSUInteger r = [selectedRows firstIndex]; r != NSNotFound; r = [selectedRows indexGreaterThanIndex:r]) {
		[selectedSections addObject:[self sectionForRow:r]];
	}
	return selectedSections;
}

#pragma mark Editing

- (NSUInteger)editedRow {
	return editedRow;
}

- (void)setEditedRow:(NSUInteger)aRow {
	NSMutableIndexSet *reloadRows = [NSMutableIndexSet indexSet];
	
	if (editedRow != NSNotFound) {
		[reloadRows addIndex:editedRow];
		
		if (aRow == NSNotFound) {
			//NSUInteger oldEditedRow = editedRow;
			editedRow = NSNotFound;
			//[self setSelectedRows:[NSIndexSet indexSet]];
		}
	}
	
	editedRow = aRow;
        
	if (editedRow != NSNotFound) {
		[reloadRows addIndex:editedRow];
		[self setSelectedRows:[NSIndexSet indexSetWithIndex:editedRow]];
	}
	
	[self reloadRows:reloadRows animated:NO];
}

- (Section *)editedSection {
	if (self.editedRow == NSNotFound) {
		return nil;
	} else {
		return [self sectionForRow:editedRow];
	}
}

- (void)setEditedSection:(Section *)aSection {
	self.editedRow = [self rowForSection:aSection];
}


#pragma mark FieldEditor

- (void)commitFieldEditor {
	IPhoneDocumentViewFieldEditor *editor = [IPhoneDocumentViewFieldEditor sharedInstance];
	if (editedRow != NSNotFound && editor.uncommitedChanges) {
		Section *section = [self sectionForRow:editedRow];
		if (![section.content isEqualToString:editor.text]) {
			[section setContent:editor.text];
		}
		editor.uncommitedChanges = NO;
        if ([editor isFirstResponder]) {
            ((TaskViewController *)self.taskDelegate).saveToDiskWhenKeyboardDidHide = YES;
        } else {
            [((TaskViewController *)self.taskDelegate) saveToDisk];            
        }
        [section.tree commitCurrentPatch:NSLocalizedString(@"Typing", nil)];
        NSLog(@"commitCurrentPatch: Typing");

	}
}

- (void)removeFieldEditor {
	IPhoneDocumentViewFieldEditor *editor = [IPhoneDocumentViewFieldEditor sharedInstance];
	if (editor.superview) {
		[self beginUpdates];
		[self becomeFirstResponder];
		[editor removeFromSuperview];
		editor.uncommitedChanges = NO;
        [fieldEditorTextExpander setNextDelegate:nil];
		editor.delegate = nil;
		[UIView beginAnimations:nil context:nil];
		[UIView commitAnimations];
		self.editedRow = NSNotFound;
		[self endUpdates];
	}
}

- (void)commitAndRemoveFieldEditor {
	[self commitFieldEditor];
	[self removeFieldEditor];
}

- (void)setupFieldEditorForRow:(NSUInteger)row {
	[self commitFieldEditor];
	
	if (row == NSNotFound) {
		[self removeFieldEditor];
	} else {
		self.editedRow = row;
        
		IPhoneDocumentViewFieldEditor *editor = [IPhoneDocumentViewFieldEditor sharedInstance];
		Section *section = [self sectionForRow:row];
        if (section) {
            CGRect frame = CGRectInset([IPhoneDocumentViewCell textRectForSection:section inBounds:[self rectForRow:row]], -8, -8);
            
            editor.frame = frame;
            editor.text = section.content;
            editor.font = section.sectionFont;
            editor.textColor = section.sectionColor;
            editor.placeholderText = [NSString stringWithFormat:NSLocalizedString(@"New %@", nil), [[section typeAsString] capitalizedString]];
            
            if ([APP_VIEW_CONTROLLER textExpanderEnabled]) {
                if (!fieldEditorTextExpander) {
                    fieldEditorTextExpander = [[SMTEDelegateController alloc] init];
                    fieldEditorTextExpander.provideUndoSupport = YES;
                }
                
                if (fieldEditorTextExpander.nextDelegate != self) {
                    [fieldEditorTextExpander setNextDelegate:self];
                }
                
                if (editor.delegate != fieldEditorTextExpander) {
                    [editor setDelegate:fieldEditorTextExpander];
                }
            } else {
                editor.delegate = self;
            }
            
            if (editor.superview != self) {
                [editor removeFromSuperview];
                [self addSubview:editor];
            } else {
                [editor.superview bringSubviewToFront:editor];
            }
        }
    }	
}


- (void)beginFieldEditorForRow:(NSUInteger)row {
	[self setupFieldEditorForRow:row];
	[[IPhoneDocumentViewFieldEditor sharedInstance] becomeFirstResponder];
}

- (void)beginFieldEditorForRowAtPoint:(CGPoint)aPoint {
	NSUInteger row = [self rowAtPoint:aPoint];
	if (row != NSNotFound) {
		IPhoneDocumentViewFieldEditor *editor = [IPhoneDocumentViewFieldEditor sharedInstance];
		animateReloadRows = NO;
		[self setupFieldEditorForRow:[self rowAtPoint:aPoint]];
		[editor myMakeSelectionWithPoint:[self convertPoint:aPoint toView:editor]];
		NSRange selectedRange = [editor selectedRange];
		[editor becomeFirstResponder];
		[editor setSelectedRange:selectedRange];
	}
}

- (void)scrollFieldEditorToVisible:(BOOL)animated {
	IPhoneDocumentViewFieldEditor *editor = [IPhoneDocumentViewFieldEditor sharedInstance];
	if (editor.superview) {
		CGRect r = [editor myRectForSelection:editor.selectedRange];
		r.size.height += FIELD_EDITOR_PADDING;
        CGRect scrollRect = [editor convertRect:r toView:self];
		[self scrollRectToVisible:scrollRect animated:animated];
	}
}


#pragma mark FieldEditor Delegate

- (void)textViewDidChange:(UITextView *)textView {
	IPhoneDocumentViewFieldEditor *editor = [IPhoneDocumentViewFieldEditor sharedInstance];
	
	editor.uncommitedChanges = YES;
	
	Section *section = [self sectionForRow:editedRow];
	
	if ([textView.text length] == 0 || [section.content length] == 0) {
		[editor setNeedsDisplay];
	}
	
	CGSize sizeToFit = CGSizeMake(self.bounds.size.width, CGFLOAT_MAX);
	CGFloat oldHeight = [section sizeThatFits:sizeToFit].height;
	
	if (![section.content isEqualToString:textView.text]) {
		section.content = textView.text;
	}
	
	CGFloat newHeight = [section sizeThatFits:sizeToFit].height;
	
	if (oldHeight != newHeight) {
		[self reloadRows:[NSIndexSet indexSetWithIndex:editedRow] animated:NO];
		editor.frame = CGRectInset([IPhoneDocumentViewCell textRectForSection:section inBounds:[self rectForRow:editedRow]], -8, -8);
		if (editedRow > 0) {
			[self bringSubviewToFront:[self cellForRow:editedRow - 1]];
		}
		
		if (editedRow + 1 < [self numberOfRows] - 1) {
			[self bringSubviewToFront:[self cellForRow:editedRow + 1]];
		}
	}
	
	[self layoutSubviews]; // force content size to grow by FIELD_EDITOR_PADDING
	
	[self scrollFieldEditorToVisible:NO];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	return [(id)self.taskDelegate documentView:self fieldEditor:(id)textView shouldChangeTextInRange:range replacementText:text];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [fieldEditorTextExpander setNextDelegate:nil];
	textView.delegate = nil;
	[self commitAndRemoveFieldEditor];
}

#pragma mark Updates

- (void)beginUpdates {
	updating++;
}

- (BOOL)isUpdating {
	return updating > 0;
}

- (void)endUpdates {
	[self endUpdatesAnimated:animateReloadRows];
}

- (void)endUpdatesAnimated:(BOOL)animated {
	animateReloadRows = animated;
	updating--;
	if (updating == 0) {
		[self animateLayoutSubviews];
		animateReloadRows = YES;
	}
}

- (void)insertRows:(NSIndexSet *)rows animated:(BOOL)animated {
	[self beginUpdates];
	animateReloadRows = animated;
	[rowsToInsert addIndexes:rows];
	[self endUpdates];
}

- (void)removeRows:(NSIndexSet *)rows animated:(BOOL)animated {
	[self beginUpdates];
	animateReloadRows = animated;
	[rowsToRemove addIndexes:rows];
	[rowsToReload removeIndexes:rows];
	[selectedRows removeIndexes:rows];
	[selectedRowsCover removeIndexes:rows];
	[self endUpdates];
}

- (void)reloadRows:(NSIndexSet *)rows animated:(BOOL)animated {
	[self beginUpdates];
	animateReloadRows = animated;
	[rowsToReload addIndexes:rows];
	[self endUpdates];
}

- (void)reloadData {
	firstInvalidRowData = 0;
	
	for (RowData *each in [self rowsWithCellsOnSurface]) {
		[each.cell removeFromSuperview];
	}
	
	[rowDatas release];
	rowDatas = [[RowData rowDatasWithCapacity:[self numberOfRows]] retain];
	
	[selectedRows removeAllIndexes];
	[selectedRowsCover removeAllIndexes];
    
	animateReloadRows = NO;
	[self animateLayoutSubviews];
	[self layoutSubviews];
	    
	animateReloadRows = YES;
    
    if (!initialOffsetY) {
        initialOffsetY = [self contentOffset].y;
        
    }
}

#pragma mark Event Handling

@synthesize swipedRow;
@synthesize draggedRow;
@synthesize droppedRow;
@synthesize dropLevel;
@synthesize droppedAbove;

- (UIView *)dragIndicatorView {
	if (!dragIndicatorView) {
		dragIndicatorView = [[DragIndicatorView alloc] init];
	}
	return dragIndicatorView;
}

- (void)processDrag {
	NSUInteger row = [self rowAtPoint:lastTouchPosition];
	NSUInteger numberOfRows = [self numberOfRows];
    
	if (row == NSNotFound) {
		if (lastTouchPosition.y < SEARCH_BAR_HEIGHT || numberOfRows == 0) {
			droppedRow = 0;
		} else {
			droppedRow = [self numberOfRows] - 1;
		}
	} else {
		droppedRow = row;
	}
    	
	CGRect indicatorFrame;
	
	if (droppedRow == 0 && [self numberOfRows] == 0) {
		indicatorFrame = [self rectForStartOfRows];
		droppedAbove = YES;
	} else {
		indicatorFrame = [self rectForRow:droppedRow];
	}
    
    if (lastTouchPosition.y > CGRectGetMidY(indicatorFrame)) {
		indicatorFrame.origin.y += (indicatorFrame.size.height - (DRAG_INDICATOR_HEIGHT / 2.0));
		indicatorFrame.size.height = DRAG_INDICATOR_HEIGHT;
		droppedAbove = NO;
	} else {
		indicatorFrame.origin.y -= DRAG_INDICATOR_HEIGHT / 2.0;
		indicatorFrame.size.height = DRAG_INDICATOR_HEIGHT;
		droppedAbove = YES;
	}
    
	NSInteger levelDifference = (lastTouchPosition.x - startTouchPosition.x) / 20.0;
	dropLevel = dragStartLevel + levelDifference;
	
	if (dropLevel < 0) {
		dropLevel = 0;
	}
    
	if (row == NSNotFound) {
		if (numberOfRows > 0) {
			if (CGRectGetMaxY([self rectForRow:numberOfRows - 1]) <= lastTouchPosition.y) {
				droppedAbove = NO;
				row = numberOfRows - 1;
			} else {
				droppedAbove = YES;
				row = 0;
			}
		} else {
			dropLevel = 0;
		}
	}
	
	if (droppedRow < numberOfRows) {
		Section *droppedOnSection = [self sectionForRow:droppedRow];
		Section *droppedBelowSection = droppedAbove ? droppedOnSection.treeOrderPrevious : droppedOnSection;
		Section *droppedAboveSection = droppedAbove ? droppedOnSection : droppedOnSection.treeOrderNext;
		
		if (dropLevel > droppedBelowSection.level + 1) {
			dropLevel = droppedBelowSection.level + 1;
		}
		
		if (dropLevel < droppedAboveSection.level) {
			dropLevel = droppedAboveSection.level;
		}
	}
    
	NSInteger indentationWidth = dropLevel * 20;
	indicatorFrame.origin.x += indentationWidth;
	indicatorFrame.size.width -= indentationWidth;
	self.dragIndicatorView.frame = indicatorFrame;    
}

- (void)handleStartDrag {
	draggedRow = [self rowAtPoint:lastTouchPosition];
	if (draggedRow != NSNotFound) {
		dragStartLevel = [self sectionForRow:draggedRow].level;
		lastTouchPosition.y = [self rectForRow:draggedRow].origin.y;
		[self addSubview:self.dragIndicatorView];
		[self processDrag];
		self.scrollEnabled = NO;
		self.editedRow = NSNotFound;
		[(id)self.taskDelegate documentViewStartedDrag:self];
	}
}

- (void)maybeStartAutoscroll {
	autoscrollDistance = 0;
    
	CGFloat distanceFromTop = lastTouchPosition.y - CGRectGetMinY(self.bounds);
	CGFloat distanceFromBottom = CGRectGetMaxY(self.bounds) - lastTouchPosition.y;
    
    if (distanceFromTop < AUTOSCROLL_THRESHOLD) {
		autoscrollDistance = ceilf((AUTOSCROLL_THRESHOLD - distanceFromTop) / 5.0) * -1;
	} else if (distanceFromBottom < AUTOSCROLL_THRESHOLD) {
		autoscrollDistance = ceilf((AUTOSCROLL_THRESHOLD - distanceFromBottom) / 5.0);
	}
    
    if (autoscrollDistance == 0) {
		[autoscrollTimer invalidate];
		[autoscrollTimer release];
		autoscrollTimer = nil;
	} else if (!autoscrollTimer) {
		autoscrollTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(autoscrollTimerFired:) userInfo:nil repeats:YES] retain];
	}
}

- (void)stopAutoscroll {
	autoscrollDistance = 0;
	[autoscrollTimer invalidate];
	[autoscrollTimer release];
	autoscrollTimer = nil;
}

- (void)autoscrollTimerFired:(NSTimer *)aTimer {
    
	float minimumLegalDistance = ([self contentOffset].y + fabs(initialOffsetY)) * -1;
	float maximumLegalDistance = [self contentSize].height - ([self frame].size.height + ([self contentOffset].y + fabs(initialOffsetY))) + 30; //30 = toolbar height
    
    if (minimumLegalDistance > 0) {
        minimumLegalDistance = 0;
    }
    
    if (maximumLegalDistance < 0) {
        maximumLegalDistance += fabs(initialOffsetY);
    }
    
    if (maximumLegalDistance < 0) {
        maximumLegalDistance = 0;
    }
    
	autoscrollDistance = MAX(autoscrollDistance, minimumLegalDistance);
	autoscrollDistance = MIN(autoscrollDistance, maximumLegalDistance);
    
	if (fabs(autoscrollDistance) > 0) {
		CGPoint contentOffset = [self contentOffset];
        
        if (autoscrollDistance > 0) {
            contentOffset.y += autoscrollDistance + fabs(initialOffsetY / 6.0);
        } else {
            contentOffset.y += (autoscrollDistance - fabs(initialOffsetY / 6.0));
        }
        
		[self setContentOffset:contentOffset animated:NO];
		lastTouchPosition.y += autoscrollDistance;
		[self processDrag];
        contentOffset = [self contentOffset];
	} else {
		[self stopAutoscroll];
	}
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	UIView *result = [super hitTest:point withEvent:event];
	UIView *each = result;
	BOOL delayContentTouches = YES;
	
	if (each != nil) {
		while (each != self && delayContentTouches) {
			if ([[each description] rangeOfString:@"<UIAutocorrectInlinePrompt"].location == 0) {
				delayContentTouches = NO;
			}
			each = each.superview;
		}
	}
    
	self.delaysContentTouches = delayContentTouches;
    
	return result;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (![self isFirstResponder]) return NO;
	
	if (action == @selector(cut:)) {
		return YES;
	} else if (action == @selector(copy:)) {
		return YES;
	} else if (action == @selector(paste:)) {
		return [[UIPasteboard generalPasteboard] valueForPasteboardType:(id)kUTTypeUTF8PlainText] != nil;
    } else if (action == @selector(delete:)) {
        return YES;
    }
    
    return NO;
}

- (IBAction)cut:(id)sender {
    [self.taskDelegate cut:sender];
}

- (IBAction)copy:(id)sender {
    [self.taskDelegate copy:sender];
}

- (IBAction)paste:(id)sender {
    [self.taskDelegate paste:sender];
}

- (IBAction)delete:(id)sender {
    [self.taskDelegate delete:sender];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[[UIMenuController sharedMenuController] setMenuVisible:NO];
	
	startTouchPosition = [[touches anyObject] locationInView:self];
	lastTouchPosition = startTouchPosition;
	
	if (!self.decelerating) {
		swipedRow = NSNotFound;
		draggedRow = NSNotFound;
		droppedRow = NSNotFound;
		[self performSelector:@selector(handleStartDrag) withObject:nil afterDelay:DRAG_START_DELAY];
		[(TaskViewController *)self.taskDelegate documentView:self touchAtPoint:startTouchPosition];
	}
    
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	lastTouchPosition = [[touches anyObject] locationInView:self];
	
	if (swipedRow != NSNotFound) {
		self.scrollEnabled = NO;
	} else if (draggedRow != NSNotFound) {
		[self maybeStartAutoscroll];
		[self processDrag];
	} else {
		if (fabsf(startTouchPosition.x - lastTouchPosition.x) >= SWIPE_DISTANCE) {
			swipedRow = [self rowAtPoint:startTouchPosition];
			if (swipedRow != NSNotFound) {
				if (startTouchPosition.x < lastTouchPosition.x) {
					[(id)self.taskDelegate documentView:self swipeRightFromPoint:startTouchPosition];
				} else {
					[(id)self.taskDelegate documentView:self swipeLeftFromPoint:startTouchPosition];
				}
			}
		}	
	}
	
	[super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    
	if (draggedRow != NSNotFound) {
		[(id)self.taskDelegate documentViewEndedDrag:self];
	} else {
		UITouch *touch = [touches anyObject];
		touchesEndedLocation = [touch locationInView:self];
		
		if ([touch tapCount] == 1) {
			[(TaskViewController *)self.taskDelegate documentView:self tapAtPoint:touchesEndedLocation];
		} else if([touch tapCount] == 2) {
			[(TaskViewController *)self.taskDelegate documentView:self doubleTapAtPoint:touchesEndedLocation];
		}
	}
	
	[self stopAutoscroll];
	self.scrollEnabled = YES;
	startTouchPosition = CGPointZero;
	lastTouchPosition = CGPointZero;
	swipedRow = NSNotFound;
	draggedRow = NSNotFound;
	droppedRow = NSNotFound;
	[dragIndicatorView removeFromSuperview];
	[super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    
	[self stopAutoscroll];
	self.scrollEnabled = YES;
	startTouchPosition = CGPointZero;
	lastTouchPosition = CGPointZero;
	swipedRow = NSNotFound;
	draggedRow = NSNotFound;
	droppedRow = NSNotFound;
	[dragIndicatorView removeFromSuperview];
	[super touchesCancelled:touches withEvent:event];
}


@synthesize padding;

- (void)setPadding:(UIEdgeInsets)newPadding {
	padding = newPadding;
	[self setNeedsLayout];
}


- (void)singleTapInMarginLocation:(CGFloat)yLocation isLeftMargin:(BOOL)isLeftMargin {
    IPhoneDocumentViewFieldEditor *editor = [IPhoneDocumentViewFieldEditor sharedInstance];
    if ([editor isFirstResponder]) {
        NSRange selection = [editor selectedRange];
		NSUInteger selectionStart = selection.location;
		NSUInteger selectionEnd = NSMaxRange(selection);
		NSUInteger length = [editor.text length];
		
		if (isLeftMargin) {
			if (selectionStart > 0) {
				selection.location = selectionStart - 1;
				selection.length = 0;
			} else {
				selection.length = 0;
			}
		} else {
			if (selectionEnd < length) {
				selection.location = selectionEnd + 1;
				selection.length = 0;
			} else {
				selection.length = 0;
			}
		}
		
		editor.scrollEnabled = NO;
		editor.selectedRange = selection;
		editor.scrollEnabled = YES;
    }
}

- (void)doubleTapInMarginLocation:(CGFloat)yLocation isLeftMargin:(BOOL)isLeftMargin {
    IPhoneDocumentViewFieldEditor *editor = [IPhoneDocumentViewFieldEditor sharedInstance];
	if ([editor isFirstResponder]) {
		NSRange selection = [editor selectedRange];
		NSUInteger selectionStart = selection.location;
		NSUInteger selectionEnd = NSMaxRange(selection);
		NSString *text = editor.text;
		NSUInteger length = [text length];
		
		if (isLeftMargin) {
			if (selectionStart > 0) {
				selection.location = [text nextWordFromIndex:selectionStart forward:NO];
				selection.length = 0;
			} else {
				selection.length = 0;
			}
		} else {
			if (selectionEnd < length) {
				selection.location = [text nextWordFromIndex:selectionEnd forward:YES];
				selection.length = 0;
			} else {
				selection.length = 0;
			}
		}
		
		editor.scrollEnabled = NO;
		editor.selectedRange = selection;
		editor.scrollEnabled = YES;
	} 
}

@end

@implementation TaskView (TaskViewPrivate)


- (void)validateRowDatasToRow:(NSUInteger)fixToRow {
	if (firstInvalidRowData == NSNotFound) return;
	if ([rowDatas count] == 0) return;
    if ([rowDatas count] != [self numberOfRows]) return;
    
	CGFloat rowWidth = self.frame.size.width;
	CGSize rowFitInSize = CGSizeMake(rowWidth, CGFLOAT_MAX);
	TaskViewController *documentViewController = (TaskViewController *) self.taskDelegate;
	NSUInteger end = MIN(fixToRow, [rowDatas count] - 1);
	RowData *lastValidRowData = firstInvalidRowData == 0 ? nil : [rowDatas objectAtIndex:firstInvalidRowData - 1];
	NSUInteger yOffset = lastValidRowData == nil ? SEARCH_BAR_HEIGHT + 5 : CGRectGetMaxY(lastValidRowData->rowRect);
	NSUInteger index = firstInvalidRowData;
	RowData *eachRowData;
    
    while (index <= end) {
		eachRowData = [rowDatas objectAtIndex:index];
		eachRowData->row = index;
		
		if (CGRectEqualToRect(eachRowData->rowRect, CGRectZero)) {
			IPhoneDocumentViewCell *cell = [documentViewController documentView:self cellForRow:index];
			eachRowData->rowRect = CGRectMake(0, yOffset, rowWidth, [cell sizeThatFits:rowFitInSize].height);
			eachRowData->lastRowRect = eachRowData->rowRect;
			[reusableCells addObject:cell];
		} else {
			eachRowData->lastRowRect = eachRowData->rowRect;
            IPhoneDocumentViewCell *cell = [documentViewController documentView:self cellForRow:index];
            eachRowData->rowRect = CGRectMake(0, yOffset, rowWidth, [cell sizeThatFits:rowFitInSize].height);
		}
        
		yOffset += eachRowData->rowRect.size.height;
        
		index++;
	}
	
	firstInvalidRowData = index;
}

- (void)updatedFieldEditorForRow:(NSUInteger)row {
	if (row != NSNotFound) {
		IPhoneDocumentViewFieldEditor *editor = [IPhoneDocumentViewFieldEditor sharedInstance];
		Section *section = [self sectionForRow:row];
        if (section) {
            CGRect newFrame = CGRectInset([IPhoneDocumentViewCell textRectForSection:section inBounds:[self rectForRow:row]], -8, -8);
            
            if (!CGRectEqualToRect(editor.frame, newFrame)) {
                editor.frame = newFrame;
            }
            
            if (![editor.text isEqualToString:section.content]) {
                editor.text = section.content;
            }
            
            if (![editor.font isEqual:section.sectionFont]) {
                editor.font = section.sectionFont;
            }
            
            if (![editor.textColor isEqual:section.sectionColor]) {
                editor.textColor = section.sectionColor;
            }
            
            if (![editor.textColor isEqual:section.sectionColor]) {
                editor.textColor = section.sectionColor;
            }
            
            NSString *placeholder = [NSString stringWithFormat:NSLocalizedString(@"New %@", nil), [[section typeAsString] capitalizedString]];
            if (![placeholder isEqualToString:editor.placeholderText]) {
                editor.placeholderText = placeholder;
            }	
        }
	}
}

@end


@implementation RowData

+ (NSMutableArray *)rowDatasWithCapacity:(NSUInteger)capacity {
	NSMutableArray *rowDatas = [NSMutableArray arrayWithCapacity:capacity];
	for (NSUInteger i = 0; i < capacity; i++) {
		[rowDatas addObject:[[[RowData alloc] init] autorelease]];
	}
	return rowDatas;
}

- (id)init {
	self = [super init];
	row = NSNotFound;
	rowRect = CGRectZero;
	lastRowRect = CGRectZero;
	return self;
}

- (id)retain {
	return [super retain];
}

- (id)autorelease {
	return [super autorelease];
}

- (void)dealloc {
	//[cell release];
	cell.rowData = nil;
	[super dealloc];
}

@synthesize cell;

- (void)setCell:(IPhoneDocumentViewCell *)aCell {
	cell.rowData = nil;
	//[cell release];
	//cell = [aCell retain];
	cell = aCell;
	cell.rowData = self;
}

- (void)invalidateCachedRowRect {
	rowRect = CGRectZero;
}

@end


@implementation DragIndicatorView

- (id)init {
    self = [super init];
	if (self) {
		self.opaque = NO;
		self.userInteractionEnabled = NO;
	}
	return self;
}

- (void)setFrame:(CGRect)rect {
	[super setFrame:rect];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	[[TaskView selectionColor] set];
	
	CGRect bounds = self.bounds;
	bounds.size.width -= 8;
	
	CGRect circle = bounds;
	circle.size.width = DRAG_INDICATOR_HEIGHT;
	circle = CGRectInset(circle, DRAG_INDICATOR_STROKE / 2, DRAG_INDICATOR_STROKE / 2);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, DRAG_INDICATOR_STROKE);
	CGContextStrokeEllipseInRect(context, circle);
	
	bounds.origin.y += (NSInteger) ((bounds.size.height / 2) - (DRAG_INDICATOR_STROKE / 2));
	bounds.size.height = DRAG_INDICATOR_STROKE;
	bounds.origin.x += DRAG_INDICATOR_HEIGHT;
	bounds.size.width -= DRAG_INDICATOR_HEIGHT;
	UIRectFill(bounds);
}

@end

CGPoint midpointBetweenPoints(CGPoint a, CGPoint b) {
	CGFloat x = (a.x + b.x) / 2.0;
	CGFloat y = (a.y + b.y) / 2.0;
	return CGPointMake(x, y);
}

