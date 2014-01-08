//
//  ViewSettingsViewController.h
//  PlainText
//
//  Created by Jesse Grosjean on 4/20/11.
//

#import "CMFontSelectTableViewController.h"
#import "IFGenericTableViewController.h"

@class IFLinkCellController;

@interface FontAndColorSettingsViewController : IFGenericTableViewController <UIActionSheetDelegate, CMFontSelectTableViewControllerDelegate> {
    IFLinkCellController *linkCell;
}
@end
