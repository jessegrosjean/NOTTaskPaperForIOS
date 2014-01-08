//
//  HelpContentsController.h
//  Documents
//
//  Created by Jesse Grosjean on 1/21/10.
//

#import <UIKit/UIKit.h>
#import "IFGenericTableViewController.h"

@interface HelpSectionController : IFGenericTableViewController <UIWebViewDelegate> {
	NSString *subheaderPrefix;
	UIWebView *sectionWebView;
	UITableViewCell *sectionWebViewTableViewCell;
	BOOL sectionWebViewLoaded;
	NSMutableArray *subheaders;
}

- (id)initWithTitle:(NSString *)aTitle subheaderPrefix:(NSString *)subheaderPrefix htmlTextContent:(NSString *)htmlTextContent;

@end
