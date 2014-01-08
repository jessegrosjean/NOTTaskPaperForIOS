//
//  DeletePathOperation.m
//  SyncTest
//
//  Created by Jesse Grosjean on 8/11/10.
//

#import "DeletePathOperation.h"
#import "FolderSyncPathOperation.h"
#import "ApplicationController.h"
#import "ShadowMetadata.h"
#import "PathController.h"

@implementation DeletePathOperation

- (BOOL)isDeleteOperation {
	return YES;
}

- (void)main {
	if (!pathController.isServerReachable) {
		[self finish:[NSError errorWithDomain:NSURLErrorKey code:NSURLErrorNetworkConnectionLost userInfo:nil]];
		return;
	}
	
	if ([self validateLocalPath]) {
		[self.client deletePath:[pathController localPathToServer:localPath]];
	}
}

- (void)restClient:(DBRestClient*)aClient deletedPath:(NSString *)aServerPath {
	[pathController deleteShadowMetadataForLocalPath:localPath];
	self.createShadowMetadataOnFinish = NO;
	[self finish];
}

- (void)restClient:(DBRestClient*)aClient deletePathFailedWithError:(NSError*)error {
	[self retryWithError:error];
}

@end
