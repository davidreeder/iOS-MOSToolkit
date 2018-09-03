//
// MOSDatafileCache.h
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_DatafileCache  0.2

#import "MOSMobileSound.h"



//------------------------------------------------------------ -o-
#define MOS_DFC_CACHEDIR_BASENAME_DEFAULT      @"MOSDatafileCache"
#define MOS_DFC_CACHEDIR_DATADIR_NAME          @"data"
#define MOS_DFC_CACHEDIR_PROPERTYLIST_NAME     @"dataTimestamps.plist"


// SCHEMA for self.propertyList--
//   [MOS_DFC_CACHE_OVERFLOW_OKAY_KEY  NSNumber booleanValue]
//    MOS_DFC_DATAFILE_DICTIONARY      NSDictionary (zero or more):
//                                       NSString fileName --> NSNumber timestamp
//
#define MOS_DFC_CACHE_OVERFLOW_OKAY_KEY  @"DatafileCache_CACHE_OVERFLOW_OKAY"
#define MOS_DFC_DATAFILE_DICTIONARY_KEY  @"DatafileCache_DATAFILE_DICTIONARY"




//------------------------------------------------------------ -o-
// NB XXX  Xcode 5.1 "long long" evaluates to "long".  (Wed Jul 30 EDT 2014)  
//
// NB XXX  Using "unsigned long long" breaks use of ("signed" long long) 
//           cacheSizeFreeBytes to detect cache overwrites after accounting for 
//           the resource fork.
//         However, this problem is hopefully minimized if cacheSizeMaximumBytes is 2^64.
//

#define MOS_DFC_LONGLONG_IS_BROKEN  YES

#if defined(MOS_DFC_LONGLONG_IS_BROKEN)
#  define MOS_DFC_LONGLONG  unsigned long long
#else
#  define MOS_DFC_LONGLONG  long long
#endif




//------------------------------------------------------------ -o-
@interface MOSDatafileCache : NSObject

  @property  (readonly, strong, nonatomic)  NSURL  *cacheDirURL;
  @property  (readonly, strong, nonatomic)  NSURL  *propertyListURL;
  @property  (readonly, strong, nonatomic)  NSURL  *dataDirURL;
      // NB propertyListURL and dataDirURL are both contained within cacheDirURL.

  @property  (readonly, nonatomic)  dispatch_queue_t  queue;
      // NB Cache specific queue.

  @property  (nonatomic)  BOOL  verbose;
      // YES enables MOS_LOG_INFO messages.



  //
  - (id) initCacheDirectoryWithURL: (NSURL *)           cacheDirURL
                    inSubdirectory: (NSString *)        subdirectoryName
                       sizeInBytes: (MOS_DFC_LONGLONG)  sizeInBytes;


  - (BOOL) saveData: (NSData *)   fileData
       withFilename: (NSString *) fileName;

  - (BOOL) overwriteData: (NSData *)   fileData
	    withFilename: (NSString *) fileName;

  - (BOOL) saveData: (NSData *)   fileData
       withFilename: (NSString *) fileName
      cacheOverflow: (BOOL *)     willOverflowCache;

  - (BOOL) overwriteData: (NSData *)data
            withFilename: (NSString *)fileName
           cacheOverflow: (BOOL *)willOverflowCache;


  - (BOOL) isFileCached: (NSString *)fileName;

  - (NSURL *) cachedFileURL: (NSString *)fileName;

  - (MOS_DFC_LONGLONG) currentFreeBytes;

  - (BOOL) deleteFile: (NSString *)fileName;

  - (BOOL) areBytesAvailable: (MOS_DFC_LONGLONG)bytesRequested;
  - (BOOL) makeBytesAvailable: (MOS_DFC_LONGLONG)bytesRequested;

  - (BOOL) clearCache;

  + (void) proofThatLongLongIsBroken;

@end

