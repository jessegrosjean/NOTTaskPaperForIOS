//
//  PKCommentState.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 12/28/08.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "PKCommentState.h"
#import "PKTokenizer.h"
#import "PKToken.h"
#import "PKReader.h"
#import "PKSymbolRootNode.h"
#import "PKSingleLineCommentState.h"
#import "PKMultiLineCommentState.h"

@interface PKToken ()
@property (nonatomic, readwrite) NSUInteger offset;
@end

@interface PKTokenizerState ()
- (void)resetWithReader:(PKReader *)r;
- (PKTokenizerState *)nextTokenizerStateFor:(PKUniChar)c tokenizer:(PKTokenizer *)t;
@end

@interface PKCommentState ()
@property (nonatomic, retain) PKSymbolRootNode *rootNode;
@property (nonatomic, retain) PKSingleLineCommentState *singleLineState;
@property (nonatomic, retain) PKMultiLineCommentState *multiLineState;
@end

@interface PKSingleLineCommentState ()
- (void)addStartMarker:(NSString *)start;
- (void)removeStartMarker:(NSString *)start;
@property (nonatomic, retain) NSMutableArray *startMarkers;
@property (nonatomic, retain) NSString *currentStartMarker;
@end

@interface PKMultiLineCommentState ()
- (void)addStartMarker:(NSString *)start endMarker:(NSString *)end;
- (void)removeStartMarker:(NSString *)start;
@property (nonatomic, retain) NSMutableArray *startMarkers;
@property (nonatomic, retain) NSMutableArray *endMarkers;
@property (nonatomic, copy) NSString *currentStartMarker;
@end

@implementation PKCommentState

- (id)init {
    if (self = [super init]) {
        self.rootNode = [[[PKSymbolRootNode alloc] init] autorelease];
        self.singleLineState = [[[PKSingleLineCommentState alloc] init] autorelease];
        self.multiLineState = [[[PKMultiLineCommentState alloc] init] autorelease];
    }
    return self;
}


- (void)dealloc {
    self.rootNode = nil;
    self.singleLineState = nil;
    self.multiLineState = nil;
    [super dealloc];
}


- (void)addSingleLineStartMarker:(NSString *)start {
    NSParameterAssert(start.length);
    [rootNode add:start];
    [singleLineState addStartMarker:start];
}


- (void)removeSingleLineStartMarker:(NSString *)start {
    NSParameterAssert(start.length);
    [rootNode remove:start];
    [singleLineState removeStartMarker:start];
}


- (void)addMultiLineStartMarker:(NSString *)start endMarker:(NSString *)end {
    NSParameterAssert(start.length);
    NSParameterAssert(end.length);
    [rootNode add:start];
    [rootNode add:end];
    [multiLineState addStartMarker:start endMarker:end];
}


- (void)removeMultiLineStartMarker:(NSString *)start {
    NSParameterAssert(start.length);
    [rootNode remove:start];
    [multiLineState removeStartMarker:start];
}


- (PKToken *)nextTokenFromReader:(PKReader *)r startingWith:(PKUniChar)cin tokenizer:(PKTokenizer *)t {
    NSParameterAssert(r);
    NSParameterAssert(t);

    [self resetWithReader:r];

    NSString *symbol = [rootNode nextSymbol:r startingWith:cin];

    if ([multiLineState.startMarkers containsObject:symbol]) {
        multiLineState.currentStartMarker = symbol;
        PKToken *tok = [multiLineState nextTokenFromReader:r startingWith:cin tokenizer:t];
        if (tok.isComment) {
            tok.offset = offset;
        }
        return tok;
    } else if ([singleLineState.startMarkers containsObject:symbol]) {
        singleLineState.currentStartMarker = symbol;
        PKToken *tok = [singleLineState nextTokenFromReader:r startingWith:cin tokenizer:t];
        if (tok.isComment) {
            tok.offset = offset;
        }
        return tok;
    } else {
        [r unread:symbol.length - 1];
        return [[self nextTokenizerStateFor:cin tokenizer:t] nextTokenFromReader:r startingWith:cin tokenizer:t];
    }
}

@synthesize rootNode;
@synthesize singleLineState;
@synthesize multiLineState;
@synthesize reportsCommentTokens;
@synthesize balancesEOFTerminatedComments;
@end
