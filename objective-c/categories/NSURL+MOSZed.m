//
// NSURL+MOSZed.m
//
// DEPENDENCIES: NSString+MOSLog, UIImage+MOSZed
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#import "NSURL+MOSZed.h"



//------------------------------------------------ -o--
@implementation NSURL (MOSZed)

#pragma mark - Acquire system directories.

//-------------------------- -o-
+ (NSURL *)  firstSearchPathDirectory: (NSSearchPathDirectory)searchPathDirectory
{
  NSArray  *cacheDirOptions = [[NSFileManager defaultManager] URLsForDirectory:searchPathDirectory inDomains:NSUserDomainMask];

  if ([cacheDirOptions count] < 1) {
    NSString  *dirTypeName = nil;

    switch(searchPathDirectory) {
    case NSCachesDirectory:
      dirTypeName = @"NSCachesDirectory";
      break;
    case NSDocumentDirectory:
      dirTypeName = @"NSDocumentDirectory";
      break;
    case NSLibraryDirectory:
      dirTypeName = @"NSLibraryDirectory";
      break;
    case NSUserDirectory:
      dirTypeName = @"NSUserDirectory";
      break;
    default:
      dirTypeName = @"(UNKNOWN DIRECTORY TYPE NAME)";
    }

    MOS_LOG_ERROR(@"COULD NOT acquire path to %@.", dirTypeName); 
    return nil;
  }

  return cacheDirOptions[0];
}

//-------------------------- -o-
+ (NSURL *)  firstUserCacheDirectory
{
  return [self firstSearchPathDirectory:NSCachesDirectory];
}

//-------------------------- -o-
+ (NSURL *)  firstUserDocumentsDirectory
{
  return [self firstSearchPathDirectory:NSDocumentDirectory];
}

//-------------------------- -o-
+ (NSURL *)  userRootDirectory
{
  return [NSURL fileURLWithPath:[@"~" stringByExpandingTildeInPath] isDirectory:YES];
}




//------------------------------------------------ -o--
#pragma mark - File and directory management.

//-------------------------- -o-
- (BOOL)  doesExist
{
  return [[NSFileManager defaultManager] fileExistsAtPath:[self path]];
}

//-------------------------- -o-
- (BOOL)  isFile
{
  BOOL  fsObjectIsDirectory  = NO;
  BOOL  fsObjectExists       = [[NSFileManager defaultManager] fileExistsAtPath:[self path] isDirectory:&fsObjectIsDirectory];

  return (fsObjectExists) ? (!fsObjectIsDirectory) : NO;
}

//-------------------------- -o-
- (BOOL)  isDirectory
{
  BOOL  fsObjectIsDirectory  = NO;
  BOOL  fsObjectExists       = [[NSFileManager defaultManager] fileExistsAtPath:[self path] isDirectory:&fsObjectIsDirectory];

  return (fsObjectExists) ? fsObjectIsDirectory : NO;
}



//-------------------------- -o-
- (BOOL)  remove
{
  NSFileManager  *fileMgr  = [NSFileManager defaultManager];
  NSError        *error    = nil;


  if (! [self doesExist]) {
    //MOS_LOG_WARNING(@"Item to be removed does not exist.  (%@)", self);
    return YES;
  }

  if (! [fileMgr removeItemAtPath:[self path] error:&error]) 
  {
    MOS_LOG_NSERROR(error);
    MOS_LOG_ERROR(@"Failed to remove item.  (%@)", self);
    return NO;
  }

  return YES;
}



//-------------------------- -o-
// createDirectoryWithReplace: 
//
// RETURNS:  YES  if directory exists or is successfully created;
//           NO   on error or if directoryURL is not a directory when replace is NO.
//
- (BOOL)  createDirectoryWithReplace: (BOOL)replace
{
  NSFileManager  *fileMgr  = [NSFileManager defaultManager];
  NSError        *error    = nil;

  //
  BOOL  fsObjectIsDirectory  = NO;
  BOOL  fsObjectExists       = [fileMgr fileExistsAtPath:[self path] isDirectory:&fsObjectIsDirectory];
  
  if (fsObjectExists) {
    if (!replace) {
      if (fsObjectIsDirectory) { 
        return YES; 
      } else {
        return NO; 
      }
    }

    if (![self remove]) { 
      return NO; 
    }
  }

  //
  if (! [fileMgr createDirectoryAtURL:self withIntermediateDirectories:YES attributes:nil error:&error])
  {
    MOS_LOG_NSERROR(error);
    MOS_LOG_ERROR(@"Failed to create directory.  (%@)", self);
    return NO;
  }

  return YES;

} // createDirectoryWithReplace: 



//-------------------------- -o-
- (BOOL)  createDirectoryPathToFile
{
  return [[self URLByDeletingLastPathComponent] createDirectory];
}


//-------------------------- -o-
- (BOOL)  createDirectory
{
  return [self createDirectoryWithReplace:NO];
}

//-------------------------- -o-
- (BOOL)  replaceDirectory
{
  return [self createDirectoryWithReplace:YES];
}



//-------------------------- -o-
- (NSURL *) appendPathToDirectory: (NSString *)path
{
  return [self URLByAppendingPathComponent:path isDirectory:YES];
}

//-------------------------- -o-
- (NSURL *) appendPathToFile: (NSString *)path
{
  return [self URLByAppendingPathComponent:path isDirectory:NO];
}

//-------------------------- -o-
- (NSURL *) appendExtension: (NSString *)extension
{
  return [self URLByAppendingPathExtension:extension];
}

//-------------------------- -o-
- (NSURL *) appendPathToFile: (NSString *)path
               withExtension: (NSString *)extension
{
  return [[self appendPathToFile:path] appendExtension:extension];
}




//------------------------------------------------ -o--
#pragma mark - File, directory and file system utilities.

//------------------- -o-
// fileSizeIncludingResourceFork: 
//
// RETURNS:
//   -1         on error  -or-  if url is not a file;
//   otherwise  size of file (INCLUDING resource fork per includeResourceFork).
//
// ASSUME  [NSURL checkResourceIsReachableAndReturnError:] returns error for non-files. 
//
- (NSInteger)  fileSizeIncludingResourceFork: (BOOL)includeResourceFork
{
  NSError  *error = nil;

  if (error) {
    MOS_LOG_NSERROR(error);
    MOS_LOG_ERROR(@"FAILED to assess whether URL is file or otherwise.  (%@)", self);
    return -1;
  }

  if (![self isFile]) {
    MOS_LOG_WARNING(@"URL is NOT a file.  (%@)", self);
    return -1; 
  }


  //
  NSDictionary *keyResults = [self resourceValuesForKeys: @[NSURLFileSizeKey, NSURLTotalFileAllocatedSizeKey]
                                                   error: &error];
  if (error) { 
    MOS_LOG_NSERROR(error);
    MOS_LOG_ERROR(@"FAILED to assess file size.  (%@)", self);
    return -1; 
  }


  //
  NSInteger  size;

  if (includeResourceFork) {
    size = [[keyResults objectForKey:NSURLTotalFileAllocatedSizeKey] integerValue];
  } else {
    size = [[keyResults objectForKey:NSURLFileSizeKey] integerValue];
  }

  return size;

} // fileSizeIncludingResourceFork: 



//-------------------------- -o-
// directoryList
//
// RETURN:  Array of NSURL.
//
- (NSMutableArray *) directoryList
{
  NSFileManager  *fileMgr = [NSFileManager defaultManager];
  NSError        *error   = nil;


  NSMutableArray  *directoryListing =
                       [[fileMgr contentsOfDirectoryAtURL:  self
                               includingPropertiesForKeys:  nil
                                                  options:  NSDirectoryEnumerationSkipsHiddenFiles
                                                    error: &error]  mutableCopy];
  if (error) {
    MOS_LOG_NSERROR(error);
    MOS_LOG_ERROR(@"FAILED to read directory.  (%@)", [self path]);
    return nil;
  }

  return directoryListing;
}



//-------------------------- -o-
// fileAttributeWithName: 
//
// RETURN:  Value of attributeName, or nil.
//
- (id)  fileAttributeWithName: (NSString *)attributeName
{
  NSError        *error    = nil;
  NSDictionary   *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:[self path] error:&error ];

  if (error) {
    MOS_LOG_NSERROR(error);
    MOS_LOG_ERROR(@"FAILED to acquire file attribute \"%@\" at URL.  (%@)", attributeName, [self path]);
    return nil;
  }
  
  return [dict objectForKey:attributeName];
}



//-------------------------- -o-
// fileSystemAttributeWithName: 
//
// RETURN:  Value of attributeName  -OR-  MOS_ULONGLONG_MAX on error.
//
- (unsigned long long)  fileSystemAttributeWithName: (NSString *)attributeName
{
  NSError        *error    = nil;
  NSDictionary   *dict = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[self path] error:&error];

  if (error) {
    MOS_LOG_NSERROR(error);
    MOS_LOG_ERROR(@"FAILED to acquire file system attributes at URL.  (%@)", [self path]);
    return ULONG_LONG_MAX;
  }
  
  return [[dict objectForKey:attributeName] unsignedLongLongValue];
}



//-------------------------- -o-
- (UIImage *) readAsUIImage 
{
  return [UIImage imageFromURL:self];
}


//-------------------------- -o-
- (NSString *) readAsNSString
{
  NSData   *stringdata;
  NSError  *error;


  stringdata = [NSData dataWithContentsOfURL:  self
                                     options:  NSDataReadingUncached
                                       error: &error ];
  if (!stringdata) { 
    MOS_LOG_NSERROR(error);
    MOS_LOG_ERROR(@"FAILED to read data from URL.  (%@)", self);
    return nil;
  }

  return [[NSString alloc] initWithData:stringdata encoding:NSUTF8StringEncoding];
}



@end

