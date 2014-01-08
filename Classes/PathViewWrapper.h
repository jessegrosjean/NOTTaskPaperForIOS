//
//  PathViewWrapper.h
//  PlainText
//
//  Created by Jesse Grosjean on 5/31/11.
//

#import <Foundation/Foundation.h>

@class PathView;
@class Button;

@interface PathViewWrapper : UIView {
	PathView *pathView;
	Button *popupMenuButton;
}

@property (nonatomic, readonly) PathView *pathView;
@property (nonatomic, readonly) Button *popupMenuButton;

@end
