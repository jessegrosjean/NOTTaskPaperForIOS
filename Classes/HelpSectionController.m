//
//  HelpContentsController.m
//  Documents
//
//  Created by Jesse Grosjean on 1/21/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "HelpSectionController.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "NSString_Additions.h"

@interface MyWebView : UIWebView { } @end

@implementation HelpSectionController

- (id)init {
	NSString *markdownText = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Help" ofType:@"markdown"] encoding:NSUTF8StringEncoding error:NULL];
	NSString *htmlText = [NSString stringWithFormat:@"<html>%@</html>", [markdownText markdownToHTML]];
	htmlText = [htmlText substringFromIndex:6];
	htmlText = [htmlText substringToIndex:[htmlText length] - 7];
	return [self initWithTitle:NSLocalizedString(@"Help", nil) subheaderPrefix:@"<h1>" htmlTextContent:htmlText];
}

- (id)initWithTitle:(NSString *)aTitle subheaderPrefix:(NSString *)aPrefix htmlTextContent:(NSString *)htmlTextContent {
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		self.title = aTitle;

		NSMutableString *sectionText = [NSMutableString string];

		subheaders = [[NSMutableArray array] retain];
		subheaderPrefix = [aPrefix retain];
        
		for (NSString *each in [htmlTextContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
			if ([each hasPrefix:subheaderPrefix]) {
				each = [each substringFromIndex:4];
				each = [each substringToIndex:[each length] - 5];
				each = [each stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"]; // HACK!!!
				[subheaders addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:each, @"title", [NSMutableString string], @"htmlText", nil]];
			} else {
				if ([subheaders count] > 0) {
					[[[subheaders lastObject] objectForKey:@"htmlText"] appendString:[NSString stringWithFormat:@"\n%@", each]];
				} else {
					if ([each length] > 0) {
						[sectionText appendFormat:@"\n%@", each];
					}
				}
			}
		}

		sectionText = [[[sectionText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy] autorelease];
		
		if ([sectionText length] > 0) {
			NSString *helpTemplatePath = [[NSBundle mainBundle] pathForResource:@"HelpPageTemplate" ofType:@"html"];
			NSMutableString *helpTemplate = [NSMutableString stringWithContentsOfFile:helpTemplatePath encoding:NSUTF8StringEncoding error:nil];
			
			[helpTemplate replaceOccurrencesOfString:@"PAGE_TITLE" withString:aTitle options:0 range:NSMakeRange(0, [helpTemplate length])];
			[helpTemplate replaceOccurrencesOfString:@"PAGE_BODY" withString:sectionText options:0 range:NSMakeRange(0, [helpTemplate length])];
			
			NSString *basePath = [helpTemplatePath stringByDeletingLastPathComponent];
			basePath = [basePath stringByReplacingOccurrencesOfString:@"/" withString:@"//"];
			basePath = [basePath stringByReplacingOccurrencesOfString:@" " withString:@"%20"];

			sectionWebViewTableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
			sectionWebView = [[MyWebView alloc] initWithFrame:sectionWebViewTableViewCell.frame];
			sectionWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			sectionWebView.delegate = self;
			sectionWebView.backgroundColor = [UIColor clearColor];
			sectionWebView.opaque = NO;
			[sectionWebView loadHTMLString:helpTemplate baseURL:[NSURL fileURLWithPath:basePath]];
			[sectionWebViewTableViewCell.contentView addSubview:sectionWebView];

			sectionWebViewTableViewCell.clipsToBounds = NO;
			sectionWebViewTableViewCell.contentView.clipsToBounds = NO;
			
			UIScrollView *innerScroller = [[sectionWebView subviews] lastObject];
			if ([innerScroller respondsToSelector:@selector(setScrollEnabled:)]) {
				innerScroller.scrollEnabled = NO;
			}
		}
	}
	return self;
}

- (void)dealloc {
	self.tableView.delegate = nil;
	self.tableView.dataSource = nil;
	sectionWebView.delegate = nil;
	[sectionWebView release];
	[subheaderPrefix release];
	[subheaders release];
	[sectionWebViewTableViewCell release];
    [super dealloc];
}

- (void)loadView {	
	[super loadView];
	//self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated {
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
	[super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([APP_VIEW_CONTROLLER lockOrientation]) {
		return interfaceOrientation == [APP_VIEW_CONTROLLER lockedOrientation];
	} else {
		return YES;
	}
}

- (IBAction)dismissModalViewControllerAction:(id)sender {
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (sectionWebView) {
		if (sectionWebViewLoaded) {
			return [subheaders count] + 1;
		} else {
			return 0;
		}
	}
	return [subheaders count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (sectionWebView && indexPath.row == 0) {
		sectionWebViewTableViewCell.frame = tableView.frame;
		NSString *offsetHeight = [sectionWebView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"];
		return [[[[[NSNumberFormatter alloc] init] autorelease] numberFromString:offsetHeight] integerValue] - 36;
	}
	return tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {	
	static NSString *HeaderCellIdentifier = @"HeaderCellIdentifier";	
	
	if (sectionWebViewTableViewCell && indexPath.row == 0) {
		return sectionWebViewTableViewCell;
	} else {
		UITableViewCell *cell = (id) [tableView dequeueReusableCellWithIdentifier:HeaderCellIdentifier];
		
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:HeaderCellIdentifier] autorelease];
		}
		
		if (sectionWebViewTableViewCell) {
			cell.textLabel.text = [[subheaders objectAtIndex:[indexPath row] - 1] objectForKey:@"title"];
		} else {
			cell.textLabel.text = [[subheaders objectAtIndex:[indexPath row]] objectForKey:@"title"];
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		return cell;
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0 && sectionWebViewTableViewCell != nil) {
		return nil;
	}
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *selection;
	
	if (sectionWebViewTableViewCell) {
		selection = [subheaders objectAtIndex:[indexPath row] - 1];
	} else {
		selection = [subheaders objectAtIndex:[indexPath row]];
	}
	
	if ([subheaderPrefix isEqualToString:@"<h1>"]) {
		[self.navigationController pushViewController:[[[HelpSectionController alloc] initWithTitle:[selection objectForKey:@"title"] subheaderPrefix:@"<h2>" htmlTextContent:[selection objectForKey:@"htmlText"]] autorelease] animated:YES];
	} else {
		[self.navigationController pushViewController:[[[HelpSectionController alloc] initWithTitle:[selection objectForKey:@"title"] subheaderPrefix:@"none" htmlTextContent:[selection objectForKey:@"htmlText"]] autorelease] animated:YES];
	}
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	sectionWebViewLoaded = YES;
	[self.tableView reloadData];
	[self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0];
}
				
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeOther)
		return YES;
	
	[[UIApplication sharedApplication] openURL:[request URL]];
	
	return NO;
}

@end

@implementation MyWebView

/*
- (void)setFrame:(CGRect)frame {
	if (!CGRectEqualToRect([self frame], frame)) {
		[super setFrame:frame];
		UITableView *tableView = (id) self;
		while (tableView != nil && ![tableView isKindOfClass:[UITableView class]]) {
			tableView = (id) [tableView superview];
		}
	}
}*/

@end