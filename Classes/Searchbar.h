//
//  SearchBar.h
//  PlainText
//
//  Created by Jesse Grosjean on 10/14/10.
//

#import <Foundation/Foundation.h>

#import "Bar.h"

@class SearchView;

@interface Searchbar : Bar {
	SearchView *searchView;
    UIButton *rightButton;
    UIButton *leftButton;
	CGFloat originalRightWidth;
	UIEdgeInsets originalRightInsets;
    CGFloat originalLeftWidth;
	UIEdgeInsets originalLeftInsets;
}

@property (nonatomic, retain) SearchView *searchView;

@property (nonatomic, retain) UIButton *rightButton;
@property (nonatomic, retain) UIButton *leftButton;


@end
