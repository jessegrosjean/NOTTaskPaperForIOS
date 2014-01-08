//
//  UIImage_Additions.h
//  PlainText
//
//  Created by Jesse Grosjean on 5/21/10.
//

@interface UIImage (Additions)

+ (UIImage *)colorizeImage:(UIImage *)baseImage color:(UIColor *)theColor;
+ (UIImage *)colorizeImagePixels:(UIImage *)baseImage color:(UIColor *)theColor;

@end
