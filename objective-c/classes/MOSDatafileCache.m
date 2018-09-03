//
// MOSDatafileCache.m
//
// Manage directory of files as LRU cache.
// 
//
// saveData:withFilename: is instrumented with two control flags and one response flag -- 
// alwaysOverwriteDatafile, doNotRemoveFilesWhenCacheIsFull, and fileSizeExceedsFreeBytes, respectively.
// These behaviors are encapsulated by the following sibling methods:
// 
//   saveData:withFilename:
//     Standard use of LRU cache.  Data is NOT overwritten if it already exists.
//     If the data size is greater than cacheSizeFreeBytes, then LRU files are removed to make room.
//
//   overwriteData:withFilename:
//     Standard use of LRU cache.  Data is overwritten if it already exists.
//     If the data size is greater than cacheSizeFreeBytes, then LRU files are removed to make room.
//
//   saveData:withFilename:cacheOverflow:
//     LRU files are not deleted.  Data is NOT overwritten if it already exists.
//     cacheOverflow returns YES if writing the data would exceed cacheSizeFreeBytes.
//
//   overwriteData:withFilename:cacheOverflow: 
//     LRU files are not deleted.  Data is overwritten if it already exists.
//     cacheOverflow returns YES if writing the data would exceed cacheSizeFreeBytes.
//
//
// NB  Regarding resource forks--  
//       . cacheSizeFreeBytes takes into account the size of resource forks.
//       . Size of file resource forks cannot be computed in advance.
//       . cacheSizeFreeBytes may, therefore, be less than zero if size of 
//           most recently saved file closely approximates or matches 
//           cacheSizeFreeBytes. 
//       . This anomaly of size will be naturally corrected the next time a 
//           file is added to the cache.
//
// NB  The cache managed by this class is NOT cryptographically secure.
// NB  This class is NOT thread safe.
//
//
// CLASS DEPENDENCIES:  
//   NSString+MOSLog
//   NSData+MOSZed
//   NSDate+MOSZed
//   NSURL+MOSZed
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#import "MOSDatafileCache.h"




//------------------------------------------------------------ -o--
@interface MOSDatafileCache() 

  //
  @property  (readwrite, strong, nonatomic)  NSURL                *cacheDirURL;

  @property  (readwrite, strong, nonatomic)  NSURL                *propertyListURL;
  @property  (strong, nonatomic)             NSMutableDictionary  *propertyList;
  @property  (strong, nonatomic)             NSMutableDictionary  *datafileDictionary;

  @property  (readwrite, strong, nonatomic)  NSURL                *dataDirURL;
  @property  (strong, nonatomic)             NSMutableArray       *dataDirContents;

  @property  (readwrite, nonatomic)          dispatch_queue_t      queue;


  // NB  A signed value allows the case where sum of pre-existing file(s) 
  //     is greater then requested cache size.  (See makeBytesAvailable:.)
  //
  //     XXX  Broken by MOS_DFC_LONGLONG_IS_BROKEN.
  //
  @property  (nonatomic)  MOS_DFC_LONGLONG  cacheSizeMaximumBytes;
  @property  (nonatomic)  MOS_DFC_LONGLONG  cacheSizeFreeBytes;


  //
  @property  (nonatomic)  BOOL  doNotRemoveFilesWhenCacheIsFull;
      // YES refuses data save and makes no changes to cache contents if new file exceeds free bytes.
      //   Encapsulated in saveData:withFilename:cacheOverflow:.

  @property  (nonatomic)  BOOL  fileSizeExceedsFreeBytes;
      // YES if data save is prevented when doNotRemoveFilesWhenCacheIsFull==YES.

  @property  (nonatomic)  BOOL  alwaysOverwriteDatafile;
      // YES forces pre-existing files in the cache by the same name to be overwritten.
      //   Encapsulated in overwriteData:withFilename:cacheOverflow:.


  // Private system resources for this instance.
  //
  @property  (strong, nonatomic)  NSFileManager  *fileManager;


  // Private methods.
  //
  - (void)  updateDatafileDictionaryObject: (id)          object
                                    forKey: (NSString *)  key;

  - (void)  removeDatafileDictionaryObjectForKey: (NSString *)object;

  - (BOOL) sync;

@end




//------------------------------------------------------------ -o--
@implementation MOSDatafileCache

#pragma mark - Constructors.

//------------------------ -o-
// initCacheDirectoryWithURL:sizeInBytes: 
//
// INPUTS--
//   cacheDirURL  Valid URL  -OR-  nil to use system path + default basename.
//   sizeInBytes  Size of cache.  
//
// Upon successful return, data directory and property list are consistent with one another.
//
// MOS_DFC_CACHEDIR_BASENAME and MOS_DFC_CACHEDIR_DATADIR_NAME are removed if they exist and are not directories.
// If one of data directory or property list does not exist, the other is removed.
//
- (id) initCacheDirectoryWithURL: (NSURL *)           cacheDirURL__
                  inSubdirectory: (NSString *)        subdirectoryName__
                     sizeInBytes: (MOS_DFC_LONGLONG)  sizeInBytes__
{
  // Sanity check inputs.
  // Initialize properties.
  //
  if (sizeInBytes__ < 1)                                       
  {
    MOS_LOG_ERROR(@"Cache size must be greater than zero.");
    return nil;
  }

  if (!(self = [super init])) {
    MOS_LOG_ERROR(@"[super init] FAILED.");
    return nil;
  }

  //
  self.cacheDirURL            = cacheDirURL__;
  self.cacheSizeMaximumBytes  = sizeInBytes__;

  self.verbose = NO;



  // Establish pathnames to cacheDir elements.
  // Sanity check and instantiate data directory and property list.
  // If one of data directory or property list is missing, delete the other.
  //
  if (!self.cacheDirURL) {                                      
    self.cacheDirURL = [[NSURL firstUserCacheDirectory] appendPathToDirectory:MOS_DFC_CACHEDIR_BASENAME_DEFAULT];
  }

  if (subdirectoryName__) { 
    self.cacheDirURL = [self.cacheDirURL appendPathToDirectory:subdirectoryName__];
  }


  if (! [self.cacheDirURL createDirectory])  { return nil; }

  self.dataDirURL       = [self.cacheDirURL URLByAppendingPathComponent:MOS_DFC_CACHEDIR_DATADIR_NAME isDirectory:YES];
  self.propertyListURL  = [self.cacheDirURL URLByAppendingPathComponent:MOS_DFC_CACHEDIR_PROPERTYLIST_NAME];


  //
  BOOL  dataPathExists       = NO;
  BOOL  dataPathIsDirectory  = NO;

  self.propertyList  = [[NSDictionary dictionaryWithContentsOfURL:self.propertyListURL] mutableCopy];
  dataPathExists     = [self.fileManager fileExistsAtPath:[self.dataDirURL path] isDirectory:&dataPathIsDirectory];

  NSString  *dataPathErrorMsg = nil;


  if (dataPathExists)
  {
    if (!dataPathIsDirectory) {                                 
      dataPathErrorMsg = MOS_STRWFMT(@"REMOVING file with same name as data directory.  (%@)", self.dataDirURL);
    } else if (!self.propertyList) {                            
      dataPathErrorMsg = MOS_STRWFMT(@"REMOVING data directory because property list is missing.  (%@)", self.dataDirURL);
    }

  }

  if (self.propertyList) 
  {
    if ((!dataPathExists) || dataPathErrorMsg) {                
      dataPathErrorMsg = MOS_STRWFMT(@"REMOVING property list because data directory is missing or corrupt.  (%@)", self.propertyListURL);
    }
  }


  if (dataPathErrorMsg)                                         
  {
    MOS_LOG_WARNING(@"%@", dataPathErrorMsg);

    if (! (    [self.dataDirURL remove] 
            && [self.propertyListURL remove] ) )
    {
      return nil;
    }

    dataPathExists = NO;
  }



  // (Re)create property list and data directory
  //    -OR-
  // Check consistency of property list versus data directory.
  //
  MOS_DFC_LONGLONG  sumOfDatafileSizes = 0;


  if (!dataPathExists)  
  {
    if (! [self.dataDirURL replaceDirectory])  { return nil; }

    self.propertyList = [[NSMutableDictionary alloc] init];

    if (self.verbose) {
      MOS_LOG_INFO(@"CREATED property list and data directory for cache directory.  (%@)", self.cacheDirURL);
    }


  } else {
    NSDictionary         *dictOfFilesOnRecord  = self.datafileDictionary;
    NSMutableDictionary  *newDict              = [[NSMutableDictionary alloc] init];

    NSMutableArray       *dataDirList          = [self.dataDirURL directoryList];


    if (!dataDirList)  { return nil; }
    

    // After for-loop--
    //   . newDict is a copy of dictOfFilesOnRecord, but only contains files 
    //       that exist and have a timestamp;
    //   . dataDirList contains files that were not in dictOfFilesOnRecord;
    //   . sumOfDatafileSizes is the total size (including resource forks) of all files 
    //       listed in newDict.
    //
    for (id key in dictOfFilesOnRecord)         
    {
      NSNumber  *timestamp = (NSNumber *)[dictOfFilesOnRecord objectForKey:key];

      if (!timestamp) {                                         
        MOS_LOG_WARNING(@"Property list entry missing timestamp.  (%@)", key);
        continue;
      }

      NSURL  *dataDirEntry = [self.dataDirURL URLByAppendingPathComponent:key];
      if (![dataDirList containsObject:dataDirEntry]) {         
        MOS_LOG_WARNING(@"Property list entry missing in data directory.  (%@)", key);
        continue;
      } 

      //
      NSInteger  dataDirEntryFileSize = [dataDirEntry fileSizeIncludingResourceFork:YES];

      if (dataDirEntryFileSize < 0)                             
      {
        MOS_LOG_WARNING(@"File in data directory is corrupt or missing.  (%@)", key);

        if (! [dataDirEntry remove]) {            
          MOS_LOG_ERROR(@"Could not remove errant data directory file.  (%@)", key);
          return nil;  // XXX -- Option to let this slide?
        }

        [dataDirList removeObject:dataDirEntry];
        continue;

      } else {
        sumOfDatafileSizes += dataDirEntryFileSize;
      }

      //
      [dataDirList removeObject:dataDirEntry];
      [newDict setObject:timestamp forKey:key];

    } // endfor


    //
    self.datafileDictionary = newDict;

    if (![self sync]) {
      MOS_LOG_ERROR(@"FAILED to write property list after synchronizing with data directory.  (%@)", self.propertyListURL); 
      return nil;
    }


    //
    if ([dataDirList count] > 0)                                
    {
      __block  BOOL  stopped = NO;

      [dataDirList enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop)
        {
          if (! [(NSURL *)obj remove]) {
            stopped  = YES;
            *stop    = YES;
          }
        }];

      if (stopped) {                                            
        MOS_LOG_ERROR(@"FAILED to remove data file(s) that do not appear in property list.");
        return nil;  // XXX -- Option to let this slide?
      }
    } 

  } // end-ifelse !dataPathExists



#if !defined(MOS_DFC_LONGLONG_IS_BROKEN)
  // Compute maximum and free bytes.
  //
  BOOL  doesCacheHaveOverflow = [[self.propertyList objectForKey:MOS_DFC_CACHE_OVERFLOW_OKAY_KEY] boolValue];

  if ( (!doesCacheHaveOverflow) && (sumOfDatafileSizes > self.cacheSizeMaximumBytes) )
  {
    MOS_DFC_LONGLONG  difference = (sumOfDatafileSizes - self.cacheSizeMaximumBytes);

    MOS_LOG_WARNING(@"Sum of previously cached data (%lld) is greater than cache size.  DELETING cached items...", difference);

    self.cacheSizeFreeBytes = -difference;

    if (! [self makeBytesAvailable:0]) {
      MOS_LOG_ERROR(@"FAILED to free enough space for request cache size.");
      return nil;
    }

  } else {
    self.cacheSizeFreeBytes = self.cacheSizeMaximumBytes - sumOfDatafileSizes;
  }

#else
    self.cacheSizeFreeBytes = self.cacheSizeMaximumBytes - sumOfDatafileSizes;
#endif


  //
  unsigned long long  fileSystemFreeBytes =
                        [self.cacheDirURL fileSystemAttributeWithName:NSFileSystemFreeSize]; 
  if (ULONG_LONG_MAX == fileSystemFreeBytes)  { return nil; }


#if !defined(MOS_DFC_LONGLONG_IS_BROKEN)
  if ((self.cacheSizeFreeBytes >= 0) && (self.cacheSizeFreeBytes > fileSystemFreeBytes))
  {
    MOS_LOG_ERROR(
      @"Cache size request (%lld) current file system availability (%llu).", sumOfDatafileSizes, fileSystemFreeBytes);
    return nil;
  }

#else
  if ((self.cacheSizeFreeBytes > fileSystemFreeBytes))
  {
    MOS_LOG_ERROR(
      @"Cache size request (%lld) exceeds sum of previously cached data (%lld) and current file system availability (%llu).",
          self.cacheSizeMaximumBytes, sumOfDatafileSizes, fileSystemFreeBytes);
    return nil;
  }
#endif


  return self;

} // initCacheDirectoryWithURL:dataFileSuffix:sizeInBytes: 




//------------------------------------------------------------ -o--
#pragma mark - Getters/setters.

@synthesize datafileDictionary = _datafileDictionary;


//----------------- -o-
- (NSFileManager *)  fileManager
{
  if (!_fileManager) {
    _fileManager = [[NSFileManager alloc] init];
  }

  return _fileManager;
}


//----------------- -o-
- (NSMutableDictionary *)  datafileDictionary
{
  _datafileDictionary = [[self.propertyList objectForKey:MOS_DFC_DATAFILE_DICTIONARY_KEY] mutableCopy];
  return (_datafileDictionary) ? _datafileDictionary : [[NSMutableDictionary alloc] init];
}


//----------------- -o-
// setDatafileDictionary:
//
// ASSUME  self.propertyList is not nil.
//         Calling environment will [self sync].
//
- (void)  setDatafileDictionary:(NSDictionary *)newDict
{
  [self.propertyList setObject:newDict forKey:MOS_DFC_DATAFILE_DICTIONARY_KEY];
}


//----------------- -o-
- (dispatch_queue_t) queue
{
  if (!_queue) {
    NSString  *label = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSinceReferenceDate]];
    _queue = [MOSZed createAsynchronousSerialQueueWithLabel:label];
  }

  return _queue;
}



//------------------------------------------------------------ -o--
#pragma mark - Public methods.

//----------------- -o-
// saveData:withFilename:
//
// RETURN:  YES upon successful save; otherwise NO.
//
// ASSUME fileName is unique within set of all possible cached file names.
//
// NB  Permission to save is based on the data in the file.  On success, 
//     cacheSizeFreeBytes may be negative due to size of associated resource fork.
//
// When doNotRemoveFilesWhenCacheIsFull=YES, then fileSizeExceedsFreeBytes
// will be set YES if fileData exceeds cacheSizeFreeBytes and the data will 
// NOT be saved.  To save the data, set doNotRemoveFilesWhenCacheIsFull=NO 
// or manage space directly with makeBytesAvailable: or deleteFile:.
//
- (BOOL) saveData: (NSData *)   fileData
     withFilename: (NSString *) fileName
{
  NSInteger  fileSizeRaw               = 0,
             fileSizeWithResourceFork  = 0;

  self.fileSizeExceedsFreeBytes = NO;

  if ((!fileName) || (!fileData)) {                             
    MOS_LOG_ERROR(@"Undefined arguments: fileName and/or fileData.");
    return NO;
  }


  //
  if ([self isFileCached:fileName])  
  {
    if (self.alwaysOverwriteDatafile) {
      if (! [self deleteFile:fileName]) {
        MOS_LOG_ERROR(@"FAILED to force deletion of data in file \"%@\".", fileName);
        return NO;
      }  

    } else {
      [self updateDatafileDictionaryObject:MOS_NOW_SECONDS forKey:fileName];
      if (! [self sync])  { return NO; };

      if (self.verbose) {
        MOS_LOG_INFO(@"Refreshed timestamp on cached entry.  (%@)", fileName); 
      }

      return YES;
    }
  }


  // 
  // Verifies there is enough room for raw data, but not resource fork.
  // Final cache size may exceed maximum by (up to) size of resource fork.  XXX
  //
  fileSizeRaw = [fileData length];

  if (self.doNotRemoveFilesWhenCacheIsFull) 
  {
    if (! [self areBytesAvailable:fileSizeRaw]) { 
      self.fileSizeExceedsFreeBytes = YES;
      return NO; 
    }
  } 
  else if (! [self makeBytesAvailable:fileSizeRaw]) 
  {
    MOS_LOG_ERROR(@"FAILED to acquire space sufficient to cache data for \"%@\".", fileName);
    return NO;
  }


  //
  unsigned long long  fileSystemFreeBytes = 
                        [self.dataDirURL fileSystemAttributeWithName: NSFileSystemFreeSize ]; 
  if (ULONG_LONG_MAX == fileSystemFreeBytes)  { return NO; }

  if (fileSizeRaw > fileSystemFreeBytes) {
    MOS_LOG_ERROR(@"Cache requires more bytes (%d) than available in file system (%llu).",
                      (int) fileSizeRaw, fileSystemFreeBytes);
    return NO;
  }


  //
  NSURL  *fileURL = [self.dataDirURL appendPathToFile:fileName];

  if (! [fileData writeToURL:fileURL atomically:YES])
  {
    MOS_LOG_ERROR(@"FAILED to write cache data for \"%@\".", fileName);
    return NO;
  }

  fileSizeWithResourceFork = [fileURL fileSizeIncludingResourceFork:YES];
  if (fileSizeWithResourceFork < 0) {                                   
    MOS_LOG_ERROR(@"FAILED to read size of cached file \"%@\".  DELETING from cache...", fileName);

    if (! [self deleteFile:fileName]) {
      MOS_LOG_ERROR(@"FAILED to remove improperly logged cached file \"%@\".", fileName);
    }

    return NO;
  }


  // XXX  Check whether inclusion of new file exceeds cache size.
  //      Alternative to allowing small, temporary overwrites.
  //
#if defined(MOS_DFC_LONGLONG_IS_BROKEN)
  MOS_DFC_LONGLONG  cacheSizeDifference = self.cacheSizeFreeBytes - fileSizeWithResourceFork;

  if (cacheSizeDifference > self.cacheSizeFreeBytes) 
  {
    MOS_LOG_ERROR(@"Cached file with resource fork (%d) exceeds size of cache (%llu).  "
                   "DELETING file from cache...  (%@)", 
                       (int) fileSizeWithResourceFork, self.cacheSizeFreeBytes, fileName );

    if (! [self deleteFile:fileName]) {
      MOS_LOG_ERROR(@"FAILED to remove oversize cached file \"%@\".", fileName);
    }

    return NO;
  }
#endif


  //
  self.cacheSizeFreeBytes -= fileSizeWithResourceFork;

  [self updateDatafileDictionaryObject:MOS_NOW_SECONDS forKey:fileName];
  [self sync];  // XXX  Ignore err if save was successful.
  

#if !defined(MOS_DFC_LONGLONG_IS_BROKEN)
  if (self.cacheSizeFreeBytes < 0) 
  {
    [self.propertyList setObject:@(YES) forKey:MOS_DFC_CACHE_OVERFLOW_OKAY_KEY];
    [self sync];

    MOS_LOG_WARNING(@"EXCEEDED cache maximum due to size of file resource fork (%d).",
                        (fileSizeWithResourceFork - fileSizeRaw));
  }
#endif


  return YES;

} // saveData:withFilename:



//----------------- -o-
// overwriteData:withFilename:
//
// fileName is overwritten if it already exists.
// LRU files are deleted if a new file exceeds self.cacheSizeFreeBytes.
//
// RETURNS:  YES  on successful write;
//           NO  if write failed.
//
// On failure, if willOverflowCache == YES then the cache is full;
// otherwise there is a real error and the data could not be saved.
//
// NB  Original fileName is always deleted, even if new version cannot be written.
//
- (BOOL) overwriteData: (NSData *)   fileData
          withFilename: (NSString *) fileName
{
  BOOL  rval;
  BOOL  previousValueAlwaysOverwriteDatafile = self.alwaysOverwriteDatafile;

  //
  self.alwaysOverwriteDatafile = YES;

  //
  rval = [self saveData:fileData withFilename:fileName];

  //
  self.alwaysOverwriteDatafile = previousValueAlwaysOverwriteDatafile;
  return rval;
}



//----------------- -o-
// saveData:withFilename:cacheOverflow:
//
// This version of save data operates with doNotRemoveFilesWhenCacheIsFull == YES.
//
// fileName is NOT overwritten if it already exists.
// LRU files are NOT deleted if a new file exceeds self.cacheSizeFreeBytes.
//
// RETURNS:  YES  on successful write;
//           NO  if write failed.
//
// On failure, if willOverflowCache == YES then the cache is full;
// otherwise there is a real error and the data could not be saved.
//
- (BOOL) saveData: (NSData *)   fileData
     withFilename: (NSString *) fileName
    cacheOverflow: (BOOL *)     willOverflowCache
{
  BOOL  rval;
  BOOL  previousValueOfDoNotRemoveFilesWhenCacheIsFull = self.doNotRemoveFilesWhenCacheIsFull;

  //
  self.doNotRemoveFilesWhenCacheIsFull = YES;

  //
  *willOverflowCache = NO;
  rval = [self saveData:fileData withFilename:fileName];
  *willOverflowCache = self.fileSizeExceedsFreeBytes;

  //
  self.doNotRemoveFilesWhenCacheIsFull = previousValueOfDoNotRemoveFilesWhenCacheIsFull;
  return rval;
}



//----------------- -o-
// overwriteData:withFilename:cacheOverflow: 
//
// This version of save data operates with doNotRemoveFilesWhenCacheIsFull == YES
// and alwaysOverwriteDatafile == YES.
//
// fileName is overwritten if it already exists.
// LRU files are NOT deleted if a new file exceeds self.cacheSizeFreeBytes.
//
// RETURNS:  YES  on successful write;
//           NO  if write failed.
//
// On failure, if willOverflowCache == YES then the cache is full;
// otherwise there is a real error and the data could not be saved.
//
// NB  Original fileName is always deleted, even if new version cannot be written.
//
- (BOOL) overwriteData: (NSData *)fileData
          withFilename: (NSString *)fileName
         cacheOverflow: (BOOL *)willOverflowCache
{
  BOOL  rval = YES;
  BOOL  previousValueOfDoNotRemoveFilesWhenCacheIsFull  = self.doNotRemoveFilesWhenCacheIsFull;
  BOOL  previousValueAlwaysOverwriteDatafile            = self.alwaysOverwriteDatafile;

  //
  self.doNotRemoveFilesWhenCacheIsFull  = YES;
  self.alwaysOverwriteDatafile          = YES;

  //
  *willOverflowCache = NO;
  rval = [self saveData:fileData withFilename:fileName];
  *willOverflowCache = self.fileSizeExceedsFreeBytes;

  //
  self.doNotRemoveFilesWhenCacheIsFull  = previousValueOfDoNotRemoveFilesWhenCacheIsFull;
  self.alwaysOverwriteDatafile          = previousValueAlwaysOverwriteDatafile;
  return rval;
}



//----------------- -o-
- (BOOL) isFileCached:(NSString *)fileName
{
  if (nil != [self.datafileDictionary objectForKey:fileName]) {
    return YES;
  }

  return NO;
}



//----------------- -o-
- (NSURL *) cachedFileURL: (NSString *)fileName
{
  if (! [self isFileCached:fileName]) {
    return nil;
  } 

  return [self.dataDirURL appendPathToFile:fileName];
}



//----------------- -o-
- (MOS_DFC_LONGLONG) currentFreeBytes
{
  return self.cacheSizeFreeBytes;
}



//----------------- -o-
// deleteFile:
//
// RETURN:  YES if file is deleted or is not cached; NO otherwise.
//
// NB  Deleting non-existent files returns YES.
//
- (BOOL) deleteFile:(NSString *)fileName
{
  if (!fileName) {                                      
    MOS_LOG_ERROR(@"fileName is undefined.");
    return NO;
  }


  //
  if (! [self isFileCached:fileName]) {
    return YES;
  }


  //
  NSURL      *fileURL   = [self.dataDirURL appendPathToFile:fileName];
  NSInteger   fileSize  = [fileURL fileSizeIncludingResourceFork:YES];

  if (fileSize < 0)  { return NO; }                     

  if (! [fileURL remove])  { return NO; }

  [self removeDatafileDictionaryObjectForKey:fileName];

  if (! [self sync])  { return NO; }                    

  self.cacheSizeFreeBytes += fileSize;


  return YES;
}



//----------------- -o-
- (BOOL) areBytesAvailable:(MOS_DFC_LONGLONG)bytesRequested
{
  if (bytesRequested <= self.cacheSizeFreeBytes) {      
    return YES; 
  }

  return NO;
}



//----------------- -o-
// makeBytesAvailable:
//
// Make list of file(s) to delete to free up space.
// Determine if needed space, though less than cache size, is also available in the file system.
// Delete file(s) and free space in cache. 
//
// NB  File deletion postponed until all error checks are complete.
//
- (BOOL) makeBytesAvailable:(MOS_DFC_LONGLONG)bytesRequested
{
#if !defined(MOS_DFC_LONGLONG_IS_BROKEN)
  if (bytesRequested < 0) {                             
    MOS_LOG_ERROR(@"bytesRequested is less than zero.  (%lld)", bytesRequested);
    return NO;
  }
#endif


  //
  if (bytesRequested > self.cacheSizeMaximumBytes)      
  {
    MOS_LOG_ERROR(@"Size of free space request (%lld) is greater than cache size (%lld).",
                      bytesRequested, self.cacheSizeMaximumBytes);
    return NO;
  }

  if ([self areBytesAvailable:bytesRequested]) {
    return YES;
  }


  //
  NSArray  *sortedKeysOldestFirst = 
              [self.datafileDictionary keysSortedByValueUsingComparator:^(NSNumber *num1, NSNumber *num2) { return [num1 compare:num2]; } ];

  NSMutableArray  *filesScheduledForDeletion = [[NSMutableArray alloc] init];

  MOS_DFC_LONGLONG  wouldBeFreeBytes = self.cacheSizeFreeBytes;
  NSInteger         fileSize;
        
  for (NSString *key in sortedKeysOldestFirst)
  { 
    if (bytesRequested <= wouldBeFreeBytes) {
      break;
    }

    fileSize = [[self.dataDirURL appendPathToFile:key] fileSizeIncludingResourceFork:YES ];
    if (fileSize < 0)  { return NO; }

    wouldBeFreeBytes += fileSize;
    [filesScheduledForDeletion addObject:key];
  }


  //
  for (NSString *fileName in filesScheduledForDeletion) {
    if (! [self deleteFile:fileName]) {
      return NO;
    }
  }


  return YES;

} // makeBytesAvailable:



//----------------- -o-
- (BOOL) clearCache
{
  self.propertyList = [[NSMutableDictionary alloc] init];
  if (! [self sync]) { 
    return NO; 
  }

  self.cacheSizeFreeBytes = self.cacheSizeMaximumBytes;

  if (! [self.dataDirURL replaceDirectory])
  { 
    MOS_LOG_ERROR(@"FAILED to delete and recreate data directory for cache.");
    return NO; 
  }

  if (self.verbose) {
    MOS_LOG_INFO(@"REMOVED and RE-CREATED property list and data directory for cache directory.  (%@)", self.cacheDirURL);
  }

  return YES;
}



//----------------- -o-
+ (void) proofThatLongLongIsBroken
{
#define BIGNUMBER (10 * 1024 * 1024 * 1024)
  
  MOS_SEP();

  MOS_DUMPO(@((long) BIGNUMBER));
  MOS_DUMPO(@((unsigned long) BIGNUMBER));
  MOS_DUMPO(@((long long) BIGNUMBER));
  MOS_DUMPO(@((unsigned long long) BIGNUMBER));

  MOS_SEP();
}




//------------------------------------------------------------ -o--
#pragma mark - Private methods.

//----------------- -o-
- (void)  updateDatafileDictionaryObject: (id)          object
                                  forKey: (NSString *)  key
{
  NSMutableDictionary  *dfDict = self.datafileDictionary;
  [dfDict setObject:object forKey:key];
  self.datafileDictionary = dfDict;
}


//----------------- -o-
- (void)  removeDatafileDictionaryObjectForKey: (NSString *)object
{
  NSMutableDictionary  *dfDict = self.datafileDictionary;
  [dfDict removeObjectForKey:object];
  self.datafileDictionary = dfDict;
}



//----------------- -o-
- (BOOL) sync
{
  if (! [self.propertyList writeToURL:self.propertyListURL atomically:YES])
  {
    MOS_LOG_ERROR(@"FAILED to write property list for cache data.  (%@)", self.propertyListURL);
    return NO;
  }

  return YES;
}


@end // @implementation MOSDatafileCache

