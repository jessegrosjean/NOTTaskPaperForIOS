//
//  QueryParser.m
//  Documents
//
//  Created by Jesse Grosjean on 5/29/09.
//

#import "QueryParser.h"
#import "NaturalComparisonPredicate.h"
#import "TaskPaperSection.h"
#import "PKTokenizer.h"
#import "PKToken.h"
#import "PKSequence.h"
#import "PKParser.h"
#import "PKCollectionParser.h"
#import "PKPattern.h"
#import "PKAssembly.h"
#import "PKWordState.h"
#import "PKTokenAssembly.h"
#import "PKRepetition.h"
#import "PKCaseInsensitiveLiteral.h"
#import "PKAlternation.h"
#import "PKSequence.h"
#import "PKSymbol.h"
#import "PKTokenizerState.h"
#import "PKIntersection.h"
#import "PKQuotedString.h"
#import "PKWord.h"
#import "PKNegation.h"

// expression				= term orTerm*
// term						= notFactor andNotFactor*
// orTerm					= 'or' term
// notFactor				= 'not'* primaryExpression
// andNotFactor				= 'and' notFactor
// primaryExpression		= predicate | '(' expression ')'
// predicate				= completePredicate | attributeValuePredicate | attributePredicate | relationValuePredicate | valuePredicate
// completePredicate		= attribute relation value
// attributeValuePredicate	= attribute value
// attributePredicate		= attribute
// relationValuePredicate	= relation value
// valuePredicate			= value
// attribute				= attributeKeywords
// relation					= '=' | '!=' | '>' | '>=' | '<' | '<=' | relationKeywords
// value					= QuotedString | unquotedString
// unquotedString			= nonReservedWord+

@interface QueryParser ()
@property (nonatomic, retain) NSArray *logicKeywords;
@property (nonatomic, retain) NSArray *relationKeywords;
@property (nonatomic, retain) NSArray *attributeKeywords;
@property (nonatomic, retain) PKToken *nonReservedWordFence;
- (void)boldRange:(NSRange)aRange attributedString:(id)string;
- (void)blackRange:(NSRange)aRange attributedString:(id)string;
@end

@implementation QueryParser

+ (id)sharedInstance {
	static id sharedInstance = nil;
	if (sharedInstance == nil) {
		sharedInstance = [[self alloc] init];
	}
	return sharedInstance;
}

- (id)init {
	if (self = [super init]) {
		self.tokenizer = [PKTokenizer tokenizer];
		
		[tokenizer setTokenizerState:tokenizer.wordState from:'-' to:'-'];
		[tokenizer setTokenizerState:tokenizer.wordState from:'.' to:'.'];
		[tokenizer setTokenizerState:tokenizer.wordState from:'0' to:'9'];		
		[tokenizer setTokenizerState:tokenizer.wordState from:'@' to:'@'];
		
		self.logicKeywords = [NSArray arrayWithObjects:@"or", @"and", @"not", nil];
		self.relationKeywords = [NSArray arrayWithObjects:@"beginswith", @"contains", @"endswith", @"like", @"matches", nil];
		self.attributeKeywords = [NSArray arrayWithObjects:@"line", @"project", @"index", @"content", @"type", @"level", @"@\\w*", nil];
		
		self.nonReservedWordFence = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"." floatValue:0.0];
	}
	return self;
}

- (void)dealloc {
	self.expressionParser = nil;
	self.termParser = nil;
	self.orTermParser = nil;
	self.notFactorParser = nil;
	self.andNotFactorParser = nil;
	self.primaryExpressionParser = nil;
	self.predicateParser = nil;
	self.completePredicateParser = nil;
	self.attributeValuePredicateParser = nil;
	self.attributePredicateParser = nil;
	self.relationValuePredicateParser = nil;
	self.valuePredicateParser = nil;
	self.attributeParser = nil;
	self.relationParser = nil;
	self.valueParser = nil;
	self.quotedStringParser = nil;
	self.unquotedStringParser = nil;
	self.reservedWordParser = nil;
	self.nonReservedWordParser = nil;
	[super dealloc];
}

- (NSPredicate *)parse:(NSString *)s highlight:(id *)attributedString {
	PKAssembly *assembly = [self assemblyFromString:s];
	
#if !TARGET_OS_IPHONE
	NSMutableAttributedString *mutableAttributedString = nil;
	
	if (attributedString) {
		mutableAttributedString = [[[NSMutableAttributedString alloc] initWithString:s] autorelease];
		[mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(0, [s length])];
		[assembly setTarget:mutableAttributedString];
	}
#endif
	
	assembly = [self.expressionParser bestMatchFor:assembly];
	
#if !TARGET_OS_IPHONE
	if (attributedString) {
		mutableAttributedString = assembly.target;
		PKToken *unparsedToken = [assembly peek];
		if (unparsedToken) {
			[mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:NSMakeRange(unparsedToken.offset, [mutableAttributedString length] - unparsedToken.offset)];
		}
		*attributedString = mutableAttributedString;
	}
#endif
	
	return [assembly pop];
}

- (PKAssembly *)assemblyFromString:(NSString *)s {
	tokenizer.string = s;
	return [PKTokenAssembly assemblyWithTokenizer:tokenizer];
}

@synthesize logicKeywords;
@synthesize relationKeywords;
@synthesize attributeKeywords;
@synthesize nonReservedWordFence;

#pragma mark Parsers


// expression				= term orTerm*
- (PKCollectionParser *)expressionParser {
	if (!expressionParser) {
		self.expressionParser = [PKSequence sequence];
		expressionParser.name = @"exprParser";
		[expressionParser add:self.termParser];
		[expressionParser add:[PKRepetition repetitionWithSubparser:self.orTermParser]];
	}
	return expressionParser;
}

// term			 = primaryExpression andPrimaryExpression*
// term						= notFactor andNotFactor*
- (PKCollectionParser *)termParser {
	if (!termParser) {
		self.termParser = [PKSequence sequence];
		termParser.name = @"termParser";
		[termParser add:self.notFactorParser];
		[termParser add:[PKRepetition repetitionWithSubparser:self.andNotFactorParser]];
	}
	return termParser;
}

// orTerm					= 'or' term
- (PKCollectionParser *)orTermParser {
	if (!orTermParser) {
		self.orTermParser = [PKSequence sequence];
		orTermParser.name = @"orTermParser";
		[orTermParser add:[PKCaseInsensitiveLiteral literalWithString:@"or"]];
		[orTermParser add:self.termParser];
		[orTermParser setAssembler:self selector:@selector(workOnOrAssembly:)];
	}
	return orTermParser;
}


// notFactor				= 'not'* primaryExpression
- (PKCollectionParser *)notFactorParser {
	if (!notFactorParser) {
		self.notFactorParser = [PKSequence sequence];
		notFactorParser.name = @"notFactorParser";
		[notFactorParser add:[PKRepetition repetitionWithSubparser:[PKCaseInsensitiveLiteral literalWithString:@"not"]]];
		[notFactorParser add:self.primaryExpressionParser];
		[notFactorParser setAssembler:self selector:@selector(workOnNotAssembly:)];
	}
	return notFactorParser;
}

// andNotFactor				= 'and' notFactor
- (PKCollectionParser *)andNotFactorParser {
	if (!andNotFactorParser) {
		self.andNotFactorParser = [PKSequence sequence];
		andNotFactorParser.name = @"andNotFactorParser";
		[andNotFactorParser add:[PKCaseInsensitiveLiteral literalWithString:@"and"]];
		[andNotFactorParser add:self.notFactorParser];
		[andNotFactorParser setAssembler:self selector:@selector(workOnAndAssembly:)];
	}
	return andNotFactorParser;
}

// primaryExpression		= predicate | '(' expression ')'
- (PKCollectionParser *)primaryExpressionParser {
	if (!primaryExpressionParser) {
		self.primaryExpressionParser = [PKAlternation alternation];
		primaryExpressionParser.name = @"primaryExpressionParser";
		[primaryExpressionParser add:self.predicateParser];
		
		PKSequence *s = [PKSequence sequence];
		[s add:[PKSymbol symbolWithString:@"("]];
		[s add:self.expressionParser]; // Leak now exprParser retains us and we retain it
		[s add:[PKSymbol symbolWithString:@")"]];
		[s setAssembler:self selector:@selector(workOnGroupedExpressionAssembly:)];
		
		[primaryExpressionParser add:s];
	}
	return primaryExpressionParser;
}

// predicate				= completePredicate | attributeValuePredicate | attributePredicate | relationValuePredicateParser | valuePredicate
- (PKCollectionParser *)predicateParser {
	if (!predicateParser) {
		self.predicateParser = [PKAlternation alternation];
		predicateParser.name = @"predicateParser";
		[predicateParser add:self.completePredicateParser];
		[predicateParser add:self.attributeValuePredicateParser];
		[predicateParser add:self.attributePredicateParser];
		[predicateParser add:self.relationValuePredicateParser];
		[predicateParser add:self.valuePredicateParser];
	}
	return predicateParser;
}

// completePredicate		= attribute relation value
- (PKCollectionParser *)completePredicateParser {
	if (!completePredicateParser) {
		self.completePredicateParser = [PKSequence sequence];
		completePredicateParser.name = @"completePredicateParser";
		[completePredicateParser add:self.attributeParser];
		[completePredicateParser add:self.relationParser];
		[completePredicateParser add:self.valueParser];
		[completePredicateParser setAssembler:self selector:@selector(workOnCompletePredicateAssembly:)];
	}
	return completePredicateParser;
}

// attributeValuePredicate	= attribute value
- (PKCollectionParser *)attributeValuePredicateParser {
	if (!attributeValuePredicateParser) {
		self.attributeValuePredicateParser = [PKSequence sequence];
		attributeValuePredicateParser.name = @"attributeValuePredicateParser";
		[attributeValuePredicateParser add:self.attributeParser];
		[attributeValuePredicateParser add:self.valueParser];
		[attributeValuePredicateParser setAssembler:self selector:@selector(workOnAttributeValuePredicateAssembly:)];
	}
	return attributeValuePredicateParser;
}

// attributePredicate		= attribute
- (PKCollectionParser *)attributePredicateParser {
	if (!attributePredicateParser) {
		self.attributePredicateParser = [PKSequence sequence];
		attributePredicateParser.name = @"attributePredicateParser";
		[attributePredicateParser add:self.attributeParser];
		[attributePredicateParser setAssembler:self selector:@selector(workOnAttributePredicateAssembly:)];
	}
	return attributePredicateParser;
}

- (PKCollectionParser *)relationValuePredicateParser {
	if (!relationValuePredicateParser) {
		self.relationValuePredicateParser = [PKSequence sequence];
		relationValuePredicateParser.name = @"relationValuePredicateParser";
		[relationValuePredicateParser add:self.relationParser];
		[relationValuePredicateParser add:self.valueParser];
		[relationValuePredicateParser setAssembler:self selector:@selector(workOnRelationValuePredicateAssembly:)];
	}
	return relationValuePredicateParser;
}

// valuePredicate			= value
- (PKCollectionParser *)valuePredicateParser {
	if (!valuePredicateParser) {
		self.valuePredicateParser = [PKSequence sequence];
		valuePredicateParser.name = @"valuePredicateParser";
		[valuePredicateParser add:self.valueParser];
		[valuePredicateParser setAssembler:self selector:@selector(workOnValuePredicateAssembly:)];
	}
	return valuePredicateParser;
}

// attribute				= attributeKeywords
- (PKPattern *)attributeParser {
	if (!attributeParser) {
		self.attributeParser = [PKIntersection intersectionWithSubparsers:[PKWord word], [PKPattern patternWithString:[NSString stringWithFormat:@"%@", [self.attributeKeywords componentsJoinedByString:@"|"]] options:PKPatternOptionsIgnoreCase], nil];
		attributeParser.name = @"attributeParser";
		[attributeParser setAssembler:self selector:@selector(workOnAttributeAssembly:)];
	}
	return attributeParser;
}

// relation					= '=' | '!=' | '>' | '>=' | '<' | '<=' | relationKeywords
- (PKCollectionParser *)relationParser {
	if (!relationParser) {
		self.relationParser = [PKAlternation alternation];
		relationParser.name = @"relationParser";
		[relationParser add:[PKSymbol symbolWithString:@"="]];
		[relationParser add:[PKSymbol symbolWithString:@"!="]];
		[relationParser add:[PKSymbol symbolWithString:@">"]];
		[relationParser add:[PKSymbol symbolWithString:@">="]];
		[relationParser add:[PKSymbol symbolWithString:@"<"]];
		[relationParser add:[PKSymbol symbolWithString:@"<="]];
		[relationParser add:[PKIntersection intersectionWithSubparsers:[PKWord word],[PKPattern patternWithString:[NSString stringWithFormat:@"%@", [self.relationKeywords componentsJoinedByString:@"|"]] options:PKPatternOptionsIgnoreCase], nil]];
		[relationParser setAssembler:self selector:@selector(workOnRelationAssembly:)];
	}
	return relationParser;
}

// value					= QuotedString | unquotedString
- (PKCollectionParser *)valueParser {
	if (!valueParser) {
		self.valueParser = [PKAlternation alternation];
		valueParser.name = @"valueParser";
		[valueParser add:self.quotedStringParser];
		[valueParser add:self.unquotedStringParser];
	}
	return valueParser;
}

- (PKParser *)quotedStringParser {
	if (!quotedStringParser) {
		self.quotedStringParser = [PKQuotedString quotedString];
		[quotedStringParser setAssembler:self selector:@selector(workOnQuotedStringAssembly:)];
	}
	return quotedStringParser;
}

// unquotedString			= nonReservedWord+
- (PKCollectionParser *)unquotedStringParser {
	if (!unquotedStringParser) {
		self.unquotedStringParser = [PKSequence sequence];
		[unquotedStringParser add:self.nonReservedWordParser];
		[unquotedStringParser add:[PKRepetition repetitionWithSubparser:self.nonReservedWordParser]];
		[unquotedStringParser setAssembler:self selector:@selector(workOnUnquotedStringAssembly:)];
	}
	return unquotedStringParser;
}

- (PKPattern *)reservedWordParser {
	if (!reservedWordParser) {
		self.reservedWordParser = [PKAlternation alternationWithSubparsers:[PKPattern patternWithString:[self.logicKeywords componentsJoinedByString:@"|"] options:PKPatternOptionsIgnoreCase], self.relationParser, self.attributeParser, nil];
		reservedWordParser.name = @"reservedWord";
	}
	return reservedWordParser;
}

- (PKPattern *)nonReservedWordParser {
	if (!nonReservedWordParser) {
		self.nonReservedWordParser = [PKIntersection intersectionWithSubparsers:[PKWord word], [PKNegation negationWithSubparser:self.reservedWordParser], nil];
		nonReservedWordParser.name = @"nonReservedWord";
		[nonReservedWordParser setAssembler:self selector:@selector(workOnNonReservedWordAssembly:)];
	}
	return nonReservedWordParser;
}

#pragma mark Work Ons

- (void)workOnAndAssembly:(PKAssembly *)a {
	NSPredicate *p2 = [a pop];
	PKToken *and = [a pop];
	NSPredicate *p1 = [a pop];
	NSArray *subs = [NSArray arrayWithObjects:p1, p2, nil];
	[a push:[NSCompoundPredicate andPredicateWithSubpredicates:subs]];
	[self boldRange:NSMakeRange(and.offset, 3) attributedString:a.target];
}

- (void)workOnOrAssembly:(PKAssembly *)a {
	NSPredicate *p2 = [a pop];
	PKToken *or = [a pop];
	NSPredicate *p1 = [a pop];
	NSArray *subs = [NSArray arrayWithObjects:p1, p2, nil];
	[a push:[NSCompoundPredicate orPredicateWithSubpredicates:subs]];
	[self boldRange:NSMakeRange(or.offset, 3) attributedString:a.target];
}

- (void)workOnGroupedExpressionAssembly:(PKAssembly *)a {
	PKToken *open = [a pop];
	id inner = [a pop];
	PKToken *close = [a pop];
	[a push:inner];
	[self boldRange:NSMakeRange(open.offset, 1) attributedString:a.target];
	[self boldRange:NSMakeRange(close.offset, 1) attributedString:a.target];
}

- (void)workOnCompletePredicateAssembly:(PKAssembly *)a {
	static NSNumberFormatter *numberFormatter = nil;
	
	if (!numberFormatter) {
		numberFormatter = [[NSNumberFormatter alloc] init];
	}
	
	id value = [a pop];
	NSString *relation = [a pop];
	NSString *attribute = [a pop];
	
	// all searches expected to work on string values, so switch type and level to asString forms.
	if ([attribute isEqualToString:@"type"]) attribute = @"typeAsString";
	//if ([attribute isEqualToString:@"level"]) attribute = @"levelAsString";
	if ([attribute isEqualToString:@"level"]) value = [numberFormatter numberFromString:value];
	//if ([attribute isEqualToString:@"index"]) attribute = @"indexAsString";
	if ([attribute isEqualToString:@"index"]) value = [numberFormatter numberFromString:value];
	if ([attribute isEqualToString:@"line"]) attribute = @"selfString";
	
	if (![relation isEqualToString:@"matches"] && [self.relationKeywords containsObject:relation]) {
		relation = [relation stringByAppendingString:@"[cd]"];
	}
		
	if ([attribute characterAtIndex:0] == '@') {
        
        NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setLocale:[NSLocale currentLocale]]; 
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        
        NSNumber *maybeNumberValue = [numberFormatter numberFromString:value];
		NSMutableString *tagsPredicateFormat = [[[NSMutableString alloc] init] autorelease];
        if (maybeNumberValue) {
            [tagsPredicateFormat appendString:@"SUBQUERY(tags, $tag, $tag.name =[cd] %@ AND $tag.numberValue "];
            [tagsPredicateFormat appendString:relation];
            [tagsPredicateFormat appendString:@" %@).@count > 0"];            
            [a push:[NSPredicate predicateWithFormat:tagsPredicateFormat, [attribute substringFromIndex:1], maybeNumberValue]];
        } else {
            [tagsPredicateFormat appendString:@"SUBQUERY(tags, $tag, $tag.name =[cd] %@ AND $tag.value "];
            [tagsPredicateFormat appendString:relation];
            [tagsPredicateFormat appendString:@" %@).@count > 0"];
            [a push:[NSPredicate predicateWithFormat:tagsPredicateFormat, [attribute substringFromIndex:1], value]];            
        }
	} else {
		// This code should be put in Section Formatter
		NSString *predicateFormat = [NSString stringWithFormat:@"%@ %@ %%@", attribute, relation, nil];
		NSPredicate *predicate = nil;
		
		if ([attribute isEqualToString:@"project"]) {
			 NSNumber *projectType = [NSNumber numberWithUnsignedInteger:TaskPaperSectionTypeProject];
			 NSMutableString *projectPredicateFormat = [[[NSMutableString alloc] init] autorelease];
			 [projectPredicateFormat appendFormat:@"(type = %%@ AND content %@ %%@)", relation, nil];
			 [projectPredicateFormat appendString:@" OR "];
			 [projectPredicateFormat appendFormat:@"SUBQUERY(ancestors.allObjects, $ancestor, $ancestor.type = %%@ AND $ancestor.content %@ %%@).@count > 0", relation, nil];
			 predicate = [NSPredicate predicateWithFormat:projectPredicateFormat, projectType, value, projectType, value, nil];
		 } else {
			 predicate = [NSPredicate predicateWithFormat:predicateFormat, value, nil];
		 }
		
		[a push:predicate];
	}
}

- (void)workOnAttributeValuePredicateAssembly:(PKAssembly *)a {
	id value = [a pop];
	id attribute = [a pop];
	[a push:attribute];
	[a push:@"contains"]; // default relation
	[a push:value];
	[self workOnCompletePredicateAssembly:a];
}

- (void)workOnAttributePredicateAssembly:(PKAssembly *)a {
	NSString *attribute = [a pop];
	if ([attribute characterAtIndex:0] == '@') {
		if ([attribute length] == 1) {
			[a push:[NSPredicate predicateWithFormat:@"tags.@count > 0"]];
		} else {
			[a push:[NSPredicate predicateWithFormat:@"ANY tags.name =[cd] %@", [attribute substringFromIndex:1]]];
		}
	} else {
		[a push:attribute];
		[a push:@""]; // default value;
		[self workOnAttributeValuePredicateAssembly:a];
	}
}

- (void)workOnRelationValuePredicateAssembly:(PKAssembly *)a {
	id predicate = [a pop];
	id value = [a pop];
	[a push:@"selfString"]; // default attribute
	[a push:value];
	[a push:predicate];
	[self workOnCompletePredicateAssembly:a];
}

- (void)workOnValuePredicateAssembly:(PKAssembly *)a {
	id value = [a pop];
	[a push:@"selfString"]; // default attribute
	[a push:value];
	[self workOnAttributeValuePredicateAssembly:a];
}

- (void)workOnAttributeAssembly:(PKAssembly *)a {
	PKToken *attribute = [a pop];
	[a push:[attribute.stringValue lowercaseString]];
	if ([attribute.stringValue characterAtIndex:0] == '@') {
		[self blackRange:NSMakeRange(attribute.offset, [attribute.stringValue length]) attributedString:a.target];
	}
}

- (void)workOnRelationAssembly:(PKAssembly *)a {
	[a push:[[a pop] stringValue]];
}

- (void)workOnNotAssembly:(PKAssembly *)a {
	NSPredicate *predicate = [a pop];
	PKToken *possibleNot = [a pop];
	BOOL shouldNotExpression = NO;
	while ([possibleNot isKindOfClass:[PKToken class]] && [((PKToken *)possibleNot).stringValue isEqualToString:@"not"]) {
		shouldNotExpression = !shouldNotExpression;
		[self boldRange:NSMakeRange(possibleNot.offset, 3) attributedString:a.target];
		possibleNot = [a pop];
	}
	
	if (possibleNot) {
		[a push:possibleNot];
	}
	
	if (shouldNotExpression) {
		[a push:[NSCompoundPredicate notPredicateWithSubpredicate:predicate]];
	} else {
		[a push:predicate];
	}
}

- (void)workOnQuotedStringAssembly:(PKAssembly *)a {
	PKToken *t = [a pop];
	NSString *stringValue = [t stringValue];
	NSString *s = [stringValue stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
	[a push:s];
	[self boldRange:NSMakeRange(t.offset, [stringValue length]) attributedString:a.target];
}

- (void)workOnNonReservedWordAssembly:(PKAssembly *)a {
	PKToken *tok = [a pop];
	[a push:nonReservedWordFence];
	[a push:tok];
	[self blackRange:NSMakeRange(tok.offset, [tok.stringValue length]) attributedString:a.target];
}

- (void)workOnUnquotedStringAssembly:(PKAssembly *)a {
	NSInteger minOffset = NSNotFound;
	NSInteger maxOffset = NSNotFound;
	
	while (1) {
		NSArray *objs = [a objectsAbove:nonReservedWordFence];
		id next = [a pop]; // is the next obj a fence?
		if (![nonReservedWordFence isEqual:next]) {
			if (next) {
				[a push:next];
			}
			for (id obj in [objs reverseObjectEnumerator]) {
				[a push:obj];
			}
			break;
		}
		
		NSAssert(1 == objs.count, @"");
		
		PKToken *word = [objs objectAtIndex:0];
		
		if (minOffset == NSNotFound) {
			minOffset = word.offset;
			maxOffset = word.offset + [word.stringValue length];
		} else {
			minOffset = MIN(minOffset, word.offset);
			maxOffset = MAX(maxOffset, word.offset + [word.stringValue length]);
		}
	}
	
	[a push:[tokenizer.string substringWithRange:NSMakeRange(minOffset, maxOffset - minOffset)]];
}

- (void)boldRange:(NSRange)aRange attributedString:(id)string {
#if !TARGET_OS_IPHONE
	[string addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:aRange];
	[string addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:0] range:aRange];
#endif
}

- (void)blackRange:(NSRange)aRange attributedString:(id)string {
#if !TARGET_OS_IPHONE
	[string addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:aRange];
#endif
}

@synthesize tokenizer;
@synthesize expressionParser;
@synthesize orTermParser;
@synthesize termParser;
@synthesize notFactorParser;
@synthesize andNotFactorParser;
@synthesize primaryExpressionParser;
@synthesize predicateParser;
@synthesize completePredicateParser;
@synthesize attributeValuePredicateParser;
@synthesize attributePredicateParser;
@synthesize relationValuePredicateParser;
@synthesize valuePredicateParser;
@synthesize attributeParser;
@synthesize relationParser;
@synthesize valueParser;
@synthesize quotedStringParser;
@synthesize unquotedStringParser;
@synthesize reservedWordParser;
@synthesize nonReservedWordParser;
@end