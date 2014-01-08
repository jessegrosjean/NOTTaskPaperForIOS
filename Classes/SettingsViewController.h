//
//  SettingsViewController.h
//  PlainText
//
//  Created by Jesse Grosjean on 6/30/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "IFGenericTableViewController.h"


@interface SettingsViewController : IFGenericTableViewController {
}

+ (BOOL)showing;
+ (UINavigationController *)viewControllerForDisplayingSettings;

@end