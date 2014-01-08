//
//  Tag.m
//  Documents
//
//  Created by Jesse Grosjean on 5/18/09.
//

#import "Tag.h"
#import "Tree.h"
#import "Section.h"
#import "RegexKitLite.h"


@implementation Tag

+ (NSDateFormatter *)tagDateFormatter {
	static NSDateFormatter *dateFormatter = nil;
	if (!dateFormatter) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dateFormatter setDateStyle:NSDateFormatterNoStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDateFormat:@"yyyy-MM-dd"];
	}
	return dateFormatter;
}

+ (NSArray *)parseTagsInString:(NSString *)string {
	NSUInteger possibleTagsStartLocation = [string rangeOfString:@"@" options:NSLiteralSearch].location; // quick check to avoid regex if possible.
	if (possibleTagsStartLocation != NSNotFound) {
		NSMutableArray *tags = [NSMutableArray array];
		NSArray *tagsArray = [string arrayOfCaptureComponentsMatchedByRegex:TagRegex];		
		for (NSArray *matchedTagArray in tagsArray) {
			[tags addObject:[[[Tag alloc] initWithName:[matchedTagArray objectAtIndex:1] value:[matchedTagArray objectAtIndex:2]] autorelease]];
		}
		return tags;
	}
	return [NSArray array];
}

+ (NSRange)parseTrailingTagsRangeInString:(NSString *)string {
	return [self parseTrailingTagsRangeInString:string inRange:NSMakeRange(0, [string length])];
}

+ (NSRange)parseTrailingTagsRangeInString:(NSString *)string inRange:(NSRange)aRange {
	NSUInteger possibleTagsStartLocation = [string rangeOfString:@"@" options:NSLiteralSearch].location; // quick check to avoid regex if possible.
	if (possibleTagsStartLocation != NSNotFound) {
		return [string rangeOfRegex:TrailingTagsRegex inRange:aRange];
	}
	
	return NSMakeRange(NSNotFound, 0);
}

+ (void)writeTags:(NSArray *)tags toString:(NSMutableString *)string {
	BOOL firstTag = YES;
	for (Tag *eachTag in tags) {
		if (firstTag) {
			firstTag = NO;
		} else {
			[string appendString:@" "];
		}
		
		if ([eachTag.value length] > 0) {
			[string appendFormat:@"@%@(%@)", eachTag.name, eachTag.value];
		} else {
			[string appendFormat:@"@%@", eachTag.name];
		}
	}
}

+ (id)tagWithName:(NSString *)aName value:(NSString *)aValue {
	return [[[self alloc] initWithName:aName value:aValue] autorelease];
}

+ (NSString *)validateTagValue:(NSString *)aValue {
	NSRange validRange = [aValue rangeOfRegex:TagValidValueRegex];
	if ([aValue length] == validRange.length) {
		return aValue;
	}
	return [aValue substringWithRange:validRange];
}

- (id)initWithName:(NSString *)aName value:(NSString *)aValue {
	if (self = [super init]) {
		if (aName != nil) {
			if ([aName rangeOfRegex:TagValidNameRegex].length != [aName length]) {
				[NSException raise:@"InvalidTagName" format:@"Invalid tag name: %@", aName];
			}
		}
		
		[name autorelease];
		name = [aName retain];
		
		if (aValue != nil && [aValue length] > 0) {
			if ([aValue rangeOfRegex:TagValidValueRegex].length != [aValue length]) {
				[NSException raise:@"InvalidTagValue" format:@"Invalid tag value: %@", aValue];
			}
		}
		
		[value autorelease];
		value = [aValue retain];
	}
	return self;
}

- (void)dealloc {
	[name release];
	[value release];
	[super dealloc];
}

- (BOOL)isEqual:(id)anObject {
	Tag *other = (Tag *)anObject;
	if ([other isKindOfClass:[Tag class]]) {
		if (![name isEqual:other->name]) return NO;
		if (value != other->value) return NO;
		if (value) {
			return [value isEqual:other->value];
		} else {
			return YES;
		}
	}
	return NO;
}

- (NSUInteger)hash {
	return [[self description] hash];
}

@synthesize section;
@synthesize name;
@synthesize value;

- (NSString *)contentByAddingTag:(NSString *)originalContent {
	return [originalContent stringByAppendingFormat:@" %@", [self description]];
}

- (NSString *)contentByRemovingTag:(NSString *)originalContent {
	NSCharacterSet *alphanumericCharacterSet = [NSCharacterSet alphanumericCharacterSet];
	NSString *tagString = [self description];
	NSUInteger contentLength = [originalContent length];
	NSRange tagRange = [originalContent rangeOfString:tagString];
	
	while (tagRange.location != NSNotFound) {
		NSUInteger tagMaxRange = NSMaxRange(tagRange);
		NSRange deleteRange = tagRange;
		BOOL tag = YES;

		if (tagRange.location > 0) {
			if (![alphanumericCharacterSet characterIsMember:[originalContent characterAtIndex:tagRange.location - 1]]) {
				deleteRange.location--;
				deleteRange.length++;
			} else {
				tag = NO;
			}
		}
		
		if (tag && tagMaxRange < contentLength) {
			if (![alphanumericCharacterSet characterIsMember:[originalContent characterAtIndex:tagMaxRange]]) {
				if (tagRange.location == 0) { // only delete trailing whitespace if tag starts content.
					deleteRange.length++;
				}
			} else {
				tag = NO;
			}
		}

		if (tag) {
			return [originalContent stringByReplacingCharactersInRange:deleteRange withString:@""];
		} else {
			tagRange = [originalContent rangeOfString:tagString options:NSLiteralSearch range:NSMakeRange(tagMaxRange, contentLength - tagMaxRange)];
		}
	}
	
	return nil;
}

- (NSString *)description {
	if ([value length] > 0) {
		return [NSString stringWithFormat:@"@%@(%@)", name, value];
	} else {
		return [NSString stringWithFormat:@"@%@", name];
	}
}

NSNumberFormatter * TagNumberFormatter() {
	static NSNumberFormatter *numberFormatter = nil;
	if (!numberFormatter) {
		numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setDecimalSeparator:@"."];
	}
	return numberFormatter;
}

- (NSNumber *)numberValue {
	NSNumber *result = nil;
	
	if (self.value) {
		result = [TagNumberFormatter() numberFromString:self.value];
	}
	
	if (!result) {
		result = [NSNumber numberWithInt:0];
	}
    
	return result;
}

- (void)setNumberValue:(NSNumber *)newNumber {
	value = [TagNumberFormatter() stringFromNumber:newNumber];
}

@end

NSString *TrailingTagsRegex = @"(?:(?:^|\\s)@([^\\(\\s]*)(\\([^\\)]*\\))?)+$"; // Find valid range for tags.
NSString *TagRegex = @"(?:^|\\s)@([^\\(\\s]*)(?:\\(([^\\)]+)\\))?"; // Find individual tags and values within valid range.
NSString *TagValidNameRegex = @"[^\\(\\s]*";
NSString *TagValidValueRegex = @"(?:[^\\)]*)";