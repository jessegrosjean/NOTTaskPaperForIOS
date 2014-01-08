//
//  MenuView.m
//
//  Created by Jesse Grosjean on 10/22/09.
//  Copyright 2009 Hog Bay Software. All rights reserved.
//

#import "MenuView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "UIView_Additions.h"
#import "FolderViewCellSelectedBackground.h"


@interface SeparatorMenuViewCell : UITableViewCell {
}
@end

@implementation MenuView

+ (id)sharedInstance {
	static id sharedInstance = nil;
	if (sharedInstance == nil) {
		sharedInstance = [[self alloc] init];
	}
	return sharedInstance;
}

- (void)refreshFromDefaults {
	[super refreshFromDefaults];
	menuItemsTableView.rowHeight = (NSInteger)([APP_VIEW_CONTROLLER leading] * 1.3);
	[menuItemsTableView reloadData];
	[self setNeedsLayout];
}

- (id)init {
	self = [super init];
	if (self) {
		[self refreshFromDefaults];		
		self.borderInset = CGSizeMake(-10, -10);
		items = [[NSMutableArray alloc] init];
		selectedItems = [[NSMutableArray alloc] init];
 	}
	return self;
}

- (void)dealloc {
	menuItemsTableView.delegate = nil;
	menuItemsTableView.dataSource = nil;
	[items release];
	[selectedItems release];
	[menuItemsTableView release];
	[super dealloc];
}

- (void)show {
	//[APP_VIEW_CONTROLLER hideKeyboard]; //need to find out the side effect of no hiding
	[super show];
}


- (UIView *)hudView {
	return self.menuItemTableView;
}

- (UITableView *)menuItemTableView {
	if (!menuItemsTableView) {
		menuItemsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
		menuItemsTableView.alwaysBounceVertical = NO;
		menuItemsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		menuItemsTableView.dataSource = self;
		menuItemsTableView.delegate = self;

		menuItemsTableView.backgroundColor = [UIColor clearColor];
		menuItemsTableView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
        menuItemsTableView.scrollEnabled = YES;
	}
	return menuItemsTableView;
}

@synthesize items;

- (void)setItems:(NSArray *)itemsArray {
	[self removeAllItems];
	[items addObjectsFromArray:itemsArray];
}

@synthesize selectedItems;

- (void)setSelectedItems:(NSArray *)itemsArray {
	[selectedItems removeAllObjects];
	[selectedItems addObjectsFromArray:itemsArray];
}

- (void)addItem:(MenuViewItem *)anItem {
	[items addObject:anItem];
}

- (void)removeItemAtIndex:(NSUInteger)index {
	[items removeObjectAtIndex:index];
}

- (void)removeAllItems {
	[items removeAllObjects];
	[menuItemsTableView reloadData];
}

@synthesize target;
@synthesize action;
@synthesize longPressAction;

- (MenuViewItem *)longPressItem {
    return [items objectAtIndex:longPressItemIndex];
}

- (void)didClose {
	[self removeAllItems];
	[super didClose];
}

- (void)layoutSubviews {
	CGRect menuFrame = CGRectMake(0, 0, 0, 0);
	UIFont *font = [APP_VIEW_CONTROLLER font];
	
	for (MenuViewItem *each in items) {
		CGFloat eachWidth = [each.text sizeWithFont:font].width;
		eachWidth += (each.indentationLevel * 10) + 30;
		if (each.checked) {
			eachWidth += 16;
		}
		menuFrame.size.width = menuFrame.size.width < eachWidth ? eachWidth : menuFrame.size.width;
	}
	
	for (NSUInteger i = 0; i < [menuItemsTableView numberOfRowsInSection:0]; i++) {
		menuFrame.size.height += [self tableView:menuItemsTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
	}
	
	if (menuFrame.size.width > 320) {
		menuFrame.size.width = 320;
	}
	
	hudViewFrame = menuFrame;

	[super layoutSubviews];
}

#pragma mark TableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [items count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	MenuViewItem *item = [items objectAtIndex:indexPath.row];
	if (item.separator) {
		return 10.0;
	} else {
		return tableView.rowHeight;
	}		
}

- (UIEdgeInsets)padding {
	return UIEdgeInsetsMake(0, 1, 0, 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	static NSString *SeparatorCellIdentifier = @"SeparatorCell";
		
	UITableViewCell *cell = nil;
	
	MenuViewItem *item = [items objectAtIndex:indexPath.row];
	if (item.separator) {
		cell = [tableView dequeueReusableCellWithIdentifier:SeparatorCellIdentifier];
		
		if (cell == nil) {
			cell = [[[SeparatorMenuViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SeparatorCellIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;		
		}
		
		cell.backgroundColor = [APP_VIEW_CONTROLLER paperColor];
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.selectedBackgroundView = [[[UIView alloc] initWithFrame:cell.frame] autorelease];
            UILongPressGestureRecognizer *longPress = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)] autorelease];
            [cell addGestureRecognizer:longPress];
		}
		
		cell.textLabel.font = [APP_VIEW_CONTROLLER font];
		cell.textLabel.text = item.text;
		cell.backgroundColor = [APP_VIEW_CONTROLLER paperColor];
		cell.indentationLevel = item.indentationLevel;
		cell.selectedBackgroundView.backgroundColor = [APP_VIEW_CONTROLLER inkColor];
		
		if (item.enabled) {
			cell.textLabel.textColor = [APP_VIEW_CONTROLLER inkColor];
			cell.textLabel.highlightedTextColor = [APP_VIEW_CONTROLLER paperColor];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;		
		} else {
			cell.textLabel.textColor = [APP_VIEW_CONTROLLER inkColorByPercent:0.5];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;		
		}
		
		if (item.checked) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	MenuViewItem *item = [items objectAtIndex:indexPath.row];
	if (item.enabled) {
		[selectedItems addObject:item];
		[target performSelector:action withObject:self];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	MenuViewItem *item = [items objectAtIndex:indexPath.row];
	if (item.enabled) {
		[selectedItems removeObject:[items objectAtIndex:indexPath.row]];
		[target performSelector:action withObject:self];
	}
}

-(void)handleLongPress: (UIGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        CGPoint pressPoint = [longPress locationInView:menuItemsTableView];
        NSIndexPath *indexPath = [menuItemsTableView indexPathForRowAtPoint:pressPoint];
        longPressItemIndex = indexPath.row;
        MenuViewItem *item = [items objectAtIndex:longPressItemIndex];
        if (item.enabled && longPressAction) {
            [target performSelector:longPressAction withObject:self];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}
 
@end

@implementation MenuViewItem

+ (id)separatorItem {
	MenuViewItem *separatorItem = [self menuViewItem:@"" indentationLevel:0 enabled:NO];
	separatorItem.separator = YES;
	return separatorItem;
}

+ (id)menuViewItem:(NSString *)aString indentationLevel:(NSInteger)aLevel enabled:(BOOL)aBool {
	return [[[self alloc] initMenuViewItem:aString indentationLevel:aLevel enabled:aBool checked:NO userData:nil] autorelease];
}

+ (id)menuViewItem:(NSString *)aString indentationLevel:(NSInteger)aLevel enabled:(BOOL)anEnabled checked:(BOOL)aChecked userData:(id)aUserData {
	return [[[self alloc] initMenuViewItem:aString indentationLevel:aLevel enabled:anEnabled checked:aChecked userData:aUserData] autorelease];
}

- (id)initMenuViewItem:(NSString *)aString indentationLevel:(NSInteger)aLevel enabled:(BOOL)anEnabled checked:(BOOL)aChecked userData:(id)aUserData {
	self = [super init];
	self.enabled = anEnabled;
	self.checked = aChecked;
	self.text = aString;
	self.indentationLevel = aLevel;
	self.userData = aUserData;
	return self;
}

- (void)dealloc {
	[text release];
	[userData release];
	[super dealloc];
}

@synthesize enabled;
@synthesize checked;
@synthesize separator;
@synthesize text;
@synthesize indentationLevel;
@synthesize userData;

@end

@implementation SeparatorMenuViewCell

- (void)drawRect:(CGRect)aRect {
	CGRect bounds = self.bounds;
	bounds.origin.x += 1;
	bounds.size.width -= 2;
	bounds.origin.y = CGRectGetMidY(bounds);
	bounds.size.height = 1;
	[[APP_VIEW_CONTROLLER inkColorByPercent:0.15] set];
	UIRectFill(bounds);
}

@end