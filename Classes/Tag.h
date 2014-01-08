//
//  Tag.h
//  Documents
//
//  Created by Jesse Grosjean on 5/18/09.
//

@class Section;

@interface Tag : NSObject {
	Section *section;
	NSString *name;
	NSString *value;
}

+ (NSDateFormatter *)tagDateFormatter;
+ (NSArray *)parseTagsInString:(NSString *)string;
+ (NSRange)parseTrailingTagsRangeInString:(NSString *)string;
+ (NSRange)parseTrailingTagsRangeInString:(NSString *)string inRange:(NSRange)aRange;
+ (id)tagWithName:(NSString *)aName value:(NSString *)aValue;
+ (NSString *)validateTagValue:(NSString *)aValue;

- (id)initWithName:(NSString *)aName value:(NSString *)aValue;

@property(assign, nonatomic) Section *section;
@property(readonly, nonatomic) NSString *name;
@property(readonly, nonatomic) NSString *value;
@property(retain, nonatomic) NSNumber *numberValue;

- (NSString *)contentByAddingTag:(NSString *)originalContent;
- (NSString *)contentByRemovingTag:(NSString *)originalContent;

@end

extern NSString *TrailingTagsRegex;
extern NSString *TagRegex;
extern NSString *TagValidNameRegex;
extern NSString *TagValidValueRegex;
