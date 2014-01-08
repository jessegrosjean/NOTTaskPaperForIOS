//
//  GetPathOperation.h
//  SyncTest
//
//  Created by Jesse Grosjean on 8/10/10.
//

#import "PathOperation.h"


@class ShadowMetadata;

@interface GetPathOperation : PathOperation {
	NSString *tempDownloadPath;
}

@end
