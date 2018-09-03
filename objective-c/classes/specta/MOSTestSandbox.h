//
// MOSTestSandbox.h
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_TESTSANDBOX  0.2  // 


#import "MOSMobileSound.h"



//--------------------------------------------------------------- -o-
#define MOSTS_WORKSPACE_STR      @"workspace"
#define MOSTS_WORKSPACE_TMP_STR  @"tmp" 
#define MOSTS_ASSET_STR          @"asset"


#define ASSERT_OR_COUNTERROR(assertion, testClassInstance)  \
    if (! (assertion))  { [testClassInstance incrementErrorCounter]; }



//--------------------------------------------------------------- -o-
@interface  MOSTestSandbox : NSObject

  @property  (nonatomic)            BOOL        verbose;
  @property  (readonly, nonatomic)  NSUInteger  errorCounter;

  @property  (readonly, strong, nonatomic)  NSURL  *rootURL;
  @property  (readonly, strong, nonatomic)  NSURL  *assetURL;
  @property  (readonly, strong, nonatomic)  NSURL  *workspaceURL;
  @property  (readonly, strong, nonatomic)  NSURL  *workspaceTmpURL;


  //
  - (id)  initWithRootPath: (NSString *) rootPath
              testOnDevice: (BOOL)       testOnDevice;

  - (BOOL)  recreateWorkspace;
  - (BOOL)  recreateWorkspaceTmp;
  - (BOOL)  removeSandbox;

  - (NSInteger)  incrementErrorCounter;
  - (void)       clearErrorCounter;

  - (BOOL)  createFileAsset: (NSString *) fileName
                     ofSize: (NSUInteger) sizeInBytes
                withPattern: (NSString *) hexPattern;
@end

