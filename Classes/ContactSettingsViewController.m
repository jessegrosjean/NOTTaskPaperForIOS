//
//  ContactSettingsViewController.m
//  PlainText
//
//  Created by Jesse Grosjean on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ContactSettingsViewController.h"
#import "IFButtonCellController.h"

@implementation ContactSettingsViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAction:)] autorelease];		
}

- (void)constructTableGroups {
	NSMutableArray *groupOneCells = [NSMutableArray array];
	NSMutableArray *groupTwoCells = [NSMutableArray array];
    
    //Group One
	IFButtonCellController *emailDeveloperCell = [[[IFButtonCellController alloc] initWithLabel:@"Forums" withAction:@selector(forums) onTarget:self] autorelease];
	emailDeveloperCell.textAlignment = UITextAlignmentLeft;
	[groupOneCells addObject:emailDeveloperCell];	

	IFButtonCellController *followDeveloperCell = [[[IFButtonCellController alloc] initWithLabel:@"Twitter" withAction:@selector(twitter) onTarget:self] autorelease];
	followDeveloperCell.textAlignment = UITextAlignmentLeft;
	[groupOneCells addObject:followDeveloperCell];    

	IFButtonCellController *visitCell = [[[IFButtonCellController alloc] initWithLabel:@"Website" withAction:@selector(website) onTarget:self] autorelease];
	visitCell.textAlignment = UITextAlignmentLeft;
	[groupOneCells addObject:visitCell];	

    //Group Two
	
	IFButtonCellController *bubblesCell = [[[IFButtonCellController alloc] initWithLabel:@"Bubbles iOS" withAction:@selector(bubbles) onTarget:self] autorelease];
	bubblesCell.textAlignment = UITextAlignmentLeft;
	[groupTwoCells addObject:bubblesCell];	
	
	IFButtonCellController *markdownNoteCell = [[[IFButtonCellController alloc] initWithLabel:@"PlainText iOS" withAction:@selector(plainText) onTarget:self] autorelease];
	markdownNoteCell.textAlignment = UITextAlignmentLeft;
	[groupTwoCells addObject:markdownNoteCell];	
	
	IFButtonCellController *taskPaperiOSCell = [[[IFButtonCellController alloc] initWithLabel:@"TaskPaper iOS+Mac" withAction:@selector(taskPaper) onTarget:self] autorelease];
	taskPaperiOSCell.textAlignment = UITextAlignmentLeft;
	[groupTwoCells addObject:taskPaperiOSCell];	
    
	IFButtonCellController *textileNoteCell = [[[IFButtonCellController alloc] initWithLabel:@"WriteRoom iOS+Mac" withAction:@selector(writeRoom) onTarget:self] autorelease];
	textileNoteCell.textAlignment = UITextAlignmentLeft;
	[groupTwoCells addObject:textileNoteCell];	
        
	IFButtonCellController *quickCursorCell = [[[IFButtonCellController alloc] initWithLabel:@"QuickCursor Mac" withAction:@selector(quickCursor) onTarget:self] autorelease];
	quickCursorCell.textAlignment = UITextAlignmentLeft;
	[groupTwoCells addObject:quickCursorCell];	
    
    tableGroups = [[NSArray arrayWithObjects: groupOneCells, groupTwoCells, nil] retain];
	tableHeaders = [[NSArray arrayWithObjects:@"", @"Our Apps", nil] retain];	
	tableFooters = [[NSArray arrayWithObjects:@"", @"", nil] retain];
	
}


- (IBAction)website {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.hogbaysoftware.com/"]];	
}


- (IBAction)twitter {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/jessegrosjean"]];	
}

- (IBAction)forums {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.hogbaysoftware.com/support"]];	
}

- (IBAction)taskPaper {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.hogbaysoftware.com/products/taskpaper"]];	
}

- (IBAction)writeRoom {
 	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.hogbaysoftware.com/products/writeroom"]];       
}

- (IBAction)plainText {
 	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.hogbaysoftware.com/products/plaintext"]];       
}

- (IBAction)bubbles {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.hogbaysoftware.com/products/bubbles"]];           
}

- (IBAction)quickCursor {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.hogbaysoftware.com/products/quickcursor"]];	
}

@end