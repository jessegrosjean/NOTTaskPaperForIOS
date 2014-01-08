//
//  NSString_Additions.m
//  SimpleText
//
//  Created by Jesse Grosjean on 5/8/10.
//

#import "NSString_Additions.h"
#import "discountWrapper.h"

@implementation NSString (Additions)

+ (NSString *)stringWithTabIndentation:(NSUInteger)level {
	NSMutableString *s = [NSMutableString stringWithCapacity:level];
	while (level--) {
		[s appendString:@"/t"];
	}
	return s;
}

+ (NSString *)myStringWithContentsOfFile:(NSString *)path usedEncoding:(NSStringEncoding *)stringEncoding error:(NSError **)error {
	NSString *fileContents = [NSString stringWithContentsOfFile:path usedEncoding:stringEncoding error:error];
	if (!fileContents) {
		fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:error];
	}
	return fileContents;
}

- (NSUInteger)nextWordFromIndex:(NSUInteger)location forward:(BOOL)isForward {
	static NSCharacterSet *wordBreakCSet = nil;
	static NSCharacterSet *wordCSet = nil;
	
	if (!wordBreakCSet) {
		NSMutableCharacterSet *m = [[[NSMutableCharacterSet alloc] init] autorelease];
		[m formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[m formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
		[m formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
		[m formUnionWithCharacterSet:[NSCharacterSet illegalCharacterSet]];
		[m removeCharactersInString:@"'"];
		wordBreakCSet = [m copy];
		wordCSet = [[wordBreakCSet invertedSet] copy];
	}
	
	NSUInteger length = [self length];
	NSRange range;
	
	if (isForward) {
		if (location == length) return length;
		
		range = NSMakeRange (location, length - location);
		range = [self rangeOfCharacterFromSet:wordBreakCSet options:NSLiteralSearch range:range];
		if (range.location == NSNotFound) return length;
		
		range = NSMakeRange (range.location, length - range.location);
		range = [self rangeOfCharacterFromSet:wordCSet options:NSLiteralSearch range:range];
		if (range.location == NSNotFound) return length;
		
		return range.location;
	} else {
		if (location == 0) return 0;
		
		range = NSMakeRange (0, location);
		range = [self rangeOfCharacterFromSet:wordCSet options:NSBackwardsSearch | NSLiteralSearch range:range];
		if (range.location == NSNotFound) return 0;
		
		range = NSMakeRange (0, range.location);
		range = [self rangeOfCharacterFromSet:wordBreakCSet options:NSBackwardsSearch | NSLiteralSearch range:range];
		if (range.location == NSNotFound) return 0;
		
		return NSMaxRange (range);
	}
}

- (void)statistics:(NSUInteger *)paragraphs words:(NSUInteger *)words characters:(NSUInteger *)characters {
	NSUInteger wordCount = 0;
	NSUInteger paragraphCount = 0;
	NSCharacterSet *lettersAndNumbers = [NSCharacterSet alphanumericCharacterSet];
	NSRange paragraphRange = NSMakeRange(0, 0);
	NSUInteger length = [self length];
	
	while (NSMaxRange(paragraphRange) < length) {		
		paragraphRange = [self paragraphRangeForRange:paragraphRange];
		
		NSUInteger index = paragraphRange.location;
		NSUInteger end = NSMaxRange(paragraphRange);
		
		while (index < end) {
			NSUInteger newIndex = MIN(end, [self nextWordFromIndex:index forward:YES]);
			NSString *word = [self substringWithRange:NSMakeRange(index, newIndex - index)];
			
			if ([word rangeOfCharacterFromSet:lettersAndNumbers].location != NSNotFound)
				wordCount++;
			
			index = newIndex;
		}
		
		paragraphCount++;
		paragraphRange = NSMakeRange(NSMaxRange(paragraphRange), 0);
	}
	
	if (paragraphs) {
		*paragraphs = paragraphCount;
	}
	
	if (words) {
		*words = wordCount;
	}
	
	if (characters) {
		*characters = length;
	}
}

- (NSComparisonResult)naturalCompare:(NSString *)aString {
	return [self compare:aString options:NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch];
}

- (NSString *)markdownToHTML {
	return discountToHTML(self);
}

- (BOOL)isInvisibleFile {
	if ([self length] > 0) {
		NSString *fileName = [self lastPathComponent];
		
		if ([fileName length] > 0) {
			if ([fileName characterAtIndex:0] == '.') return YES;
			if ([fileName isEqualToString:@"Icon\r"]) return YES;
		}
		
#if !TARGET_OS_IPHONE
		FSRef pathFSRef;
		struct FSCatalogInfo catInfo;
		
		if(![self getFSRef:&pathFSRef createFileIfNecessary:YES])
			return NO;
		
		OSErr result = FSGetCatalogInfo(&pathFSRef,
										kFSCatInfoFinderInfo,
										&catInfo,
										/*outName*/ NULL,
										/*fsSpec*/ NULL,
										/*parentRef*/ NULL );
		if (result == noErr) {
			struct FileInfo *finderInfo = (struct FileInfo *)catInfo.finderInfo;
			if ((finderInfo->finderFlags & kIsInvisible) == kIsInvisible) {
				return YES;
			}
		}
#endif		
	}
	return NO;
}

@end
