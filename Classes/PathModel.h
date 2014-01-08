//
//  Path.h
//  PlainText
//
//  Created by Jesse Grosjean on 10/5/10.
//

#import <Foundation/Foundation.h>


@interface PathModel : NSObject {
	NSString *parent;
	NSString *name;
	NSString *path;
	NSDate *created;
	NSDate *modified;
	BOOL isDirectory;
}

+ (NSMutableArray *)pathModelContentsOfDirectory:(NSString *)aPath prefetchAttributes:(BOOL)prefetchAttributes;

- (id)initWithParent:(NSString *)aParentPath name:(NSString *)aName isDirectory:(BOOL)aBool;

- (void)lstat:(const char *)pathFileSystemRepresentation;

@property(nonatomic, readonly) NSString *parent;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSString *path;
@property(nonatomic, readonly) BOOL isDirectory;
@property(nonatomic, readonly) NSDate *created;
@property(nonatomic, readonly) NSDate *modified;

@end
