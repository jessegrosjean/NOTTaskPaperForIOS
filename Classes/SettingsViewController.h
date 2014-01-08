//
//  SettingsViewController.h
//  PlainText
//
//  Created by Jesse Grosjean on 6/30/10.
//

#import "IFGenericTableViewController.h"


@interface SettingsViewController : IFGenericTableViewController {
}

+ (BOOL)showing;
+ (UINavigationController *)viewControllerForDisplayingSettings;

@end