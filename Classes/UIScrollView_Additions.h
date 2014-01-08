//
//  UIScrollView_Additions.h
//  PlainText
//
//  Created by Jesse Grosjean on 5/25/10.
//

@interface UIScrollView (Additions)

- (void)installTopFaderWithHeight:(CGFloat)height;
- (void)uninstallTopFader;
- (void)installBottomFaderWithHeight:(CGFloat)height;
- (void)uninstallBottomFader;

@end
