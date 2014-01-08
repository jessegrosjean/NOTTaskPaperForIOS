//
//  ViewSettingsViewController.h
//  PlainText
//
//  Created by Jesse Grosjean on 4/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CMFontSelectTableViewController.h"
#import "IFGenericTableViewController.h"

@class IFLinkCellController;

@interface FontAndColorSettingsViewController : IFGenericTableViewController <UIActionSheetDelegate, CMFontSelectTableViewControllerDelegate> {
    IFLinkCellController *linkCell;
}
@end
