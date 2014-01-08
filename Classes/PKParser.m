//
//  PKParser.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "PKParser.h"
#import "PKAssembly.h"
#import "PKTokenAssembly.h"
#import "PKTokenizer.h"

@interface PKParser ()
- (NSSet *)matchAndAssemble:(NSSet *)inAssemblies;
- (PKAssembly *)best:(NSSet *)inAssemblies;
@end

@interface PKParser (PKParserFactoryAdditionsFriend)
- (void)setTokenizer:(PKTokenizer *)t;
@end

@implementation PKParser

+ (id)parser {
    return [[[self alloc] init] autorelease];
}


- (void)dealloc {
#ifdef MAC_OS_X_VERSION_10_6
#if !TARGET_OS_IPHONE
    self.assemblerBlock = nil;
    self.preassemblerBlock = nil;
#endif
#endif
    self.assembler = nil;
    self.assemblerSelector = nil;
    self.preassembler = nil;
    self.preassemblerSelector = nil;
    self.name = nil;
    self.tokenizer = nil;
    [super dealloc];
}


- (void)setAssembler:(id)a selector:(SEL)sel {
    self.assembler = a;
    self.assemblerSelector = sel;
}


- (void)setPreassembler:(id)a selector:(SEL)sel {
    self.preassembler = a;
    self.preassemblerSelector = sel;
}


- (PKParser *)parserNamed:(NSString *)s {
    if ([name isEqualToString:s]) {
        return self;
    }
    return nil;
}


- (NSSet *)allMatchesFor:(NSSet *)inAssemblies {
    NSAssert1(0, @"-[PKParser %@] must be overriden",  NSStringFromSelector(_cmd));
    return nil;
}


- (PKAssembly *)bestMatchFor:(PKAssembly *)a {
    NSParameterAssert(a);
    NSSet *initialState = [NSSet setWithObject:a];
    NSSet *finalState = [self matchAndAssemble:initialState];
    return [self best:finalState];
}


- (PKAssembly *)completeMatchFor:(PKAssembly *)a {
    NSParameterAssert(a);
    PKAssembly *best = [self bestMatchFor:a];
    if (best && ![best hasMore]) {
        return best;
    }
    return nil;
}


- (NSSet *)matchAndAssemble:(NSSet *)inAssemblies {
    NSParameterAssert(inAssemblies);

#ifdef MAC_OS_X_VERSION_10_6
#if !TARGET_OS_IPHONE
    if (preassemblerBlock) {
        for (PKAssembly *a in inAssemblies) {
            preassemblerBlock(a);
        }
    } else 
#endif
#endif        
    if (preassembler) {
        NSAssert2([preassembler respondsToSelector:preassemblerSelector], @"provided preassembler %@ should respond to %@", preassembler, NSStringFromSelector(preassemblerSelector));
        for (PKAssembly *a in inAssemblies) {
            [preassembler performSelector:preassemblerSelector withObject:a];
        }
    }
    
    NSSet *outAssemblies = [self allMatchesFor:inAssemblies];

#ifdef MAC_OS_X_VERSION_10_6
#if !TARGET_OS_IPHONE
    if (assemblerBlock) {
        for (PKAssembly *a in outAssemblies) {
            assemblerBlock(a);
        }
    } else 
#endif        
#endif
    if (assembler) {
        NSAssert2([assembler respondsToSelector:assemblerSelector], @"provided assembler %@ should respond to %@", assembler, NSStringFromSelector(assemblerSelector));
        for (PKAssembly *a in outAssemblies) {
            [assembler performSelector:assemblerSelector withObject:a];
        }
    }
    return outAssemblies;
}


- (PKAssembly *)best:(NSSet *)inAssemblies {
    NSParameterAssert(inAssemblies);
    PKAssembly *best = nil;
    
    for (PKAssembly *a in inAssemblies) {
        if (![a hasMore]) {
            best = a;
            break;
        }
        if (!best || a.objectsConsumed > best.objectsConsumed) {
            best = a;
        }
    }
    
    return best;
}


- (NSString *)description {
    NSString *className = [NSStringFromClass([self class]) substringFromIndex:2];
    if (name.length) {
        return [NSString stringWithFormat:@"%@ (%@)", className, name];
    } else {
        return [NSString stringWithFormat:@"%@", className];
    }
}

#ifdef MAC_OS_X_VERSION_10_6
#if !TARGET_OS_IPHONE
@synthesize assemblerBlock;
@synthesize preassemblerBlock;
#endif
#endif
@synthesize assembler;
@synthesize assemblerSelector;
@synthesize preassembler;
@synthesize preassemblerSelector;
@synthesize name;
@end

@implementation PKParser (PKParserFactoryAdditions)

- (id)parse:(NSString *)s {
    PKTokenizer *t = self.tokenizer;
    if (!t) {
        t = [PKTokenizer tokenizer];
    }
    t.string = s;
    PKAssembly *a = [self completeMatchFor:[PKTokenAssembly assemblyWithTokenizer:t]];
    if (a.target) {
        return a.target;
    } else {
        return [a pop];
    }
}


- (PKTokenizer *)tokenizer {
    return [[tokenizer retain] autorelease];
}


- (void)setTokenizer:(PKTokenizer *)t {
    if (tokenizer != t) {
        [tokenizer autorelease];
        tokenizer = [t retain];
    }
}

@end
