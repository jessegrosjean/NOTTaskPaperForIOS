//
//  Path.m
//  PlainText
//
//  Created by Jesse Grosjean on 10/5/10.
//

#import "PathModel.h"
#import "PathController.h"
#include <sys/stat.h>
#include <dirent.h>

@implementation PathModel

+ (NSMutableArray *)pathModelContentsOfDirectory:(NSString *)aPath prefetchAttributes:(BOOL)prefetchAttributes {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSSet *textFileTypes = [PathController textFileTypes];
	const char *pathFileSystemRepresentation = [aPath fileSystemRepresentation];
	char pathBuffer[strlen(pathFileSystemRepresentation) + FILENAME_MAX + 1];
	DIR *dip = opendir(pathFileSystemRepresentation);
	struct dirent *dit;	
	
	if (dip != NULL) {
		NSMutableArray *results = [NSMutableArray array];

		while ((dit = readdir(dip)) != NULL) {
			if (0 == strcmp(".", dit->d_name) || 0 == strcmp("..", dit->d_name))
				continue;

			BOOL localIsDirectory = dit->d_type == DT_DIR;
			NSString *each = [[fileManager stringWithFileSystemRepresentation:dit->d_name length:dit->d_namlen] precomposedStringWithCanonicalMapping];
			
			if (localIsDirectory || [textFileTypes containsObject:[[each pathExtension] lowercaseString]]) {
				NSString *eachName = [[fileManager stringWithFileSystemRepresentation:dit->d_name length:dit->d_namlen] precomposedStringWithCanonicalMapping];
				PathModel *eachPathModel = [[PathModel alloc] initWithParent:aPath name:eachName isDirectory:dit->d_type == DT_DIR];
				
				if (prefetchAttributes) {
					memset(pathBuffer, '\0', sizeof(pathBuffer));
					strcpy(pathBuffer, pathFileSystemRepresentation);
					strcat(pathBuffer, "/");
					strcat(pathBuffer, (char*)dit->d_name);
					[eachPathModel lstat:pathBuffer];
				}
				
				[results addObject:eachPathModel];
				[eachPathModel release];
			}
		}
		
		closedir(dip);
		
		return results;
	} else {
		return nil;
	}	
}

- (id)initWithParent:(NSString *)aParentPath name:(NSString *)aName isDirectory:(BOOL)aBool {
	self = [super init];
	parent = [aParentPath retain];
	name = [aName retain];
	isDirectory = aBool;
	return self;
}

- (void)dealloc {
	[parent release];
	[name release];
	[path release];
	[created release];
	[modified release];
	[super dealloc];
}

- (NSString *)description {
	return [[super description] stringByAppendingFormat:@" %@", name];
}

@synthesize parent;
@synthesize name;

- (NSUInteger)hash {
	return [name hash];
}

- (BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[PathModel class]]) {
		return [name isEqual:[object name]];
	}
	return NO;
}

- (NSString *)path {
	if (!path) {
		path = [[parent stringByAppendingPathComponent:name] retain];
	}
	return path;
}

@synthesize isDirectory;

- (void)lstat:(const char *)pathFileSystemRepresentation {
	if (!pathFileSystemRepresentation) {
		pathFileSystemRepresentation = [[self path] fileSystemRepresentation];
	}
	
	struct stat fileInfo;
	if (0 == lstat(pathFileSystemRepresentation, &fileInfo)) {
		[modified release];
		modified = [[NSDate dateWithTimeIntervalSince1970:fileInfo.st_mtime] retain];
		[created release];
		created = [[NSDate dateWithTimeIntervalSince1970:fileInfo.st_ctime] retain];
	}
}

- (NSDate *)created {
	if (!created) {
		[self lstat:NULL];
	}
	return created;
}

- (NSDate *)modified {
	if (!modified) {
		[self lstat:NULL];
	}
	return modified;
}

@end
