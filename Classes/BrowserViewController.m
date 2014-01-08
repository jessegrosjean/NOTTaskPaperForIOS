//
//  BrowserViewController.m
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//

#import "BrowserViewController.h"
#import "ApplicationViewController.h"
#import "NSFileManager_Additions.h"
#import "ApplicationController.h"
#import "PathViewController.h"
#import "ItemViewController.h"
#import "PathController.h"
#import "BrowserView.h"
#import "Titlebar.h"
#import "Button.h"
#import "MenuView.h"


@implementation BrowserViewController

- (void)toggleDocumentFocusModeAnimationWillStart:(id)sender {
    [[MenuView sharedInstance] closeIfShowing];
}

- (void)toggleDocumentFocusModeAnimationDidStop:(id)sender {
    if ([self.currentItemViewController respondsToSelector:@selector(toggleDocumentFocusModeAnimationDidStop:)]) {
        [self.currentItemViewController performSelector:@selector(toggleDocumentFocusModeAnimationDidStop:) withObject:sender];
    }
}

- (id)init {
	self = [super init];
	itemViewControllers = [[NSMutableArray alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pathsChangedNotification:) name:PathsChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollsHeadingsChanged:) name:ScrollsHeadingsChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleDocumentFocusModeAnimationWillStart:) name:DocumentFocusModeAnimationWillStart object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleDocumentFocusModeAnimationDidStop:) name:DocumentFocusModeAnimationDidStop object:nil];
    
    
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[itemViewControllers release];
    [super dealloc];
}

- (IBAction)back:(id)sender {
	[APP_VIEW_CONTROLLER openItem:[self.currentItemViewController.path stringByDeletingLastPathComponent] animated:YES];
}

- (BrowserView *)browserView {
	return (id) self.view;
}

- (void)loadView {
	BrowserView *browserView = [[[BrowserView alloc] init] autorelease];
	browserView.headerBarsScroll = APP_VIEW_CONTROLLER.scrollsHeadings;
	browserView.autoresizingMask= UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view = browserView;
}

- (void)setTitle:(NSString *)aTitle {
	[super setTitle:aTitle];
}

- (ItemViewController *)topItemViewController {
	if ([itemViewControllers count] > 0) {
		return [itemViewControllers objectAtIndex:0];
	}
	return nil;
}

- (ItemViewController *)currentItemViewController {
	return [itemViewControllers lastObject];
}

- (void)beginUpdates {
	updating++;
}

- (void)endUpdates:(BOOL)editingPath {
	updating--;
	if (updating == 0) {
		[self.browserView setViewController:[itemViewControllers lastObject] editingPath:editingPath animated:updatingIsAnimated isPush:updatingIsPush];

		if ([itemViewControllers count] > 1) {
			Button *back = [Button buttonWithImage:[UIImage imageNamed:@"back.png"] accessibilityLabel:NSLocalizedString(@"Back", nil) accessibilityHint:nil target:self action:@selector(back:) edgeInsets:UIEdgeInsetsMake(0, 5, 0, 10)];
			//back.brightness = 0.15;
			self.browserView.titlebar.leftButton = back;

            if (self.currentItemViewController.isFolderViewController) {
                self.browserView.titlebar.rightButton = nil;
            }
		} else {
			self.browserView.titlebar.leftButton = nil;		
            if (!IS_IPAD) {
                self.browserView.titlebar.rightButton = nil;
            }
		}
	}
}

- (void)push:(ItemViewController *)aViewController animated:(BOOL)animated {
	[self beginUpdates];
	[itemViewControllers addObject:aViewController];
	aViewController.parentViewController = self;
	updatingIsPush = YES;
	updatingIsAnimated = animated;
	[self endUpdates:NO];
}

- (ItemViewController *)pop:(BOOL)animated {
	[self beginUpdates];
	ItemViewController *aViewController = [[[itemViewControllers lastObject] retain] autorelease];
	[itemViewControllers removeLastObject];
	aViewController.parentViewController = nil;
	updatingIsPush = NO;
	updatingIsAnimated = animated;
	[self endUpdates:NO];
	return aViewController;
}

- (NSArray *)popToRoot:(BOOL)animated {
	[self beginUpdates];
	NSMutableArray *results = [NSMutableArray array];
	while ([itemViewControllers count] > 2) {
		[results insertObject:[self pop:NO] atIndex:0];
	}
	
	if ([itemViewControllers count] == 2) {
		[results insertObject:[self pop:animated] atIndex:0];
	}
	[self endUpdates:NO];

	return results;
}

- (void)scrollsHeadingsChanged:(NSNotification *)aNotification {
	self.browserView.headerBarsScroll = APP_VIEW_CONTROLLER.scrollsHeadings;
}

- (void)pathsChangedNotification:(NSNotification *)aNotification {
	NSDictionary *userInfo = [aNotification userInfo];	
	BOOL itemViewNeedsRefresh = NO;
	
	NSSet *removedPaths = [userInfo objectForKey:RemovedPathsKey];
	for (NSString *eachRemoved in removedPaths) {
		ItemViewController *currentItemViewController = self.currentItemViewController;
		NSString *currentPath = currentItemViewController.path;
		
		if (currentPath) {
			if ([currentPath rangeOfString:eachRemoved].location == 0) {
				if ([itemViewControllers count] == 1) {
					itemViewNeedsRefresh = YES;
				} else {
					itemViewNeedsRefresh = YES;
				}
			} else if ([currentPath isEqualToString:[eachRemoved stringByDeletingLastPathComponent]]) {
				itemViewNeedsRefresh = YES;
			}
		}
	}
			
	NSSet *movedPaths = [userInfo objectForKey:MovedPathsKey];
	for (NSDictionary *eachMoved in movedPaths) {
		ItemViewController *currentItemViewController = self.currentItemViewController;
		NSString *fromPath = [eachMoved objectForKey:FromPathKey];
		NSString *toPath = [eachMoved objectForKey:ToPathKey];
		NSString *currentPath = currentItemViewController.path;
		
		if ([fromPath isEqualToString:currentPath]) {
			currentItemViewController.path = toPath;
		} else if ([currentPath rangeOfString:fromPath].location == 0) {
			NSString *trailing = [currentPath stringByReplacingCharactersInRange:NSMakeRange(0, [fromPath length]) withString:@""];
			NSString *newPath = [toPath stringByAppendingPathComponent:trailing];
			currentItemViewController.path = newPath;
		} else if (currentItemViewController.isFolderViewController) {
			NSString *fromParent = [fromPath stringByDeletingLastPathComponent];
			NSString *toParent = [toPath stringByDeletingLastPathComponent];
			
			if ([fromParent isEqualToString:currentPath] || [toParent isEqualToString:currentPath]) {
				itemViewNeedsRefresh = YES;
			}
		}
	}
	
	NSSet *modifiedPaths = [userInfo objectForKey:ModifiedPathsKey];
	for (NSString *eachModified in modifiedPaths) {
		ItemViewController *currentItemViewController = self.currentItemViewController;
		NSString *modifiedParent = [eachModified stringByDeletingLastPathComponent];
		NSString *currentPath = currentItemViewController.path;
		
		if ([eachModified isEqualToString:currentPath]) {
			itemViewNeedsRefresh = YES;
		} else if (currentItemViewController.isFolderViewController && [currentPath isEqualToString:modifiedParent] ) {
			itemViewNeedsRefresh = YES;
		}
	}

	NSSet *createdPaths = [userInfo objectForKey:CreatedPathsKey];
	for (NSString *eachCreated in createdPaths) {
		ItemViewController *currentItemViewController = self.currentItemViewController;
		NSString *createdParent = [eachCreated stringByDeletingLastPathComponent];
		NSString *currentPath = currentItemViewController.path;
		
		if (currentItemViewController.isFolderViewController && [currentPath isEqualToString:createdParent]) {
			itemViewNeedsRefresh = YES;
		}
	}
	
	if (itemViewNeedsRefresh) {
		[self.currentItemViewController syncViewWithDisk:YES];
		//[self.currentItemViewController read:YES];
	}
}

@end
