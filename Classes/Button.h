//
//  Button.h
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//


@interface Button : UIButton {
	UIImage *savedImage;
	CGFloat brightness;
}

- (void)setImage:(UIImage *)image;


+ (Button *)buttonWithImage:(UIImage *)image color:(UIColor *)color accessibilityLabel:(NSString *)accessibilityLabel accessibilityHint:(NSString *)accessibilityHint target:(id)target action:(SEL)action edgeInsets:(UIEdgeInsets)edgeInsets;
+ (Button *)buttonWithImage:(UIImage *)image accessibilityLabel:(NSString *)accessibilityLabel accessibilityHint:(NSString *)accessibilityHint target:(id)target action:(SEL)action edgeInsets:(UIEdgeInsets)edgeInsets;
+ (Button *)buttonWithTitle:(NSString *)title target:(id)target action:(SEL)action edgeInsets:(UIEdgeInsets)edgeInsets;

@property (nonatomic, assign) CGFloat brightness;

@end
