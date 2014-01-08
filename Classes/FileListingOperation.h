//
//  FileListingOperation.h
//  PlainText
//
//  Created by Jesse Grosjean on 1/4/11.
//

#import <Foundation/Foundation.h>

@protocol FileListingOperationDelegate;

@interface FileListingOperation : NSOperation {
	BOOL isExecuting;
	BOOL isFinished;
	BOOL isRecursive;
	NSString *path;
	NSString *filter;
	NSMutableArray *results;
	id<FileListingOperationDelegate> delegate;
}

- (id)initWithPath:(NSString *)aPath isRecursive:(BOOL)isRecursive filter:(NSString *)aFilter delegate:(id<FileListingOperationDelegate>)aDelegate;

@property (readonly, nonatomic) NSArray *results;

@end

@protocol FileListingOperationDelegate

- (void)fileListingOperationStarted:(FileListingOperation *)aFileListingOperation;
- (void)fileListingOperationCompleted:(FileListingOperation *)aFileListingOperation;

@end
