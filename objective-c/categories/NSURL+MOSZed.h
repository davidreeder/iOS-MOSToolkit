//
// NSURL+MOSZed.h
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_NSURL_Zed  0.2


#import <Foundation/Foundation.h>

#import "MOSMobileSound.h"



//------------------------------------------------ -o-
@interface NSURL (MOSZed)

  // File and directory management.
  //
  - (BOOL)  doesExist;
  - (BOOL)  isFile;
  - (BOOL)  isDirectory;

  - (BOOL)  remove;

  - (BOOL)  createDirectoryWithReplace: (BOOL)replace;
  - (BOOL)  createDirectoryPathToFile;
  - (BOOL)  createDirectory;
  - (BOOL)  replaceDirectory;

  - (NSURL *) appendPathToDirectory: (NSString *)path;
  - (NSURL *) appendPathToFile:      (NSString *)path;
  - (NSURL *) appendExtension:       (NSString *)extension;

  - (NSURL *) appendPathToFile: (NSString *)path
                 withExtension: (NSString *)extension;


  // Acquire system directories.
  //
  + (NSURL *)  firstSearchPathDirectory: (NSSearchPathDirectory)searchPathDirectory;
  + (NSURL *)  firstUserCacheDirectory;
  + (NSURL *)  firstUserDocumentsDirectory;
  + (NSURL *)  userRootDirectory;


  // File, directory and file system utilities.
  //
  - (NSInteger)  fileSizeIncludingResourceFork: (BOOL)includeResourceFork;

  - (NSMutableArray *) directoryList;

  - (id)                  fileAttributeWithName:       (NSString *)attributeName;
  - (unsigned long long)  fileSystemAttributeWithName: (NSString *)attributeName;


  //
  - (UIImage *) readAsUIImage;
  - (NSString *) readAsNSString;

@end

