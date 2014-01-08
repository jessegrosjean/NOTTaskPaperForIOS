//
//  UIResponder_Additions.m
//  PlainText
//
//  Created by Jesse Grosjean on 5/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIResponder_Additions.h"


@implementation UIResponder (Additions)

- (void)pasteInsertText:(NSString*)text {
	// Get a refererence to the system pasteboard because that's
	// the only one @selector(paste:) will use.
	UIPasteboard* generalPasteboard = [UIPasteboard generalPasteboard];
	
	// Save a copy of the system pasteboard's items
	// so we can restore them later.
	NSArray* items = [generalPasteboard.items copy];
	
	// Set the contents of the system pasteboard
	// to the text we wish to insert.
	generalPasteboard.string = text;
	
	// Tell this responder to paste the contents of the
	// system pasteboard at the current cursor location.
	[self paste: self];
	
	// Restore the system pasteboard to its original items.
	generalPasteboard.items = items;
	
	// Free the items array we copied earlier.
	[items release];
}

@end
