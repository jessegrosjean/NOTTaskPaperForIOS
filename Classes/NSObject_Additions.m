//
//  NSObject_Additions.m
//  PlainText
//
//  Created by Jesse Grosjean on 5/20/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "NSObject_Additions.h"
#import <objc/runtime.h> 
#import <objc/message.h>


@implementation NSObject (Additions)

+ (BOOL)replaceClassMethod:(SEL)originalSelelector withMethod:(SEL)newSelector {
	Method originalMethod = class_getClassMethod(self, originalSelelector);	
	if (originalMethod == NULL) {
		LogInfo(@"original class method %@ not found for class %@", NSStringFromSelector(originalSelelector), self);
		return NO;
	}
	
	Method newMethod = class_getClassMethod(self, newSelector);
	if (newMethod == NULL) {
		LogInfo(@"original class method %@ not found for class %@", NSStringFromSelector(newSelector), self);
		return NO;
	}
	
	//if (class_addMethod(self, originalSelelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
	//	class_replaceMethod(self, newSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
	//} else {
		method_exchangeImplementations(originalMethod, newMethod);
	//}
	
	return YES;
}

+ (BOOL)replaceInstanceMethod:(SEL)originalSelelector withMethod:(SEL)newSelector {
	Method originalMethod = class_getInstanceMethod(self, originalSelelector);	
	if (originalMethod == NULL) {
		LogInfo(@"original instance method %@ not found for class %@", NSStringFromSelector(originalSelelector), self);
		return NO;
	}
	
	Method newMethod = class_getInstanceMethod(self, newSelector);
	if (newMethod == NULL) {
		LogInfo(@"original instance method %@ not found for class %@", NSStringFromSelector(newSelector), self);
		return NO;
	}
		
	if (class_addMethod(self, originalSelelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
		class_replaceMethod(self, newSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
	} else {
		method_exchangeImplementations(originalMethod, newMethod);
	}

	return YES;
}

- (void)subclassResponsibilityForSelector:(SEL)aSelector {
	[NSException raise:@"Missing Method" format:@"subclasses of %@ are required to implement %@", NSStringFromClass([self class]), NSStringFromSelector(aSelector)];
}


@end
