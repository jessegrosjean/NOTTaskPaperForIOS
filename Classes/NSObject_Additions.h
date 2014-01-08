//
//  NSObject_Additions.h
//  PlainText
//
//  Created by Jesse Grosjean on 5/20/10.
//

@interface NSObject (Additions)

+ (BOOL)replaceClassMethod:(SEL)originalSelelector withMethod:(SEL)newSelector;
+ (BOOL)replaceInstanceMethod:(SEL)originalSelelector withMethod:(SEL)newSelector;
- (void)subclassResponsibilityForSelector:(SEL)aSelector;

@end
