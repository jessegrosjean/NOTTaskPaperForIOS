//
//  KeyboardAccessoryView.h
//  PlainText
//
//  Created by Jesse Grosjean on 4/21/11.
//


@interface KeyboardAccessoryView : UIImageView {
	UIResponder *target;
}

@property (nonatomic, assign) UIResponder *target;

@end
