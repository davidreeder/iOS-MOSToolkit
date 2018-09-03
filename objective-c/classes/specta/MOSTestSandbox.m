//
// MOSTestSandbox.m
//
// Manage and query file system assets during testing. 
//
//
// NB
//   . self.workspaceURL and self.workspaceTmpURL may be removed and recreated.
//   . All other top level directories will be created, but never removed.
//   . self.assetURL is a cumulative collection of all assets.
//
//
// CLASS DEPENDENCIES: MOSLog, NSData+MOSZed, NSURL+MOSZed
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------


#import "MOSTestSandbox.h"




//-------------------------------------------------------------- -o--
@interface  MOSTestSandbox()

  @property  (readwrite, strong, nonatomic)  NSURL  *rootURL;
  @property  (readwrite, strong, nonatomic)  NSURL  *assetURL;
  @property  (readwrite, strong, nonatomic)  NSURL  *workspaceURL;
  @property  (readwrite, strong, nonatomic)  NSURL  *workspaceTmpURL;


  @property  (strong, nonatomic)     NSFileManager  *fileManager;

  @property  (readwrite, nonatomic)  NSUInteger      errorCounter;

@end




//-------------------------------------------------------------- -o--
@implementation  MOSTestSandbox

#pragma mark - Constructors.

//------------------------------- -o-
// initWithRootPath:
//
// Define standard directories.
// Change directories to self.workspaceURL.
//
// NB  rootPath may lead with tilde ('~') indicating "home directory".
//
- (id)  initWithRootPath: (NSString *) rootPath
            testOnDevice: (BOOL)       testOnDevice
{
  if (!(self = [super init])) {
    MOSLogError(@"[super init] failed.");
    return nil;
  }

  if (!rootPath) {
    MOSLogError(@"rootPath is undefined.");
    return nil;
  }


  //
  self.verbose = YES;
  [self clearErrorCounter];


  // Testing on device requires prefixing pathname with "/private"
  //
  if (testOnDevice) 
  {
    MOSLogInfo(@"Testing ON DEVICE.");
    NSString  *pathPrefix = @"/private";
    self.rootURL = [NSURL fileURLWithPath: MOS_STRWFMT(@"%@%@", pathPrefix, [rootPath stringByExpandingTildeInPath])
                              isDirectory: YES ];
  } else {
    MOSLogInfo(@"Testing IN SIMULATOR.");
    self.rootURL = [NSURL fileURLWithPath:[rootPath stringByExpandingTildeInPath] isDirectory:YES];
  }
  

  self.assetURL         = [self.rootURL URLByAppendingPathComponent:MOSTS_ASSET_STR isDirectory:YES];
  self.workspaceURL     = [self.rootURL URLByAppendingPathComponent:MOSTS_WORKSPACE_STR isDirectory:YES];
  self.workspaceTmpURL  = [self.workspaceURL URLByAppendingPathComponent:MOSTS_WORKSPACE_TMP_STR isDirectory:YES];


  if (! (   [self.rootURL          replaceDirectory]
         && [self.assetURL         replaceDirectory]
         && [self.workspaceURL     replaceDirectory] 
         && [self.workspaceTmpURL  replaceDirectory] ))
  {
    return nil;
  }


  //
  [self.fileManager changeCurrentDirectoryPath:[self.workspaceURL path]];
  if (self.verbose) {
    MOSLogInfo(@"CURRENT DIRECTORY is \"%@\".", [[self.fileManager currentDirectoryPath] lastPathComponent] );
  }


  return self;

} // initWithRootPath:




//-------------------------------------------------------------- -o-
#pragma mark - Getter/setter.

//------------------------------- -o-
- (NSFileManager *)  fileManager
{
  if (!_fileManager) {
    _fileManager = [[NSFileManager alloc] init];
  }
  return _fileManager;
}




//-------------------------------------------------------------- -o-
#pragma mark - Methods.

//------------------------------- -o-
- (BOOL)  recreateWorkspace
{
  return (    [self.workspaceURL replaceDirectory] 
           && [self.workspaceTmpURL replaceDirectory] );
}


//------------------------------- -o-
- (BOOL)  recreateWorkspaceTmp
{
  return [self.workspaceTmpURL replaceDirectory];
}


//------------------------------- -o-
- (BOOL)  removeSandbox
{
  return [self.rootURL remove];
}



//------------------------------- -o-
- (NSInteger)  incrementErrorCounter
{
  return (self.errorCounter += 1);
}


//------------------------------- -o-
- (void)  clearErrorCounter
{
  self.errorCounter = 0;
}



//------------------------------- -o-
- (BOOL)  createFileAsset: (NSString *) fileName
                   ofSize: (NSUInteger) sizeInBytes
              withPattern: (NSString *) fourByteHexPattern
{
  if (!fileName) {
    MOSLogError(@"fileName is nil.");
    return NO;
  }


  //
  NSData   *fileData  = [NSData randomDataOfSize:sizeInBytes withPattern:fourByteHexPattern];
  NSError  *error     = nil;


  BOOL  rval = [fileData writeToURL:  [self.assetURL appendPathToFile:fileName]
                            options:  NSDataWritingAtomic
                              error: &error ];
  if (error) {
    MOSLogNSError(error);
  }

  if (!rval) {
    MOSLogError(@"Failed to write generated data to assets file.  (%@)", fileName);
    return NO;
  }


  return YES;

} // createFileAsset:ofSize:withPattern: 


@end // @implementation  MOSTestSandbox

