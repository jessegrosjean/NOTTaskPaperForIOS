//
//  SearchView.h
//  PlainText
//
//  Created by Jesse Grosjean on 4/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HUDBackgroundView.h"


@class SearchTextField;

@interface HUDSearchView : HUDBackgroundView {
	SearchTextField *searchTextField;
}

@property(readonly, nonatomic) SearchTextField *searchTextField;

@end
