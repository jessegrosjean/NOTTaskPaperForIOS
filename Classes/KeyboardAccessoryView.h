//
//  KeyboardAccessoryView.h
//  PlainText
//
//  Created by Jesse Grosjean on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


@interface KeyboardAccessoryView : UIImageView {
	UIResponder *target;
}

@property (nonatomic, assign) UIResponder *target;

@end
