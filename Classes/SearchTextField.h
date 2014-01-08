//
//  SearchView.h
//  PlainText
//
//  Created by Jesse Grosjean on 12/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

@class Button;

@interface SearchTextField : UITextField {
	Button *searchWithNoDot;
	Button *searchWithDot;
}

- (void)updateLeftRightViews;

@end
