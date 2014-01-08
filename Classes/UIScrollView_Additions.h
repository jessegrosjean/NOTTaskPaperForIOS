//
//  UIScrollView_Additions.h
//  PlainText
//
//  Created by Jesse Grosjean on 5/25/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

@interface UIScrollView (Additions)

- (void)installTopFaderWithHeight:(CGFloat)height;
- (void)uninstallTopFader;
- (void)installBottomFaderWithHeight:(CGFloat)height;
- (void)uninstallBottomFader;

@end
