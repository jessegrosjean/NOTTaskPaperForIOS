//
//  DropboxSettingsViewController.h
//  PlainText
//
//  Created by Jesse Grosjean on 4/20/11.
//

#import "IFGenericTableViewController.h"
#import <DropboxSDK/DropboxSDK.h>


@interface DropboxSettingsViewController : IFGenericTableViewController <UIActionSheetDelegate> {
	NSString *dropboxPassword;
    NSString *relinkUserId;
}
@end