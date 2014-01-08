//
//  TreeUndoManager.m
//  Documents
//
//  Created by Jesse Grosjean on 4/13/10.
//

#import "TreeUndoManager.h"


@implementation TreeUndoManager

- (void)setActionName:(NSString *)actionName {
	[super setActionName:actionName];
	//NSLog(@"setActionName &@", actionName);
}

- (void)beginUndoGrouping {
	//NSLog(@"beginUndoGrouping", nil);
	[super beginUndoGrouping];
}

- (void)endUndoGrouping {
	//NSLog(@"endUndoGrouping", nil);
	[super endUndoGrouping];
}

- (void)registerUndoWithTarget:(id)target selector:(SEL)aSelector object:(id)anObject {
	//NSLog(@"registerUndoWithTarget", nil);
	[super registerUndoWithTarget:target selector:aSelector object:anObject];
}

- (id)prepareWithInvocationTarget:(id)target {
	//NSLog(@"prepareWithInvocationTarget", nil);
	return [super prepareWithInvocationTarget:target];
}

@end
