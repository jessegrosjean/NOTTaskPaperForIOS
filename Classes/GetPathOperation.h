//
//  GetPathOperation.h
//  SyncTest
//
//  Created by Jesse Grosjean on 8/10/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "PathOperation.h"


@class ShadowMetadata;

@interface GetPathOperation : PathOperation {
	NSString *tempDownloadPath;
}

@end
