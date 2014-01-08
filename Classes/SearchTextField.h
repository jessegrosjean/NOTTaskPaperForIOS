//
//  SearchView.h
//  PlainText
//
//  Created by Jesse Grosjean on 12/23/10.
//

@class Button;

@interface SearchTextField : UITextField {
	Button *searchWithNoDot;
	Button *searchWithDot;
}

- (void)updateLeftRightViews;

@end
