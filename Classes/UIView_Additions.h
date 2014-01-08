//
//  UIView_Additions.h
// PlainText
//
//  Created by Jesse Grosjean on 6/30/10.
//


@interface UIView (Additions)

- (NSArray *)allMySubviews;
- (UIView *)firstSubviewOfClass:(Class)aClass;
- (NSString *)descriptionWithSubviews;
- (UIEdgeInsets)ancestorPadding;
- (void)my_setVisible:(BOOL)visible animated:(BOOL)animated;
- (void)removeSelfAndSubviewAnimations;

@end