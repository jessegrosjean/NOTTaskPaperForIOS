//
//  NSFileManager+DirectoryLocations.m
//
//  Created by Matt Gallagher on 06 May 2010
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "NSFileManager_Additions.h"
#import "NSString_Additions.h"
#import <DropboxSDK/NSString+Dropbox.h>
#import "NSSet_Additions.h"

enum
{
	DirectoryLocationErrorNoPathFound,
	DirectoryLocationErrorFileExistsAtLocation
};

NSString * const DirectoryLocationDomain = @"DirectoryLocationDomain";


@implementation NSFileManager (Additions)

/*
+ (void)load {
    if (self == [NSFileManager class]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[NSFileManager replaceMethod:@selector(createDirectoryAtPath:attributes:) withMethod:@selector(my_createDirectoryAtPath:attributes:)];
		[NSFileManager replaceMethod:@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:) withMethod:@selector(my_createDirectoryAtPath:withIntermediateDirectories:attributes:error:)];
		[pool release];
    }
}

- (BOOL)my_createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes error:(NSError **)error {
	LogInfo(@"               CREATE DIRECTORY %@", path);
	return [self my_createDirectoryAtPath:path withIntermediateDirectories:createIntermediates attributes:attributes error:error];
}

- (BOOL)my_createDirectoryAtPath:(NSString *)path attributes:(NSDictionary *)attributes {
	LogInfo(@"               CREATE DIRECTORY %@", path);
	return [self my_createDirectoryAtPath:path attributes:attributes];
}*/

//
// findOrCreateDirectory:inDomain:appendPathComponent:error:
//
// Method to tie together the steps of:
//	1) Locate a standard directory by search path and domain mask
//  2) Select the first path in the results
//	3) Append a subdirectory to that path
//	4) Create the directory and intermediate directories if needed
//	5) Handle errors by emitting a proper NSError object
//
// Parameters:
//	searchPathDirectory - the search path passed to NSSearchPathForDirectoriesInDomains
//	domainMask - the domain mask passed to NSSearchPathForDirectoriesInDomains
//	appendComponent - the subdirectory appended
//	errorOut - any error from file operations
//
// returns the path to the directory (if path found and exists), nil otherwise
//
- (NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory
						   inDomain:(NSSearchPathDomainMask)domainMask
				appendPathComponent:(NSString *)appendComponent
							  error:(NSError **)errorOut
{
	//
	// Search for the path
	//
	NSArray* paths = NSSearchPathForDirectoriesInDomains(
														 searchPathDirectory,
														 domainMask,
														 YES);
	if ([paths count] == 0)
	{
		if (errorOut)
		{
			NSDictionary *userInfo =
			[NSDictionary dictionaryWithObjectsAndKeys:
			 NSLocalizedStringFromTable(
										@"No path found for directory in domain.",
										@"Errors",
										nil),
			 NSLocalizedDescriptionKey,
			 [NSNumber numberWithInteger:searchPathDirectory],
			 @"NSSearchPathDirectory",
			 [NSNumber numberWithInteger:domainMask],
			 @"NSSearchPathDomainMask",
			 nil];
			*errorOut =
			[NSError 
			 errorWithDomain:DirectoryLocationDomain
			 code:DirectoryLocationErrorNoPathFound
			 userInfo:userInfo];
		}
		return nil;
	}
	
	//
	// Normally only need the first path returned
	//
	NSString *resolvedPath = [paths objectAtIndex:0];
	
	//
	// Append the extra path component
	//
	if (appendComponent)
	{
		resolvedPath = [resolvedPath
						stringByAppendingPathComponent:appendComponent];
	}
	
	//
	// Check if the path exists
	//
	BOOL exists;
	BOOL isDirectory;
	exists = [self
			  fileExistsAtPath:resolvedPath
			  isDirectory:&isDirectory];
	if (!exists || !isDirectory)
	{
		if (exists)
		{
			if (errorOut)
			{
				NSDictionary *userInfo =
				[NSDictionary dictionaryWithObjectsAndKeys:
				 NSLocalizedStringFromTable(
											@"File exists at requested directory location.",
											@"Errors",
											nil),
				 NSLocalizedDescriptionKey,
				 [NSNumber numberWithInteger:searchPathDirectory],
				 @"NSSearchPathDirectory",
				 [NSNumber numberWithInteger:domainMask],
				 @"NSSearchPathDomainMask",
				 nil];
				*errorOut =
				[NSError 
				 errorWithDomain:DirectoryLocationDomain
				 code:DirectoryLocationErrorFileExistsAtLocation
				 userInfo:userInfo];
			}
			return nil;
		}
		
		//
		// Create the path if it doesn't exist
		//
		NSError *error = nil;
		[self
		 createDirectoryAtPath:resolvedPath
		 withIntermediateDirectories:YES
		 attributes:nil
		 error:&error];
		if (error) 
		{
			if (errorOut)
			{
				*errorOut = error;
			}
			return nil;
		}
	}
	
	if (errorOut) {
		*errorOut = nil;
	}
	
	return resolvedPath;
}

//
// applicationSupportDirectory
//
// Returns the path to the applicationSupportDirectory (creating it if it doesn't
// exist).
//
- (NSString *)applicationSupportDirectory
{
	NSString *executableName =
	[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
	NSError *error = nil;
	NSString *result =
	[self
	 findOrCreateDirectory:NSApplicationSupportDirectory
	 inDomain:NSUserDomainMask
	 appendPathComponent:executableName
	 error:&error];
	if (error) {
		NSLog(@"Unable to find or create application support directory:\n%@", error);
	}
	return result;
}

- (NSString *)documentDirectory {
	NSError *error = nil;
	NSString *result = [self findOrCreateDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appendPathComponent:nil error:&error];
	if (error) {
		NSLog(@"Unable to find or create document directory:\n%@", error);
	}
	return result;
}

- (NSString *)readOnlyInboxDirectory {
	static NSString *readOnlyInboxDirectory = nil;
	if (!readOnlyInboxDirectory) {
		readOnlyInboxDirectory = [[[self documentDirectory] stringByAppendingPathComponent:@"Inbox"] retain];
	}
	return readOnlyInboxDirectory;
}

- (NSString *)cachesDirectory {
	NSError *error = nil;
	NSString *result = [self findOrCreateDirectory:NSCachesDirectory inDomain:NSUserDomainMask appendPathComponent:nil error:&error];
	if (error) {
		NSLog(@"Unable to find or create caches directory:\n%@", error);
	}
	return result;
}

- (NSString *)tempDirectory {
	NSString *tempDirectory = NSTemporaryDirectory();
	NSError *error;
	
	if (![self createDirectoryAtPath:tempDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
		NSLog(@"Unable to find or create temp directory:\n%@", error);
	}
	
	return tempDirectory;
}

- (NSString *)tempDirectoryUnusedPath {
	return [[self tempDirectory] stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
}

- (BOOL)my_moveItemAtPath:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error {
	if ([fromPath isEqualToDropboxPath:toPath]) {
		NSString *unusedPath = [self tempDirectoryUnusedPath];
		if ([self moveItemAtPath:fromPath toPath:unusedPath error:error]) {
			if ([self moveItemAtPath:unusedPath toPath:toPath error:error]) {
				return YES;
			}
		}
		return NO;
	} else {
		return [self moveItemAtPath:fromPath toPath:toPath error:error];
	}
}

- (NSString *)conflictPathForPath:(NSString *)aPath error:(NSError **)error {
	return [self conflictPathForPath:aPath includeMessage:YES error:error];
}

- (NSString *)conflictPathForPath:(NSString *)aPath includeMessage:(BOOL)includeMessage error:(NSError **)error {
	NSString *directory = [aPath stringByDeletingLastPathComponent];
	NSString *filename = [aPath lastPathComponent];
	
	if (![self createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:error]) {
		return nil;
	}
	
	NSArray *normalizedContents = [[self contentsOfDirectoryAtPath:directory error:error] valueForKey:@"normalizedDropboxPath"];
	NSSet *normalizedContentsSet = [NSSet setWithArray:normalizedContents];
	NSString *conflictName = [normalizedContentsSet conflictNameForNameInNormalizedSet:filename includeMessage:includeMessage];
	
	return [directory stringByAppendingPathComponent:conflictName];
}

@end
