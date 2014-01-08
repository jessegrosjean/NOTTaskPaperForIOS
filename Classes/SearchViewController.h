//
//  SearchViewController.h
//  PlainText
//
//  Created by Jesse Grosjean on 12/23/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "TextFieldViewController.h"

@class Button;
@class SearchView;
@class SearchViewController;

@protocol SearchViewControllerDelegate <NSObject>
- (void)searchViewTextDidChange:(SearchViewController *)aSearchViewController;
@end

@interface SearchViewController : TextFieldViewController {
	Button *beginSearchButton;
}

@property (nonatomic, readonly) SearchView *searchView;
@property (nonatomic, readonly) Button *beginSearchButton;

- (void)updateSearchText:(NSString *)newSearchText;
- (void)notifiySearchFieldChangedAfterDelay:(NSNumber *)delayNumber;

@end
