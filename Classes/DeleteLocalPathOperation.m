//
//  DeleteLocalPathOperation.m
//  SyncTest
//
//  Created by Jesse Grosjean on 8/11/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

#import "DeleteLocalPathOperation.h"
#import "ShadowMetadataTextBlob.h"
#import "FolderSyncPathOperation.h"
#import "PathController.h"
#import "ShadowMetadata.h"

@implementation DeleteLocalPathOperation

- (void)main {
	[self deleteLocalPath];
}

@end
