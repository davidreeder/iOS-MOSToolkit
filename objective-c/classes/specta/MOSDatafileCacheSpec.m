//
// MOSDatafileCacheSpec.m
//
// Test main functionality of MOSDatafileCache.
//
//
// CLASS DEPENDENCIES:  
//   MOSTestSandbox
//   NSDictionary+MOSDump
//   NSURL+MOSZed
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_DatafileCacheSpec  0.3


#import "Specta.h"

#define EXP_SHORTHAND
#import "Expecta.h"


#import "MOSTests.h"
#import "MOSTestSandbox.h"

#import "MOSDatafileCache.h"



SpecBegin(MOSDatafileCache)

//------------------------------------------------------------------------------------- -o--
#define  CACHESIZE_SMALL  (1000000 + 400000)
#define  CACHESIZE_LARGE  (CACHESIZE_SMALL * 2)

#define  FILESIZE_SMALL   250000
#define  FILESIZE_MEDIUM  500000
#define  FILESIZE_LARGE   750000




//------------------------------------------------------------------------------------- -o--
describe(@"MOSDatafileCache", 
^{
  __block  MOSTestSandbox  *sandbox;

  __block  NSDictionary  *assetDict;
  __block  NSString      *assetThatDoesntExist;

  __block  NSData  *smallData,
                   *mediumData,
                   *largeData;




  //-------------------------------------------------- -o--
  beforeAll(^{ 
    BOOL  rval;


#if defined(MOS_DFC_LONGLONG_IS_BROKEN)
    // XXX  Watch this until it gets repaired...
    //
    [MOSDatafileCache proofThatLongLongIsBroken];
#endif


    // TBD  Automate choice of whether build is on simulator or device.
    //
#ifdef MOS_DFC_TESTONDEVICE_YES
    sandbox = [[MOSTestSandbox alloc] initWithRootPath:@"~/testSandbox/" testOnDevice:YES];
#else
    sandbox = [[MOSTestSandbox alloc] initWithRootPath:@"~/testSandbox/" testOnDevice:NO];
#endif

    [sandbox recreateWorkspace];  // ALWAYS build MOSDatafileCache from scratch.


    //
    NSString  *smallFilename   = @"smallBlob.bin";
    NSURL     *smallDataURL    = [sandbox.assetURL appendPathToFile:smallFilename];

    rval = [sandbox createFileAsset:smallFilename ofSize:FILESIZE_SMALL withPattern:@"aaa00aaa"];
    ASSERT_OR_COUNTERROR(rval, sandbox);


    NSString  *mediumFilename  = @"mediumBlob.bin";
    NSURL     *mediumDataURL   = [sandbox.assetURL appendPathToFile:mediumFilename];

    rval = [sandbox createFileAsset:mediumFilename ofSize:FILESIZE_MEDIUM withPattern:@"ccc11ccc"];
    ASSERT_OR_COUNTERROR(rval, sandbox);


    NSString  *largeFilename  = @"largeBlob.bin";
    NSURL     *largeDataURL   = [sandbox.assetURL appendPathToFile:largeFilename];

    rval = [sandbox createFileAsset:largeFilename ofSize:FILESIZE_LARGE withPattern:@"eee22eee"];
    ASSERT_OR_COUNTERROR(rval, sandbox);


    //
#   define SMALL      @"small"
#   define MEDIUM     @"medium"
#   define LARGE      @"large"

#   define DATAURL     @"dataURL"
#   define CACHENAME   @"cachedFileName"
#   define DATASIZE    @"sizeData" 
#   define TOTALSIZE   @"sizeTotal"

    assetDict = 
      @{
        SMALL : @{
                     DATAURL   : smallDataURL,
                     CACHENAME : smallFilename,
                     DATASIZE  : @([smallDataURL fileSizeIncludingResourceFork:NO]),
                     TOTALSIZE : @([smallDataURL fileSizeIncludingResourceFork:YES]),
                },
        MEDIUM : @{
                     DATAURL   : mediumDataURL,
                     CACHENAME : mediumFilename,
                     DATASIZE  : @([mediumDataURL fileSizeIncludingResourceFork:NO]),
                     TOTALSIZE : @([mediumDataURL fileSizeIncludingResourceFork:YES]),
                },
        LARGE : @{
                     DATAURL   : largeDataURL,
                     CACHENAME : largeFilename,
                     DATASIZE  : @([largeDataURL fileSizeIncludingResourceFork:NO]),
                     TOTALSIZE : @([largeDataURL fileSizeIncludingResourceFork:YES]),
                  }
      };

    MOS_DICT(assetDict);


    //
    NSError  *error;

    smallData = [NSData dataWithContentsOfURL:smallDataURL options:0 error:&error];
    ASSERT_OR_COUNTERROR(smallData, sandbox);

    mediumData = [NSData dataWithContentsOfURL:mediumDataURL options:0 error:&error];
    ASSERT_OR_COUNTERROR(mediumData, sandbox);

    largeData = [NSData dataWithContentsOfURL:largeDataURL options:0 error:&error];
    ASSERT_OR_COUNTERROR(largeData, sandbox);


    //
    assetThatDoesntExist = @"assetThatDoesntExist";

  }); // beforeAll (describe)



  //------------------------ -o-
  afterAll(^{
    [sandbox removeSandbox]; 
  });




  //-------------------------------------------------- -o--
  // #A :: Files in LARGE cache.
  //
  //   01. verify test objects
  //   02. initialize size counters
  //   03. watch cached files take up space; count them and name them
  //   04. check presence of files in, or absent from, the cache
  //   05. refresh oldest file; make free large enough to free (second) oldest file
  //   06. delete a cached file, twice; check for existence and check for size
  //
  context(@"#A :: Files in LARGE cache.", 
  ^{
    __block  MOSDatafileCache  *dfc;

    __block  MOS_DFC_LONGLONG  cacheMaximumSize,
                               cacheFreeSize;

    __block  NSMutableArray  *dataDirList;

    __block  BOOL  rval;




    //------------------------ -o-
    beforeAll(^{ 
      dfc = [[MOSDatafileCache alloc] initCacheDirectoryWithURL: [sandbox.workspaceURL appendPathToDirectory:@"cache-large"]
                                                 inSubdirectory: nil
                                                    sizeInBytes: CACHESIZE_LARGE];
    }); // beforeAll (context)



    //------------------------ -o-
    it(@"01. verify test objects", 
    ^{
      expect([sandbox errorCounter]).to.equal(0);
      expect(dfc).notTo.beNil();
    });



    //------------------------ -o-
    it(@"02. initialize size counters", 
    ^{
      cacheMaximumSize  = CACHESIZE_LARGE;
      cacheFreeSize     = [dfc currentFreeBytes];

      expect(cacheFreeSize).to.equal(cacheMaximumSize);


      //
      MOS_DFC_LONGLONG  sumOfFiles = [assetDict[SMALL][TOTALSIZE] unsignedLongLongValue]
                                        + [assetDict[MEDIUM][TOTALSIZE] unsignedLongLongValue]
                                        + [assetDict[LARGE][TOTALSIZE] unsignedLongLongValue];
 
      expect(sumOfFiles).to.beLessThan(cacheMaximumSize);
    });



    //------------------------ -o-
    it(@"03. watch cached files take up space; count them and name them", 
    ^{
      [dfc   saveData: smallData                                // SMALL is first file cached (oldest)
         withFilename: assetDict[SMALL][CACHENAME] ];

      dataDirList = [[dfc dataDirURL] directoryList];

      expect(dataDirList).to.haveCountOf(1);
      expect(dataDirList).to.contain([[dfc dataDirURL] appendPathToFile:assetDict[SMALL][CACHENAME]]);
      
      cacheFreeSize -= [assetDict[SMALL][TOTALSIZE] unsignedLongLongValue];
      expect([dfc currentFreeBytes]).to.equal(cacheFreeSize);


      //
      [dfc   saveData: mediumData                               // MEDIUM is second file, second oldest
         withFilename: assetDict[MEDIUM][CACHENAME] ];

      dataDirList = [[dfc dataDirURL] directoryList];

      expect(dataDirList).to.haveCountOf(2);
      expect(dataDirList).to.contain([[dfc dataDirURL] appendPathToFile:assetDict[MEDIUM][CACHENAME]]);

      cacheFreeSize -= [assetDict[MEDIUM][TOTALSIZE] unsignedLongLongValue];
      expect([dfc currentFreeBytes]).to.equal(cacheFreeSize);
    });



    //------------------------ -o-
    it(@"04. check presence of files in, or absent from, the cache", 
    ^{
      expect([dfc isFileCached:assetDict[SMALL][CACHENAME]]).to.beTruthy();

      expect([dfc isFileCached:assetThatDoesntExist]).to.beFalsy();

      expect([dfc cachedFileURL:assetDict[SMALL][CACHENAME]]).
          to.equal([[dfc dataDirURL] appendPathToFile:assetDict[SMALL][CACHENAME]]);
    });



    //------------------------ -o-
    it(@"05. refresh oldest file; make free large enough to free (second) oldest file", 
    ^{
      [dfc   saveData: largeData                                // LARGE is third file, third oldest
         withFilename: assetDict[LARGE][CACHENAME] ];

      dataDirList = [[dfc dataDirURL] directoryList];
      expect(dataDirList).to.haveCountOf(3);

      cacheFreeSize -= [assetDict[LARGE][TOTALSIZE] unsignedLongLongValue];
      expect([dfc currentFreeBytes]).to.equal(cacheFreeSize);


      //
      [dfc   saveData: smallData                                // SMALL refreshed, MEDIUM is least recently used
         withFilename: assetDict[SMALL][CACHENAME] ];

      dataDirList = [[dfc dataDirURL] directoryList];
      expect(dataDirList).to.haveCountOf(3);
      expect([dfc currentFreeBytes]).to.equal(cacheFreeSize);


      //
      expect([dfc isFileCached:assetDict[MEDIUM][CACHENAME]]).to.beTruthy();

      rval = [dfc makeBytesAvailable:([dfc currentFreeBytes] + 1)];
      expect(rval).to.beTruthy();

      dataDirList = [[dfc dataDirURL] directoryList];
      expect(dataDirList).to.haveCountOf(2);

      cacheFreeSize += [assetDict[MEDIUM][TOTALSIZE] unsignedLongLongValue];
      expect([dfc currentFreeBytes]).to.equal(cacheFreeSize);

      expect([dfc isFileCached:assetDict[MEDIUM][CACHENAME]]).to.beFalsy();
    });



    //------------------------ -o-
    it(@"06. delete a cached file, twice; check for existence and check for size", 
    ^{
      rval = [dfc deleteFile:assetDict[LARGE][CACHENAME]];
      expect(rval).to.beTruthy();

      dataDirList = [[dfc dataDirURL] directoryList];
      expect(dataDirList).to.haveCountOf(1);

      cacheFreeSize += [assetDict[LARGE][TOTALSIZE] unsignedLongLongValue];
      expect([dfc currentFreeBytes]).to.equal(cacheFreeSize);


      //
      rval = [dfc deleteFile:assetDict[LARGE][CACHENAME]];
      expect(rval).to.beTruthy();

      expect([dfc currentFreeBytes]).to.equal(cacheFreeSize);
    });

  }); // context -- #A :: Files in LARGE cache.




  //-------------------------------------------------- -o--
  // #B :: Files in SMALL cache.
  //
  //   01. verify test objects
  //   02. initialize size counters
  //   03. add too many, see LRU discarded; count them and name them
  //   04. clear cache
  //
  context(@"#B :: Files in SMALL cache.", 
  ^{
    __block  MOSDatafileCache  *dfc;

    __block  MOS_DFC_LONGLONG  cacheMaximumSize,
                               cacheFreeSize;

    __block  NSMutableArray  *dataDirList;

    __block  BOOL  rval;




    //------------------------ -o-
    beforeAll(^{ 
      dfc = [[MOSDatafileCache alloc] initCacheDirectoryWithURL: [sandbox.workspaceURL appendPathToDirectory:@"cache-small"]
                                                 inSubdirectory: nil
                                                    sizeInBytes: CACHESIZE_SMALL];
    }); // beforeAll (context)



    //------------------------ -o-
    it(@"01. verify test objects", 
    ^{
      expect(dfc).notTo.beNil();
    });



    //------------------------ -o-
    it(@"02. initialize size counters", 
    ^{
      cacheMaximumSize  = CACHESIZE_SMALL;
      cacheFreeSize     = [dfc currentFreeBytes];

      expect(cacheFreeSize).to.equal(cacheMaximumSize);


      //
      MOS_DFC_LONGLONG  sumOfFiles = [assetDict[SMALL][TOTALSIZE] unsignedLongLongValue]
                                        + [assetDict[MEDIUM][TOTALSIZE] unsignedLongLongValue]
                                        + [assetDict[LARGE][TOTALSIZE] unsignedLongLongValue];

      expect(sumOfFiles).to.beGreaterThan(cacheMaximumSize);
    });



    //------------------------ -o-
    it(@"03. add too many, see LRU discarded; count them and name them",
    ^{
      [dfc   saveData: smallData                                // SMALL is oldest file
         withFilename: assetDict[SMALL][CACHENAME] ];

      cacheFreeSize -= [assetDict[SMALL][TOTALSIZE] unsignedLongLongValue];
      expect([dfc currentFreeBytes]).to.equal(cacheFreeSize);


      [dfc   saveData: mediumData                               // MEDIUM is second oldest
         withFilename: assetDict[MEDIUM][CACHENAME] ];

      cacheFreeSize -= [assetDict[MEDIUM][TOTALSIZE] unsignedLongLongValue];
      expect([dfc currentFreeBytes]).to.equal(cacheFreeSize);


      dataDirList = [[dfc dataDirURL] directoryList];
      expect(dataDirList).to.haveCountOf(2);


      //
      [dfc   saveData: largeData 
         withFilename: assetDict[LARGE][CACHENAME] ];

      cacheFreeSize += [assetDict[SMALL][TOTALSIZE] unsignedLongLongValue];
      cacheFreeSize -= [assetDict[LARGE][TOTALSIZE] unsignedLongLongValue];
      expect([dfc currentFreeBytes]).to.equal(cacheFreeSize);

      dataDirList = [[dfc dataDirURL] directoryList];
      expect(dataDirList).to.haveCountOf(2);


      rval = [dfc isFileCached:assetDict[SMALL][CACHENAME]];
      expect(rval).to.beFalsy();

      rval = [dfc isFileCached:assetDict[MEDIUM][CACHENAME]];
      expect(rval).to.beTruthy();
    });



    //------------------------ -o-
    it(@"04. clear cache", 
    ^{
      rval = [dfc clearCache];
      expect(rval).to.beTruthy();
      expect([dfc currentFreeBytes]).to.equal(cacheMaximumSize);

      dataDirList = [[dfc dataDirURL] directoryList];
      expect(dataDirList).to.haveCountOf(0);
      
      NSInteger  fileSize = [[dfc propertyListURL] fileSizeIncludingResourceFork:NO];
      expect(fileSize).to.beGreaterThan(0);
    });

  }); // context -- #B :: Files in SMALL cache.




#if !defined(MOS_DFC_LONGLONG_IS_BROKEN)
  //-------------------------------------------------- -o--
  // #C :: Test cache OVERFLOW logic.
  //
  //   01. verify test objects
  //   02. add file that exactly exhausts free bytes, then see that resource fork takes extra space
  //   03. create new cache instance
  //   04. verify that resource fork overflow does cause items to be deleted
  //   05. clear overflow flag, create another new cache instance, verify overflow is corrected
  //
  context(@"#C :: Test cache OVERFLOW logic.",
  ^{
    __block  MOSDatafileCache  *dfc, *dfcTwo, *dfcThree;

    __block  MOS_DFC_LONGLONG  freeByteCount,
                               overflowFreeByteCount;

    __block  NSMutableArray  *dataDirList;

    __block  BOOL  rval;




    //------------------------ -o-
    beforeAll(^{ 
      dfc = [[MOSDatafileCache alloc] initCacheDirectoryWithURL: [sandbox.workspaceURL appendPathToDirectory:@"cache-overflow"]
                                                 inSubdirectory: nil
                                                    sizeInBytes: CACHESIZE_SMALL];
    }); // beforeAll (context)



    //------------------------ -o-
    it(@"01. verify test objects", 
    ^{
      expect(dfc).notTo.beNil();
    });



    //------------------------ -o-
    it(@"02. add file that exactly exhausts free bytes, then see that resource fork takes extra space", 
    ^{
      rval = [dfc saveData:largeData withFilename:assetDict[LARGE][CACHENAME] ];
      expect(rval).to.beTruthy();

      MOS_DFC_LONGLONG  freeBytes = [dfc currentFreeBytes];

      //
      NSString  *extraFilename  = @"extraBlob.bin";
      NSURL     *extraDataURL   = [sandbox.assetURL appendPathToFile:extraFilename];

      rval = [sandbox createFileAsset:extraFilename ofSize:(NSUInteger)freeBytes withPattern:@"abcdef01"];
      expect(rval).to.beTruthy();

      NSError  *error;
      NSData  *extraData = [NSData dataWithContentsOfURL:extraDataURL options:0 error:&error];
      expect(extraData).notTo.beNil();

      //
      rval = [dfc saveData:extraData withFilename:extraFilename ];
      expect(rval).to.beTruthy();

      overflowFreeByteCount = [dfc currentFreeBytes];
      expect(overflowFreeByteCount).to.beLessThan(0);
    });



    //------------------------ -o-
    it(@"03. create new cache instance",
    ^{
      dfcTwo = [[MOSDatafileCache alloc] initCacheDirectoryWithURL: [sandbox.workspaceURL appendPathToDirectory:@"cache-overflow"]
                                                    inSubdirectory: nil
                                                       sizeInBytes: CACHESIZE_SMALL];
      expect(dfcTwo).notTo.beNil();
    });



    //------------------------ -o-
    it(@"04. verify that resource fork overflow does cause items to be deleted",
    ^{
      freeByteCount = [dfcTwo currentFreeBytes];

      expect(freeByteCount).to.equal(overflowFreeByteCount);
      expect(freeByteCount).to.beLessThan(0);

      dataDirList = [[dfcTwo dataDirURL] directoryList];
      expect(dataDirList).to.haveCountOf(2);
    });



    //------------------------ -o-
    it(@"05. clear overflow flag, create another new cache instance, verify overflow is corrected",
    ^{
      NSMutableDictionary  *cachePropertyList = [[NSDictionary dictionaryWithContentsOfURL:dfcTwo.propertyListURL] mutableCopy];
      [cachePropertyList removeObjectForKey:MOS_DFC_CACHE_OVERFLOW_OKAY_KEY];

      rval = [cachePropertyList writeToURL:dfcTwo.propertyListURL atomically:YES];
      expect(rval).to.beTruthy();


      //
      dfcThree = [[MOSDatafileCache alloc] initCacheDirectoryWithURL: [sandbox.workspaceURL appendPathToDirectory:@"cache-overflow"]
                                                      inSubdirectory: nil
                                                         sizeInBytes: CACHESIZE_SMALL];
      expect(dfcThree).notTo.beNil();


      //
      freeByteCount = [dfcThree currentFreeBytes];

      expect(freeByteCount).to.beGreaterThan(overflowFreeByteCount);
      expect(freeByteCount).to.beGreaterThan(0);

      dataDirList = [[dfcThree dataDirURL] directoryList];
      expect(dataDirList).to.haveCountOf(1);
    });

  }); // context -- #C :: Test cache OVERFLOW logic.

#else
  //-------------------------------------------------- -o--
  // #C :: Test cache OVERFLOW bars file from being saved.  Special case for MOS_DFC_LONGLONG_IS_BROKEN.
  //
  //   01. verify test objects
  //   02. add file that exactly exhausts free bytes, then see that file is not saved
  //
  context(@"#C :: Test cache OVERFLOW bars file from being saved.  Special case for MOS_DFC_LONGLONG_IS_BROKEN.",
  ^{
    __block  MOSDatafileCache  *dfc;

    __block  MOS_DFC_LONGLONG  previousFreeByteCount;

    __block  BOOL  rval;




    //------------------------ -o-
    beforeAll(^{ 
      dfc = [[MOSDatafileCache alloc] initCacheDirectoryWithURL: [sandbox.workspaceURL appendPathToDirectory:@"cache-overflow"]
                                                 inSubdirectory: nil
                                                    sizeInBytes: CACHESIZE_SMALL];
    }); // beforeAll (context)



    //------------------------ -o-
    it(@"01. verify test objects", 
    ^{
      expect(dfc).notTo.beNil();
    });



    //------------------------ -o-
    it(@"02. add file that exactly exhausts free bytes, then see that file is not saved",
    ^{
      rval = [dfc saveData:largeData withFilename:assetDict[LARGE][CACHENAME] ];
      expect(rval).to.beTruthy();

      MOS_DFC_LONGLONG  freeBytes = [dfc currentFreeBytes];

      //
      NSString  *extraFilename  = @"extraBlob.bin";
      NSURL     *extraDataURL   = [sandbox.assetURL appendPathToFile:extraFilename];

      rval = [sandbox createFileAsset:extraFilename ofSize:(NSUInteger)freeBytes withPattern:@"abcdef01"];
      expect(rval).to.beTruthy();

      NSError  *error;
      NSData  *extraData = [NSData dataWithContentsOfURL:extraDataURL options:0 error:&error];
      expect(extraData).notTo.beNil();

      //
      previousFreeByteCount = [dfc currentFreeBytes];

      rval = [dfc saveData:extraData withFilename:extraFilename ];
      expect(rval).to.beFalsy();

      expect([dfc currentFreeBytes]).to.equal(previousFreeByteCount);
    });

  }); // context -- #C :: Test cache OVERFLOW bars file from being saved.  Special case for MOS_DFC_LONGLONG_IS_BROKEN.

#endif // MOS_DFC_LONGLONG_IS_BROKEN




  //-------------------------------------------------- -o--
  // #D :: Test variations of saveData:withFilename:
  //
  //   01. verify test objects
  //   02. saveData:withFilename:cacheOverflow: -- add file that exceeds free bytes, then watch the save be cancelled
  //   03. overwriteData:withFilename: -- overwrite small with medium, watch LRU clear cache  
  //   04. overwriteData:withFilename:cacheOverflow: -- overwrite small with medium, watch the save be cancelled
  //
  context(@"#D :: Test variations of saveData:withFilename:",
  ^{
    __block  MOSDatafileCache  *dfc;
    __block  MOS_DFC_LONGLONG   freeBytes;
    __block  BOOL               rval;



    //------------------------ -o-
    beforeAll(^{ 
      dfc = [[MOSDatafileCache alloc] initCacheDirectoryWithURL: [sandbox.workspaceURL appendPathToDirectory:@"cache-preventAddition"]
                                                 inSubdirectory: nil
                                                    sizeInBytes: (CACHESIZE_SMALL / 2) ];
    }); // beforeAll (context)



    //------------------------ -o-
    it(@"01. verify test objects", 
    ^{
      expect(dfc).notTo.beNil();
    });



    //------------------------ -o-
    it(@"02. saveData:withFilename:cacheOverflow: -- add file that exceeds free bytes, then watch the save be cancelled",
    ^{
      BOOL  overflow;

      //
      rval = [dfc   saveData: mediumData 
                withFilename: assetDict[MEDIUM][CACHENAME] 
               cacheOverflow: &overflow ];

      expect(rval).to.beTruthy();
      expect(overflow).to.beFalsy();

      freeBytes = [dfc currentFreeBytes];

      rval = [dfc saveData: smallData 
              withFilename: assetDict[SMALL][CACHENAME] 
             cacheOverflow: &overflow ];

      expect(rval).to.beFalsy();
      expect(overflow).to.beTruthy();
      expect([dfc currentFreeBytes]).to.equal(freeBytes);
    });



    it(@"03. overwriteData:withFilename: -- overwrite small with medium, watch LRU clear cache",
    ^{
      NSString  *smallTwoFilename = @"smallBlobTWO.bin";
      NSInteger  datafileCount = -1;

      //
      rval = [dfc clearCache];
      expect(rval).to.beTruthy();

      rval = [dfc overwriteData:smallData withFilename:assetDict[SMALL][CACHENAME]];
      expect(rval).to.beTruthy();

      //
      rval = [dfc overwriteData:smallData withFilename:smallTwoFilename];
      expect(rval).to.beTruthy();

      datafileCount = [[dfc.dataDirURL directoryList] count];
      expect(datafileCount).to.equal(2);

      //
      rval = [dfc overwriteData:mediumData withFilename:smallTwoFilename];
      expect(rval).to.beTruthy();

      datafileCount = [[dfc.dataDirURL directoryList] count];
      expect(datafileCount).to.equal(1);

      rval = [dfc isFileCached:smallTwoFilename];
      expect(rval).to.beTruthy();
    });


    it(@"04. overwriteData:withFilename:cacheOverflow: -- overwrite small with medium, watch the save be cancelled",
    ^{
      NSString          *smallTwoFilename = @"smallBlobTWO.bin";
      NSInteger          datafileCount = -1;
      BOOL               cacheDidOverflow = NO;

      //
      rval = [dfc clearCache];
      expect(rval).to.beTruthy();

      rval = [dfc overwriteData:smallData withFilename:assetDict[SMALL][CACHENAME]];
      expect(rval).to.beTruthy();

      //
      rval = [dfc overwriteData:smallData withFilename:smallTwoFilename];
      expect(rval).to.beTruthy();

      datafileCount = [[dfc.dataDirURL directoryList] count];
      expect(datafileCount).to.equal(2);

      //
      rval = [dfc overwriteData:  mediumData 
                   withFilename:  smallTwoFilename
		  cacheOverflow: &cacheDidOverflow ];

      expect(rval).to.beFalsy();
      expect(cacheDidOverflow).to.beTruthy();

      datafileCount = [[dfc.dataDirURL directoryList] count];
      expect(datafileCount).to.equal(1);

      rval = [dfc isFileCached:assetDict[SMALL][CACHENAME]];
      expect(rval).to.beTruthy();

      freeBytes = [dfc currentFreeBytes];
      expect(freeBytes).to.beLessThan(assetDict[MEDIUM][DATASIZE]);
    });

  }); // context -- #D :: Test variations of saveData:withFilename:

}); // describe -- MOSDatafileCache


SpecEnd // MOSDatafileCache

