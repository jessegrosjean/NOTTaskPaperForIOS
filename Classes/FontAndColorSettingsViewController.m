//
//  ViewSettingsViewController.m
//  PlainText
//
//  Created by Jesse Grosjean on 4/20/11.
//

#import "FontAndColorSettingsViewController.h"
#import "CMFontSelectTableViewController.h"
#import "ApplicationViewController.h"
#import "IFChoiceCellController.h"
#import "IFUpDownCellController.h"
#import "IFSwitchCellController.h"
#import "IFSliderCellController.h"
#import "PasscodeViewController.h"
#import "ApplicationController.h"
#import "IFColorCellController.h"
#import "IFTextCellController.h"
#import "IFLinkCellController.h"
#import "UIView_Additions.h"
#import "PathController.h"

#ifdef TASKPAPER
#import "TaskViewController.h"
#endif

@implementation FontAndColorSettingsViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
}

- (void)constructTableGroups {
	NSMutableArray *groupOneCells = [NSMutableArray array];
	NSMutableArray *groupTwoCells = [NSMutableArray array];
	NSMutableArray *groupThreeCells = [NSMutableArray array];
	
	CMFontSelectTableViewController *fontSelectViewController = [[[CMFontSelectTableViewController alloc] init] autorelease];
	////fontSelectViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
	fontSelectViewController.delegate = self;
    linkCell = [[[IFLinkCellController alloc] initWithLabel:NSLocalizedString(@"Font", nil) usingController:(id)fontSelectViewController inModel:self.model] autorelease];
	linkCell.choice = [self.model objectForKey:FontNameDefaultsKey];
	[groupOneCells addObject:linkCell];

	//fontSelectViewController = [[[CMFontSelectTableViewController alloc] init] autorelease];
	////fontSelectViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
	//fontSelectViewController.delegate = self;
	//linkCell = [[[IFLinkCellController alloc] initWithLabel:NSLocalizedString(@"Printing Font", nil) usingController:(id)fontSelectViewController inModel:self.model] autorelease];
	//linkCell.choice = [self.model objectForKey:FontNameDefaultsKey];
	//[groupOneCells addObject:linkCell];

	NSNumberFormatter *pointFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	IFUpDownCellController *upDownCell = [[[IFUpDownCellController alloc] initWithLabel:NSLocalizedString(@"Font Size", nil) stepValue:1.0 minValue:8 maxValue:36 valueFormatter:pointFormatter units:@"pt" atKey:FontSizeDefaultsKey inModel:self.model] autorelease];
	upDownCell.updateTarget = self;
	upDownCell.updateAction = @selector(refreshViewFromDefaults:);
	[groupOneCells addObject:upDownCell];
	
#ifndef TASKPAPER
	NSNumberFormatter *lineHeightFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[lineHeightFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	upDownCell = [[[IFUpDownCellController alloc] initWithLabel:NSLocalizedString(@"Line Spacing", nil) stepValue:0.1 minValue:0.5 maxValue:2.0 valueFormatter:lineHeightFormatter units:@"" atKey:LineHeightMultipleDefaultsKey inModel:self.model] autorelease];
	upDownCell.updateTarget = self;
	upDownCell.updateAction = @selector(refreshViewFromDefaults:);
	[groupOneCells addObject:upDownCell];
#endif
	
	IFColorCellController *colorCellController = [[[IFColorCellController alloc] initWithLabel:NSLocalizedString(@"Text Color", nil) atKey:InkColorDefaultsKey inModel:self.model] autorelease];
	colorCellController.updateTarget = self;
	colorCellController.updateAction = @selector(textColorChanged:);
	[groupTwoCells addObject:colorCellController];
	
	colorCellController = [[[IFColorCellController alloc] initWithLabel:NSLocalizedString(@"Background Color", nil) atKey:PaperColorDefaultsKey inModel:self.model] autorelease];
	colorCellController.updateTarget = self;
	colorCellController.updateAction = @selector(backgroundColorChanged:);
	[groupTwoCells addObject:colorCellController];
	
	IFSwitchCellController *tintCursorCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"Tint Text Cursor", nil) atKey:TintCursorDefaultsKey inModel:self.model] autorelease];
	tintCursorCell.updateTarget = self;
	tintCursorCell.updateAction = @selector(tintCursorChanged:);
	[groupTwoCells addObject:tintCursorCell];
	
	IFSliderCellController *sliderCell = [[[IFSliderCellController alloc] initWithLabel:NSLocalizedString(@"Brightness", nil) minValue:0.2 maxValue:1.0 atKey:ScreenBrightnessDefaultsKey inModel:self.model] autorelease];
	sliderCell.updateTarget = self;
	sliderCell.updateAction = @selector(screenBrightnessChanged:);
	[groupThreeCells addObject:sliderCell];

	sliderCell = [[[IFSliderCellController alloc] initWithLabel:NSLocalizedString(@"Interface Tint", nil) minValue:0.5 maxValue:3.0 atKey:SecondaryBrightnessDefaultsKey inModel:self.model] autorelease];
	sliderCell.updateTarget = self;
	sliderCell.updateAction = @selector(secondaryBrightnessChanged:);
	[groupThreeCells addObject:sliderCell];

	tableGroups = [[NSArray arrayWithObjects:groupOneCells, groupTwoCells, groupThreeCells, nil] retain];
	tableHeaders = [[NSArray arrayWithObjects:@"", @"", @"", nil] retain];	
	tableFooters = [[NSArray arrayWithObjects:@"", @"", @"", nil] retain];	
}

- (void)refreshViewFromDefaults:(id)sender {
    self.clearDefaultsCaches = YES;
    ((CMFontSelectTableViewController *)linkCell.controller).clearDefaultsCaches = YES;
}

- (void)textColorChanged:(ColorPickerViewController *)sender {
	sender.previewLabel.textColor = sender.color;
	[sender.previewLabel setNeedsDisplay];
    self.clearDefaultsCaches = YES;
	sender.previewLabel.backgroundColor = APP_VIEW_CONTROLLER.paperColor;
	sender.previewLabel.font = APP_VIEW_CONTROLLER.font;
}

- (void)backgroundColorChanged:(ColorPickerViewController *)sender {
	sender.previewLabel.backgroundColor = sender.color;
	[sender.previewLabel setNeedsDisplay];
    self.clearDefaultsCaches = YES;
	sender.previewLabel.textColor = APP_VIEW_CONTROLLER.inkColor;
	sender.previewLabel.font = APP_VIEW_CONTROLLER.font;
}

- (void)tintCursorChanged:(UISwitch *)sender {
	[APP_VIEW_CONTROLLER setTintCursor:sender.on];
}

- (void)fontSelectTableViewController:(CMFontSelectTableViewController *)fontSelectTableViewController didSelectFont:(UIFont *)selectedFont {
	[self.model setObject:[selectedFont fontName] forKey:FontNameDefaultsKey];
    linkCell.choice = [selectedFont fontName];
	[self refreshViewFromDefaults:nil];
}

- (void)screenBrightnessChanged:(id)sender {
	[APP_CONTROLLER setBrightness:[(UISlider *)sender value]];
}

- (void)secondaryBrightnessChanged:(id)sender {
    self.clearDefaultsCaches = YES;
	//[APP_CONTROLLER setBrightness:[(UISlider *)sender value]];
}



@end