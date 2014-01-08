//
//  QueryParser.h
//  Documents
//
//  Created by Jesse Grosjean on 5/29/09.
//  Copyright 2009 Hog Bay Software. All rights reserved.
//

@class PKParser, PKTokenizer, PKToken, PKCollectionParser, PKPattern, PKAssembly;

@interface QueryParser : NSObject {
	PKTokenizer *tokenizer;
	NSArray *logicKeywords;
	NSArray *relationKeywords;
	NSArray *attributeKeywords;
	PKToken *nonReservedWordFence;
	PKCollectionParser *expressionParser;
	PKCollectionParser *termParser;
	PKCollectionParser *orTermParser;
	PKCollectionParser *notFactorParser;
	PKCollectionParser *andNotFactorParser;
	PKCollectionParser *primaryExpressionParser;
	PKCollectionParser *predicateParser;
	PKCollectionParser *completePredicateParser;
	PKCollectionParser *attributeValuePredicateParser;
	PKCollectionParser *attributePredicateParser;
	PKCollectionParser *relationValuePredicateParser;
	PKCollectionParser *valuePredicateParser;
	PKPattern *attributeParser;
	PKCollectionParser *relationParser;
	PKCollectionParser *valueParser;
	PKParser *quotedStringParser;
	PKCollectionParser *unquotedStringParser;
	PKPattern *reservedWordParser;
	PKPattern *nonReservedWordParser;
}

+ (id)sharedInstance;

- (NSPredicate *)parse:(NSString *)s highlight:(id *)attributedString;

- (PKAssembly *)assemblyFromString:(NSString *)s;

@property (nonatomic, retain) PKTokenizer *tokenizer;
@property (nonatomic, retain) PKCollectionParser *expressionParser;
@property (nonatomic, retain) PKCollectionParser *termParser;
@property (nonatomic, retain) PKCollectionParser *orTermParser;
@property (nonatomic, retain) PKCollectionParser *notFactorParser;
@property (nonatomic, retain) PKCollectionParser *andNotFactorParser;
@property (nonatomic, retain) PKCollectionParser *primaryExpressionParser;
@property (nonatomic, retain) PKCollectionParser *predicateParser;
@property (nonatomic, retain) PKCollectionParser *completePredicateParser;
@property (nonatomic, retain) PKCollectionParser *attributeValuePredicateParser;
@property (nonatomic, retain) PKCollectionParser *attributePredicateParser;
@property (nonatomic, retain) PKCollectionParser *relationValuePredicateParser;
@property (nonatomic, retain) PKCollectionParser *valuePredicateParser;
@property (nonatomic, retain) PKPattern *attributeParser;
@property (nonatomic, retain) PKCollectionParser *relationParser;
@property (nonatomic, retain) PKCollectionParser *valueParser;
@property (nonatomic, retain) PKParser *quotedStringParser;
@property (nonatomic, retain) PKCollectionParser *unquotedStringParser;
@property (nonatomic, retain) PKPattern *reservedWordParser;
@property (nonatomic, retain) PKPattern *nonReservedWordParser;

@end