//
//  PKLowercaseWord.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 8/13/08.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "PKLowercaseWord.h"
#import "PKToken.h"

@implementation PKLowercaseWord

- (BOOL)qualifies:(id)obj {
    PKToken *tok = (PKToken *)obj;
    if (!tok.isWord) {
        return NO;
    }
    
    NSString *s = tok.stringValue;
    return s.length && islower([s characterAtIndex:0]);
}

@end
