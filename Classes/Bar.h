//
//  Bar.h
//  PlainText
//
//  Created by Jesse Grosjean on 10/14/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Bar : UIView {
	UIEdgeInsets padding;
	UIView *topDivider;
	UIView *bottomDivider;
}

@property (nonatomic, assign) UIEdgeInsets padding;
@property (nonatomic, assign) BOOL drawTopDivider;
@property (nonatomic, assign) BOOL drawBottomDivider;

@end
