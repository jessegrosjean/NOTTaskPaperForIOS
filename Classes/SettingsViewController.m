//
//  SettingsViewController.m
//  PlainText
//
//  Created by Jesse Grosjean on 6/30/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "SettingsViewController.h"
#import "TextExpanderSettingsViewController.h"
#import "FontAndColorSettingsViewController.h"
#import "AdvancedSettingsViewController.h"
#import "DropboxSettingsViewController.h"
#import "ApplicationViewController.h"
#import "IFSwitchCellController.h"
#import "IFSwitchCellController.h"
#import "IFButtonCellController.h"
#import "HelpSectionController.h"
#import "IFSliderCellController.h"
#import "IFChoiceCellController.h"
#import "ApplicationController.h"
#import "IFTextCellController.h"
#import "IFLinkCellController.h"
#import "IFPreferencesModel.h"
#import "IFTemporaryModel.h"

@interface MyNavigationController : UINavigationController {
}
@end

@implementation MyNavigationController

static BOOL _showing;

+ (BOOL)showing {
    return _showing;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _showing = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    _showing = NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([APP_VIEW_CONTROLLER lockOrientation]) {
        if ([APP_VIEW_CONTROLLER lockedOrientation] == UIDeviceOrientationPortrait)
            return UIInterfaceOrientationMaskPortrait;
        else if ([APP_VIEW_CONTROLLER lockedOrientation] == UIInterfaceOrientationPortraitUpsideDown)
            return UIInterfaceOrientationMaskPortraitUpsideDown;
        else if ([APP_VIEW_CONTROLLER lockedOrientation] == UIInterfaceOrientationLandscapeLeft)
            return UIInterfaceOrientationMaskLandscapeLeft;
        else if ([APP_VIEW_CONTROLLER lockedOrientation] == UIInterfaceOrientationLandscapeRight)
            return UIInterfaceOrientationMaskLandscapeRight;
        else
            return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskAll;
}

- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated {
    if (animated) {
        [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:UIStatusBarAnimationSlide];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:UIStatusBarAnimationNone];
    }
	
	if (!IS_IPAD) {
		if (animated) {
			[UIView beginAnimations:nil context:NULL];
		}
		
		CGAffineTransform t = self.view.transform;
		UIInterfaceOrientation orientation = self.interfaceOrientation;
		BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
		
		CGRect goodBounds = [[UIScreen mainScreen] bounds];
		
		CGSize statusSize = [[UIApplication sharedApplication] statusBarFrame].size;
		CGSize statusSize_t = CGSizeApplyAffineTransform(statusSize, t); // discard status frame origin
		CGFloat statusHeight = fabs(statusSize_t.height);
		CGFloat statusHeight_t = statusSize_t.height; // discard status width
		
		// tricky part
		CGRect goodFrame = goodBounds;
		goodFrame.size.width -= isLandscape ? statusHeight : 0;
		goodFrame.size.height -= isLandscape ? 0 : statusHeight;
		CGRect goodFrame_t = CGRectApplyAffineTransform(goodFrame, t);
		self.view.bounds = CGRectMake(0, 0, goodFrame_t.size.width, goodFrame_t.size.height);
		
		CGFloat dx = isLandscape ? -statusHeight_t/2 : 0;
		CGFloat dy = isLandscape ? 0 : statusHeight_t/2;
		
		self.view.center = CGPointMake(goodBounds.size.width/2 + dx, goodBounds.size.height/2 + dy);
		
		if (animated) {
			[UIView commitAnimations];
		}		
	}
}

@end

@implementation SettingsViewController

+ (BOOL)showing {
    return [MyNavigationController showing];
}

+ (UINavigationController *)viewControllerForDisplayingSettings {
	UINavigationController *navigationController = [[[MyNavigationController alloc] init] autorelease];
	SettingsViewController *settingsViewController = [[[SettingsViewController alloc] init] autorelease];
	
	settingsViewController.model = [[[IFPreferencesModel alloc] init] autorelease];
	
	navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	
	if ([navigationController respondsToSelector:@selector(setModalPresentationStyle:)]) {
		navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	
	navigationController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	
	[navigationController pushViewController:settingsViewController animated:NO];
	
	return navigationController;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)loadView {
	[super loadView];
	self.title = NSLocalizedString(@"Settings", nil);
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
}

- (void)constructTableGroups {
	NSMutableArray *groupOneCells = [NSMutableArray array];
	NSMutableArray *groupTwoCells = [NSMutableArray array];
	NSMutableArray *groupThreeCells = [NSMutableArray array];
	NSString *processName = [[NSProcessInfo processInfo] processName];
	IFLinkCellController *linkCell;
	
	// Group 1
    NSString *versionKey = (id)kCFBundleVersionKey;
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:versionKey];
	IFTemporaryModel *tempModel = [[[IFTemporaryModel alloc] initWithDictionary:[NSDictionary dictionaryWithObject:version forKey:@"version"]] autorelease];
	IFTextCellController *textCell = [[[IFTextCellController alloc] initWithLabel:processName andPlaceholder:nil atKey:@"version" inModel:tempModel] autorelease];
	textCell.enabled = NO;
	[groupOneCells addObject:textCell];
	
	// Group 2
		
	linkCell = [[[IFLinkCellController alloc] initWithLabel:NSLocalizedString(@"Dropbox", nil) usingController:[[[DropboxSettingsViewController alloc] init] autorelease] inModel:model] autorelease];
	linkCell.image = [UIImage imageNamed:@"dropbox.png"];
	[groupTwoCells addObject:linkCell];

#if !defined(PLAINTEXT)
	linkCell = [[[IFLinkCellController alloc] initWithLabel:NSLocalizedString(@"Fonts & Colors", nil) usingController:[[[FontAndColorSettingsViewController alloc] init] autorelease] inModel:model] autorelease];
	linkCell.image = [UIImage imageNamed:@"fonts_small.png"];
	[groupTwoCells addObject:linkCell];
#endif
	
	linkCell = [[[IFLinkCellController alloc] initWithLabel:NSLocalizedString(@"TextExpander", nil) usingController:[[[TextExpanderSettingsViewController alloc] init] autorelease] inModel:model] autorelease];
	linkCell.image = [UIImage imageNamed:@"IconTEBarButton.png"];
	[groupTwoCells addObject:linkCell];
	
	linkCell = [[[IFLinkCellController alloc] initWithLabel:NSLocalizedString(@"Advanced", nil) usingController:[[[AdvancedSettingsViewController alloc] init] autorelease] inModel:model] autorelease];
	linkCell.image = [UIImage imageNamed:@"wand_small.png"];
	[groupTwoCells addObject:linkCell];

	linkCell = [[[IFLinkCellController alloc] initWithLabel:NSLocalizedString(@"Help", nil) usingController:[[[HelpSectionController alloc] init] autorelease] inModel:self.model] autorelease];
	linkCell.image = [UIImage imageNamed:@"question_small.png"];
	[groupTwoCells addObject:linkCell];
	
	// Group 3

#if !defined(WRITEROOM) && !defined(TASKPAPER)
	StoreController *storeController = [StoreController sharedInstance];
	if (![storeController isRemoveAdsFeaturePurchased]) {
		NSString *removeAdsButtonLabel = [storeController removeAdsButtonLabel];
		NSString *restoreRemoveAdsButtonLabel = [storeController restoreRemoveAdsButtonLabel];
		
		IFButtonCellController *removeButtonCell = [[[IFButtonCellController alloc] initWithLabel:removeAdsButtonLabel withAction:@selector(buyRemoveAds) onTarget:storeController] autorelease];
		[groupThreeCells addObject:removeButtonCell];
		
		IFButtonCellController *restoreButtonCell = [[[IFButtonCellController alloc] initWithLabel:restoreRemoveAdsButtonLabel withAction:@selector(restoreRemoveAds) onTarget:storeController] autorelease];
		[groupThreeCells addObject:restoreButtonCell];
	} else {
		IFSwitchCellController *switchCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Remove Ads", nil) atKey:RemoveAdsDefaultsKey inModel:self.model] autorelease];
		switchCell.updateTarget = self;
		switchCell.updateAction = @selector(removeAdsChanged);
		[groupThreeCells addObject:switchCell];
	}
    
    
    IFButtonCellController *privacyPolicyCell = [[[IFButtonCellController alloc] initWithLabel:@"Privacy Policy" withAction:@selector(privacyPolicy) onTarget:self] autorelease];
    [groupThreeCells addObject:privacyPolicyCell];
#endif
			
	tableGroups = [[NSArray arrayWithObjects:groupOneCells, groupTwoCells, groupThreeCells, nil] retain];
	tableHeaders = [[NSArray arrayWithObjects:@"", @"", @"", @"", nil] retain];
	tableFooters = [[NSArray arrayWithObjects:NSLocalizedString(@"Created by SOMEBODY", nil), @"", @"", @"", nil] retain];
}

- (void)privacyPolicy {
}

- (void)removeAdsChanged {
	APP_CONTROLLER.removeAdsEnabled = APP_CONTROLLER.removeAdsEnabled; // fire notification
}

@end