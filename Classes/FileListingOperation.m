//
//  FileListingOperation.m
//  PlainText
//
//  Created by Jesse Grosjean on 1/4/11.
//  Copyright 2011 Hog Bay Software. All rights reserved.
//

#import "FileListingOperation.h"
#import "PathModel.h"

#import "ApplicationController.h"
#import "PathController.h"

@implementation FileListingOperation

- (id)initWithPath:(NSString *)aPath isRecursive:(BOOL)aBool filter:(NSString *)aFilter delegate:(id)aDelegate {
	self = [super init];
	if (self) {
		isExecuting = NO;
		isFinished = NO;
		isRecursive = aBool;
		path = [aPath copy];
		filter = [aFilter copy];
		results = [[NSMutableArray alloc] init];
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[path release];
	[filter release];
	[results release];
	delegate = nil;
	[super dealloc];
}

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isExecuting {
	return isExecuting;
}

- (BOOL)isFinished {
	return isFinished;
}

- (void)start {
	if ([self isCancelled]) {
		[self willChangeValueForKey:@"isFinished"];
		isFinished = YES;
		[self didChangeValueForKey:@"isFinished"];
		return;
	}
	
	[self willChangeValueForKey:@"isExecuting"];
	[NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
	isExecuting = YES;
	[self didChangeValueForKey:@"isExecuting"];
	[delegate fileListingOperationStarted:self];
}

- (void)cancel {
	delegate = nil;
	[super cancel];
}

@synthesize results;

- (void)listResultsAtPath:(NSString *)aPath {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *contentsOfDirectory = [PathModel pathModelContentsOfDirectory:aPath prefetchAttributes:NO];
    	
	if (filter != nil && [filter length] > 0) {
		for (PathModel *each in contentsOfDirectory) {
			if (self.isCancelled) {
				[pool release];
				return;
			}
			
			NSStringCompareOptions filterOptions = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch;
			
			if ([each.name rangeOfString:filter options:filterOptions].location != NSNotFound) {
				[results addObject:each];
			} else if (!each.isDirectory) {
				NSError *error;
				NSStringEncoding stringEncoding;
				NSString *fileContents = [[NSString alloc] initWithContentsOfFile:each.path usedEncoding:&stringEncoding error:&error];
				
				if (!fileContents) {
					fileContents = [[NSString alloc] initWithContentsOfFile:each.path encoding:NSUTF8StringEncoding error:&error];
				}
				
				if (fileContents) {
					if ([fileContents rangeOfString:filter options:filterOptions].location != NSNotFound) {
						[results addObject:each];
					}
					[fileContents release];
				}
			}
			
			if (isRecursive && each.isDirectory) {
				[self listResultsAtPath:each.path];
			}
		}
	} else {
		[results addObjectsFromArray:contentsOfDirectory];
	}

	[pool release];
} 

- (void)notifiyDelegateOnMainThread {
	[delegate fileListingOperationCompleted:self];
}

- (void)main {
	@try {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		if (!self.isCancelled) {
			[self listResultsAtPath:path];
			
			[self willChangeValueForKey:@"isFinished"];
			[self willChangeValueForKey:@"isExecuting"];
			
			isExecuting = NO;
			isFinished = YES;
			
			[self didChangeValueForKey:@"isExecuting"];
			[self didChangeValueForKey:@"isFinished"];			
			
			[self performSelectorOnMainThread:@selector(notifiyDelegateOnMainThread) withObject:nil waitUntilDone:NO];
		}
		
		[pool release];
	} @catch(...) {
	}
}

@end