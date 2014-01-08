//
//  NSString_Additions.h
//  SimpleText
//
//  Created by Jesse Grosjean on 5/8/10.
//

#import <Foundation/Foundation.h>


@interface NSString (Additions)
+ (NSString *)stringWithTabIndentation:(NSUInteger)level;
+ (NSString *)myStringWithContentsOfFile:(NSString *)path usedEncoding:(NSStringEncoding *)stringEncoding error:(NSError **)error;

- (NSUInteger)nextWordFromIndex:(NSUInteger)location forward:(BOOL)isForward;
- (void)statistics:(NSUInteger *)paragraphs words:(NSUInteger *)words characters:(NSUInteger *)characters;
- (NSComparisonResult)naturalCompare:(NSString *)aString;
- (NSString *)markdownToHTML;
- (BOOL)isInvisibleFile;
@end
