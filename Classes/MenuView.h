//
//  MenuView.h
//
//  Created by Jesse Grosjean on 10/22/09.
//


#import "HUDBackgroundView.h"

@class MenuViewItem;

@interface MenuView : HUDBackgroundView <UITableViewDelegate, UITableViewDataSource> {
	UITableView *menuItemsTableView;
	NSMutableArray *selectedItems;
	NSMutableArray *items;
	id target;
	SEL action;
    SEL longPressAction;
    NSUInteger longPressItemIndex;
}

+ (id)sharedInstance;

@property(nonatomic, readonly) UITableView *menuItemTableView;
@property(nonatomic, retain) NSArray *selectedItems;
@property(nonatomic, readonly) NSArray *items;
@property(nonatomic, readonly) MenuViewItem *longPressItem;

- (void)addItem:(MenuViewItem *)anItem;
- (void)removeItemAtIndex:(NSUInteger)index;
- (void)removeAllItems;

@property(assign, nonatomic) id target;
@property(assign, nonatomic) SEL action;
@property(assign, nonatomic) SEL longPressAction;

@end

@interface MenuViewItem : NSObject {
	BOOL enabled;
	BOOL checked;
	BOOL separator;
	NSString *text;
	NSInteger indentationLevel;
	id userData;
}

+ (id)separatorItem;
+ (id)menuViewItem:(NSString *)aString indentationLevel:(NSInteger)aLevel enabled:(BOOL)aBool;
+ (id)menuViewItem:(NSString *)aString indentationLevel:(NSInteger)aLevel enabled:(BOOL)anEnabled checked:(BOOL)aChecked userData:(id)aUserData;

- (id)initMenuViewItem:(NSString *)aString indentationLevel:(NSInteger)aLevel enabled:(BOOL)anEnabled checked:(BOOL)aChecked userData:(id)aUserData;

@property(assign, nonatomic) BOOL enabled;
@property(assign, nonatomic) BOOL checked;
@property(assign, nonatomic) BOOL separator;
@property(retain, nonatomic) NSString *text;
@property(assign, nonatomic) NSInteger indentationLevel;
@property(retain, nonatomic) id userData;

@end
