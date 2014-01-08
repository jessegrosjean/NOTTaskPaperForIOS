//
//  ShadowMetadataTextContent.h
//  MyTestable
//
//  Created by Jesse Grosjean on 8/22/10.
//

#import <CoreData/CoreData.h>
#import <DropboxSDK/DropboxSDK.h>


@interface ShadowMetadataTextBlob : NSManagedObject { }
@property(nonatomic, retain) NSString *text;
@end
