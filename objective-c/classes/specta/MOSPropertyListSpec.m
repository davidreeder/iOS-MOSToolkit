//
// MOSPropertyListSpec.m
//
// Test of MOSPropertyList.
//
//
// NB  All functionality must be tested both for files, URLs and for User Defaults.
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

#define MOS_VERSION_PropertyListSpec  0.1  // 


#import "Specta.h"

#define EXP_SHORTHAND
#import "Expecta.h"


#import "MOSTests.h"
#import "MOSTestSandbox.h"

#import "MOSPropertyList.h"



SpecBegin(MOSPropertyList)

//------------------------------------------------------------------------------------- -o--
describe(@"MOSPropertyList", 
^{
  __block  MOSTestSandbox  *sandbox;

  __block  NSDictionary  *assetDict;



  //-------------------------------------------------- -o--
  beforeAll(^{ 
    BOOL      rval;
    NSError  *error;

    // TBD  Automate choice of whether build is on simulator or device.
    //
#ifdef MOS_TESTONDEVICE_YES
    sandbox = [[MOSTestSandbox alloc] initWithRootPath:@"~/testSandbox/" testOnDevice:YES];
#else
    sandbox = [[MOSTestSandbox alloc] initWithRootPath:@"~/testSandbox/" testOnDevice:NO];
#endif

    [sandbox recreateWorkspace];  // ALWAYS run MOSPropertyList from scratch.


    //
#   define kNAMING     @"NAMING"
#   define kFILENAME             @"FILENAME"
#   define kANOTHERFILENAME      @"ANOTHERFILENAME"
#   define kYETANOTHERFILENAME   @"YETANOTHERFILENAME"
#   define kUDROOT               @"UDROOT"
#   define kUDROOTWITHPREFIX     @"UDROOTWITHPREFIX"
#   define kDATAFILE             @"SeymoreTheDatafile.bin"

#   define kVALUES     @"VALUES"
#   define kINTEGER      @"INTEGER"
#   define kUINTEGER     @"UINTEGER"
#   define kLONGLONG     @"LONGLONG"
#   define kULONGLONG    @"ULONGLONG"
#   define kFLOAT        @"FLOAT"
#   define kDOUBLE       @"DOUBLE"
#   define kBOOL         @"BOOL"
#   define kDICTIONARY   @"DICTIONARY"
#   define kARRAY        @"ARRAY"
#   define kSTRING       @"STRING"
#   define kDATE         @"DATE"
#   define kNUMBER       @"NUMBER"
#   define kDATA         @"DATA"


    rval = [sandbox createFileAsset:kDATAFILE ofSize:(4 * 4) withPattern:@"eafccfae"];
    ASSERT_OR_COUNTERROR(rval, sandbox);

    NSURL  *dataURL = [sandbox.assetURL appendPathToFile:kDATAFILE];
    NSData  *dataObj = [NSData dataWithContentsOfURL:dataURL options:0 error:&error];
    ASSERT_OR_COUNTERROR(dataObj, sandbox);

    rval = [MOSPropertyList deleteDefaultDirectory];
    ASSERT_OR_COUNTERROR(rval, sandbox);


    //
    assetDict = 
      @{
        kNAMING : @{
          kFILENAME             : @"GinaTheFilename",
          kANOTHERFILENAME      : @"TerranceTheAnotherFilename",
          kYETANOTHERFILENAME   : @"BlancheTheYetAnotherFilename",
          kUDROOT               : @"JillianTheDictionaryRoot",
          kUDROOTWITHPREFIX     : @"__JillianTheDictionaryRoot"
        },

        kVALUES : @{
          kINTEGER    : @(INT_MIN),
          kUINTEGER   : @(UINT_MAX),

          kLONGLONG   : @(LONG_LONG_MIN),
          kULONGLONG  : @(ULONG_LONG_MAX),

          kFLOAT      : @(FLT_MAX),
          kDOUBLE     : @(DBL_MAX),

          kBOOL       : @(YES),

          kDICTIONARY : @{
                          @"All"   : @"Enemy",
                          @"you"   : @"of",
                          @"need"  : @"my",
                          @"is"    : @"enemy",
                          @"love." : @"is..."
                        },

          kARRAY      : @[ @"This", @(18), @"totally", @"[NSNull null]" ],
          kSTRING     : @"cylonvirus",
          kDATE       : [NSDate date],
          kNUMBER     : @(42),
          kDATA       : dataObj
        }
      };

    MOS_DICT(assetDict);

  }); // beforeAll (describe)



  //------------------------ -o-
  afterAll(^{
    [sandbox removeSandbox];
    [MOSPropertyList deleteDefaultDirectory];
  });




  //-------------------------------------------------- -o--
  // #A :: URLs and FILEs.
  //
  //   01. initialize property list from filename (plFile), then verify test objects
  //
  //   02. write values to property list, one for each available method
  //   03. re-open property list with filename (plFileTwo)
  //   04. read and verify values written to property list
  //
  //   05. re-open property list with URL (plURL), then read (select) values already verified once
  //
  //   06. remove elements, then verify they are missing in both object and file (plURLTwo)
  //   07. delete property list, then demonstrate list is empty and that file is missing 
  //   08. re-open with filename (plFileThree), then verify list is empty
  //
  //   09. open new property list file in a non-default directory (plURLThree)
  //   10. write select values to property list, then verify these values
  //
  //   11. save property list, open new property list URL (plURLFour), then verify these values
  //   12. re-open property list file (plURLThree) with overwrite option, then verify list is empty
  //
  //   13. delete default directory
  //
  context(@"#A :: URLs and FILEs.",
  ^{
    __block  MOSPropertyList  *plFile, *plFileTwo, *plFileThree;
    __block  MOSPropertyList  *plURL, *plURLTwo, *plURLThree, *plURLFour;

    __block  BOOL  rval;




    //------------------------ -o-
    it(@"01. initialize property list from filename (plFile), then verify test objects",
    ^{
      expect([sandbox errorCounter]).to.equal(0);

      plFile = [[MOSPropertyList alloc] initWithFilename:assetDict[kFILENAME] overwrite:YES];
      expect(plFile).notTo.beNil();
    });



    //------------------------ -o-
    it(@"02. write values to property list, one for each available method",
    ^{
      [plFile setObject:assetDict[kVALUES][kINTEGER]        forKey:kINTEGER];
      [plFile setObject:assetDict[kVALUES][kUINTEGER]       forKey:kUINTEGER];

      [plFile setObject:assetDict[kVALUES][kLONGLONG]       forKey:kLONGLONG];
      [plFile setObject:assetDict[kVALUES][kULONGLONG]      forKey:kULONGLONG];

      [plFile setObject:assetDict[kVALUES][kFLOAT]          forKey:kFLOAT];
      [plFile setObject:assetDict[kVALUES][kDOUBLE]         forKey:kDOUBLE];

      [plFile setObject:assetDict[kVALUES][kBOOL]           forKey:kBOOL];

      [plFile setObject:assetDict[kVALUES][kDICTIONARY]     forKey:kDICTIONARY];
      [plFile setObject:assetDict[kVALUES][kARRAY]          forKey:kARRAY];
      [plFile setObject:assetDict[kVALUES][kSTRING]         forKey:kSTRING];
      [plFile setObject:assetDict[kVALUES][kDATE]           forKey:kDATE];
      [plFile setObject:assetDict[kVALUES][kNUMBER]         forKey:kNUMBER];
      [plFile setObject:assetDict[kVALUES][kDATA]           forKey:kDATA];

      [plFile dump];
    });



    //------------------------ -o-
    it(@"03. re-open property list with filename (plFileTwo)",
    ^{
      plFileTwo = [[MOSPropertyList alloc] initWithFilename:assetDict[kNAMING][kFILENAME]  overwrite:NO];
      expect(plFileTwo).toNot.beNil();
    });



    //------------------------ -o-
    it(@"04. read and verify values written to property list",
    ^{
      expect([plFileTwo integerForKey:kINTEGER]).to.equal((NSInteger) [assetDict[kVALUES][kINTEGER] integerValue]);
      expect([plFileTwo uIntegerForKey:kUINTEGER]).to.equal((NSUInteger) [assetDict[kVALUES][kUINTEGER] unsignedIntegerValue]);

      expect([plFileTwo longLongForKey:kLONGLONG]).to.equal((long long) [assetDict[kVALUES][kLONGLONG] longLongValue]);
      expect([plFileTwo uLongLongForKey:kULONGLONG]).to.equal((unsigned long long) [assetDict[kVALUES][kULONGLONG] unsignedLongLongValue]);

      expect([plFileTwo floatForKey:kFLOAT]).to.equal((CGFloat) [assetDict[kVALUES][kFLOAT] floatValue]);
      expect([plFileTwo doubleForKey:kDOUBLE]).to.equal((double) [assetDict[kVALUES][kDOUBLE] doubleValue]);

      expect([plFileTwo boolForKey:kBOOL]).to.equal((BOOL) [assetDict[kVALUES][kBOOL] boolValue]);

      expect([plFileTwo dictionaryForKey:kDICTIONARY]).to.equal((NSMutableDictionary *) assetDict[kVALUES][kDICTIONARY]);

      expect([plFileTwo arrayForKey:kARRAY]).to.equal((NSMutableArray *) assetDict[kVALUES][kARRAY]);

      expect([plFileTwo stringForKey:kSTRING]).to.equal((NSString *) assetDict[kVALUES][kSTRING]);

      expect([plFileTwo dateForKey:kDATE]).to.equal((NSDate *) assetDict[kVALUES][kDATE]);

      expect([plFileTwo numberForKey:kNUMBER]).to.equal((NSNumber *) assetDict[kVALUES][kNUMBER]);

      expect([plFileTwo dataForKey:kDATA]).to.equal((NSData *) assetDict[kVALUES][kDATA]);
    });



    //------------------------ -o-
    it(@"05. re-open property list with URL (plURL), then read (select) values already verified once",
    ^{
      plURL = [[MOSPropertyList alloc] initWithURL:plFileTwo.url overwrite:NO];
      expect(plURL).toNot.beNil();

      //
      expect([plURL integerForKey:kINTEGER]).to.equal((NSInteger) [assetDict[kVALUES][kINTEGER] integerValue]);
      expect([plURL uIntegerForKey:kUINTEGER]).to.equal((NSUInteger) [assetDict[kVALUES][kUINTEGER] unsignedIntegerValue]);

      expect([plURL longLongForKey:kLONGLONG]).to.equal((long long) [assetDict[kVALUES][kLONGLONG] longLongValue]);
      expect([plURL uLongLongForKey:kULONGLONG]).to.equal((unsigned long long) [assetDict[kVALUES][kULONGLONG] unsignedLongLongValue]);

      expect([plURL floatForKey:kFLOAT]).to.equal((CGFloat) [assetDict[kVALUES][kFLOAT] floatValue]);
      expect([plURL doubleForKey:kDOUBLE]).to.equal((double) [assetDict[kVALUES][kDOUBLE] doubleValue]);

      expect([plURL boolForKey:kBOOL]).to.equal((BOOL) [assetDict[kVALUES][kBOOL] boolValue]);

      expect([plURL dictionaryForKey:kDICTIONARY]).to.equal((NSMutableDictionary *) assetDict[kVALUES][kDICTIONARY]);

      expect([plURL arrayForKey:kARRAY]).to.equal((NSMutableArray *) assetDict[kVALUES][kARRAY]);

      expect([plURL stringForKey:kSTRING]).to.equal((NSString *) assetDict[kVALUES][kSTRING]);

      expect([plURL dateForKey:kDATE]).to.equal((NSDate *) assetDict[kVALUES][kDATE]);

      expect([plURL numberForKey:kNUMBER]).to.equal((NSNumber *) assetDict[kVALUES][kNUMBER]);

      expect([plURL dataForKey:kDATA]).to.equal((NSData *) assetDict[kVALUES][kDATA]);
    });



    //------------------------ -o-
    it(@"06. remove elements, then verify they are missing in both object and file (plURLTwo)",
    ^{
      NSUInteger  originalPropertyListObjectCount = [plURL numberOfObjects];

      [plURL removeObjectForKey:kDICTIONARY];
      [plURL removeObjectForKey:kULONGLONG];

      expect([plURL numberOfObjects]).to.equal(originalPropertyListObjectCount - 2);
      expect([plURL dictionaryForKey:kDICTIONARY]).to.beNil();
      expect([plURL uLongLongForKey:kULONGLONG]).to.equal(0);

      //
      plURLTwo = [[MOSPropertyList alloc] initWithURL:plURL.url];
      expect(plURLTwo).toNot.beNil();

      expect([plURLTwo numberOfObjects]).to.equal(originalPropertyListObjectCount - 2);
      expect([plURLTwo dictionaryForKey:kDICTIONARY]).to.beNil();
      expect([plURLTwo uLongLongForKey:kULONGLONG]).to.equal(0);
    });



    //------------------------ -o-
    it(@"07. delete property list, then demonstrate list is empty and that file is missing",
    ^{
      rval = [plURL delete];
      expect(rval).to.beTruthy();

      expect([plURL numberOfObjects]).to.equal(0);
      expect([plURL dateForKey:kDATE]).to.beNil();

      expect([plURL.url doesExist]).to.beFalsy();
    });



    //------------------------ -o-
    it(@"08. re-open with filename (plFileThree), then verify list is empty",
    ^{
      plFileThree = [[MOSPropertyList alloc] initWithFilename:assetDict[kNAMING][kFILENAME]];
      expect(plFileThree).toNot.beNil();

      expect([plFileThree numberOfObjects]).to.equal(0);
      expect([plFileThree dateForKey:kDATE]).to.beNil();
    });



    //------------------------ -o-
    it(@"09. open new property list file in a non-default directory (plURLThree)",
    ^{
      plURLThree = [[MOSPropertyList alloc] initWithURL:[sandbox.workspaceURL appendPathToFile:assetDict[kNAMING][kANOTHERFILENAME]] overwrite:YES];
      expect(plURLThree).toNot.beNil();
    });



    //------------------------ -o-
    it(@"10. write select values to property list, then verify these values",
    ^{
      [plURLThree setObject:assetDict[kVALUES][kFLOAT]   forKey:kFLOAT];
      [plURLThree setObject:assetDict[kVALUES][kDOUBLE]  forKey:kDOUBLE];

      [plURLThree setObject:assetDict[kVALUES][kSTRING]  forKey:kSTRING];
      [plURLThree setObject:assetDict[kVALUES][kDATE]    forKey:kDATE];
      [plURLThree setObject:assetDict[kVALUES][kNUMBER]  forKey:kNUMBER];
      [plURLThree setObject:assetDict[kVALUES][kDATA]    forKey:kDATA];

      //
      expect([plURLThree floatForKey:kFLOAT]).to.equal((CGFloat) [assetDict[kVALUES][kFLOAT] floatValue]);
      expect([plURLThree doubleForKey:kDOUBLE]).to.equal((double) [assetDict[kVALUES][kDOUBLE] doubleValue]);

      expect([plURLThree stringForKey:kSTRING]).to.equal((NSString *) assetDict[kVALUES][kSTRING]);
      expect([plURLThree dateForKey:kDATE]).to.equal((NSDate *) assetDict[kVALUES][kDATE]);
      expect([plURLThree numberForKey:kNUMBER]).to.equal((NSNumber *) assetDict[kVALUES][kNUMBER]);
      expect([plURLThree dataForKey:kDATA]).to.equal((NSData *) assetDict[kVALUES][kDATA]);
    });



    //------------------------ -o-
    it(@"11. save property list, open new property list URL (plURLFour), then verify these values",
    ^{
      NSURL  *saveLocation = [[sandbox.workspaceURL appendPathToDirectory:@"dirOne/dirTwo"]
				 appendPathToFile: assetDict[kNAMING][kYETANOTHERFILENAME] 
				    withExtension: @"plist" ];

MOS_DUMPO(saveLocation, [saveLocation path]);
      rval = [plURLThree saveWithURL:saveLocation];
      expect(rval).to.beTruthy();

      //
      plURLFour = [[MOSPropertyList alloc] initWithURL:saveLocation];

      expect([plURLFour floatForKey:kFLOAT]).to.equal((CGFloat) [assetDict[kVALUES][kFLOAT] floatValue]);
      expect([plURLFour doubleForKey:kDOUBLE]).to.equal((double) [assetDict[kVALUES][kDOUBLE] doubleValue]);

      expect([plURLFour stringForKey:kSTRING]).to.equal((NSString *) assetDict[kVALUES][kSTRING]);
      expect([plURLFour dateForKey:kDATE]).to.equal((NSDate *) assetDict[kVALUES][kDATE]);
      expect([plURLFour numberForKey:kNUMBER]).to.equal((NSNumber *) assetDict[kVALUES][kNUMBER]);
      expect([plURLFour dataForKey:kDATA]).to.equal((NSData *) assetDict[kVALUES][kDATA]);
    });



    //------------------------ -o-
    it(@"12. re-open property list file (plURLThree) with overwrite option, then verify list is empty",
    ^{
      plURLThree = [[MOSPropertyList alloc] initWithURL:[sandbox.workspaceURL appendPathToFile:assetDict[kNAMING][kANOTHERFILENAME]] overwrite:YES];
      expect(plURLThree).toNot.beNil();

      expect([plURLThree numberOfObjects]).to.equal(0);
      expect([plURLThree stringForKey:kSTRING]).to.beNil();
    });



    //------------------------ -o-
    it(@"13. delete default directory",
    ^{
      rval = [MOSPropertyList deleteDefaultDirectory];
      expect(rval).to.beTruthy();
    });


  }); // context -- #A :: URLs and FILEs.




  //-------------------------------------------------- -o--
  // #B :: USER DEFAULTS.
  //
  //   01. initialize property list in UserDefaults (plUserDefaults), then verify test objects
  //
  //   02. write values to property list, one for each available method
  //   03. re-open property list in UserDefaults (plUserDefaultsTwo)
  //   04. read and verify values written to property list
  //
  //   05. remove elements, then verify they are missing in both object and in UserDefaults (plUserDefaultsThree)
  //   06. delete property list, then demonstrate list is empty and missing in UserDefaults
  //   07. re-open in UserDefaults (plUserDefaultsFour), then verify list is empty
  //
  //   08. write select values to property list, then verify these values
  //   09. re-open property list in UserDefaults (plUserDefaultsFive) with overwrite option, then verify list is empty
  //
  context(@"#B :: USER DEFAULTS.",
  ^{
    __block  MOSPropertyList  *plUserDefaults, *plUserDefaultsTwo, *plUserDefaultsThree, *plUserDefaultsFour, *plUserDefaultsFive;

    __block  BOOL  rval;




    //------------------------ -o-
    it(@"01. initialize property list in UserDefaults (plUserDefaults), then verify test objects",
    ^{
      plUserDefaults = [[MOSPropertyList alloc] initInUserDefaultsWithRootKey:assetDict[kNAMING][kUDROOT] overwrite:YES];

      expect([sandbox errorCounter]).to.equal(0);
      expect(plUserDefaults).notTo.beNil();
    });



    //------------------------ -o-
    it(@"02. write values to property list, one for each available method",
    ^{
      [plUserDefaults setObject:assetDict[kVALUES][kINTEGER]        forKey:kINTEGER];
      [plUserDefaults setObject:assetDict[kVALUES][kUINTEGER]       forKey:kUINTEGER];

      [plUserDefaults setObject:assetDict[kVALUES][kLONGLONG]       forKey:kLONGLONG];
      [plUserDefaults setObject:assetDict[kVALUES][kULONGLONG]      forKey:kULONGLONG];

      [plUserDefaults setObject:assetDict[kVALUES][kFLOAT]          forKey:kFLOAT];
      [plUserDefaults setObject:assetDict[kVALUES][kDOUBLE]         forKey:kDOUBLE];

      [plUserDefaults setObject:assetDict[kVALUES][kBOOL]           forKey:kBOOL];

      [plUserDefaults setObject:assetDict[kVALUES][kDICTIONARY]     forKey:kDICTIONARY];
      [plUserDefaults setObject:assetDict[kVALUES][kARRAY]          forKey:kARRAY];
      [plUserDefaults setObject:assetDict[kVALUES][kSTRING]         forKey:kSTRING];
      [plUserDefaults setObject:assetDict[kVALUES][kDATE]           forKey:kDATE];
      [plUserDefaults setObject:assetDict[kVALUES][kNUMBER]         forKey:kNUMBER];
      [plUserDefaults setObject:assetDict[kVALUES][kDATA]           forKey:kDATA];

      [plUserDefaults dump];
    });



    //------------------------ -o-
    it(@"03. re-open property list in UserDefaults (plUserDefaultsTwo)",
    ^{
      plUserDefaultsTwo = [[MOSPropertyList alloc] initInUserDefaultsWithRootKey:plUserDefaults.userDefaultsDictionaryRoot  overwrite:NO];
      expect(plUserDefaultsTwo).toNot.beNil();
    });



    //------------------------ -o-
    it(@"04. read and verify values written to property list",
    ^{
      expect([plUserDefaultsTwo integerForKey:kINTEGER]).to.equal((NSInteger) [assetDict[kVALUES][kINTEGER] integerValue]);
      expect([plUserDefaultsTwo uIntegerForKey:kUINTEGER]).to.equal((NSUInteger) [assetDict[kVALUES][kUINTEGER] unsignedIntegerValue]);

      expect([plUserDefaultsTwo longLongForKey:kLONGLONG]).to.equal((long long) [assetDict[kVALUES][kLONGLONG] longLongValue]);
      expect([plUserDefaultsTwo uLongLongForKey:kULONGLONG]).to.equal((unsigned long long) [assetDict[kVALUES][kULONGLONG] unsignedLongLongValue]);

      expect([plUserDefaultsTwo floatForKey:kFLOAT]).to.equal((CGFloat) [assetDict[kVALUES][kFLOAT] floatValue]);
      expect([plUserDefaultsTwo doubleForKey:kDOUBLE]).to.equal((double) [assetDict[kVALUES][kDOUBLE] doubleValue]);

      expect([plUserDefaultsTwo boolForKey:kBOOL]).to.equal((BOOL) [assetDict[kVALUES][kBOOL] boolValue]);

      expect([plUserDefaultsTwo dictionaryForKey:kDICTIONARY]).to.equal((NSMutableDictionary *) assetDict[kVALUES][kDICTIONARY]);

      expect([plUserDefaultsTwo arrayForKey:kARRAY]).to.equal((NSMutableArray *) assetDict[kVALUES][kARRAY]);

      expect([plUserDefaultsTwo stringForKey:kSTRING]).to.equal((NSString *) assetDict[kVALUES][kSTRING]);

      expect([plUserDefaultsTwo dateForKey:kDATE]).to.equal((NSDate *) assetDict[kVALUES][kDATE]);

      expect([plUserDefaultsTwo numberForKey:kNUMBER]).to.equal((NSNumber *) assetDict[kVALUES][kNUMBER]);

      expect([plUserDefaultsTwo dataForKey:kDATA]).to.equal((NSData *) assetDict[kVALUES][kDATA]);
    });



    //------------------------ -o-
    it(@"05. remove elements, then verify they are missing in both object and in UserDefaults (plUserDefaultsThree)",
    ^{
      NSUInteger  originalPropertyListObjectCount = [plUserDefaultsTwo numberOfObjects];

      [plUserDefaultsTwo removeObjectForKey:kDICTIONARY];
      [plUserDefaultsTwo removeObjectForKey:kULONGLONG];

      expect([plUserDefaultsTwo numberOfObjects]).to.equal(originalPropertyListObjectCount - 2);
      expect([plUserDefaultsTwo dictionaryForKey:kDICTIONARY]).to.beNil();
      expect([plUserDefaultsTwo uLongLongForKey:kULONGLONG]).to.equal(0);

      //
      plUserDefaultsThree = [[MOSPropertyList alloc] initInUserDefaultsWithRootKey:plUserDefaultsTwo.userDefaultsDictionaryRoot];
      expect(plUserDefaultsThree).toNot.beNil();

      expect([plUserDefaultsThree numberOfObjects]).to.equal(originalPropertyListObjectCount - 2);
      expect([plUserDefaultsThree dictionaryForKey:kDICTIONARY]).to.beNil();
      expect([plUserDefaultsThree uLongLongForKey:kULONGLONG]).to.equal(0);
    });



    //------------------------ -o-
    it(@"06. delete property list, then demonstrate list is empty and missing in UserDefaults",
    ^{
      rval = [plUserDefaultsThree delete];
      expect(rval).to.beTruthy();

      expect([plUserDefaultsThree numberOfObjects]).to.equal(0);
      expect([plUserDefaultsThree dateForKey:kDATE]).to.beNil();

      //
      NSDictionary  *userDefaultsRoot = [[NSUserDefaults standardUserDefaults] 
					    objectForKey:assetDict[kNAMING][kUDROOTWITHPREFIX]];
      expect(userDefaultsRoot).to.beNil();
    });



    //------------------------ -o-
    it(@"07. re-open in UserDefaults (plUserDefaultsFour), then verify list is empty",
    ^{
      plUserDefaultsFour = [[MOSPropertyList alloc] initInUserDefaultsWithRootKey:assetDict[kNAMING][kUDROOT]];
      expect(plUserDefaultsFour).toNot.beNil();

      expect([plUserDefaultsFour numberOfObjects]).to.equal(0);
      expect([plUserDefaultsFour dateForKey:kDATE]).to.beNil();
    });



    //------------------------ -o-
    it(@"08. write select values to property list, then verify these values",
    ^{
      [plUserDefaultsFour setObject:assetDict[kVALUES][kFLOAT]   forKey:kFLOAT];
      [plUserDefaultsFour setObject:assetDict[kVALUES][kDOUBLE]  forKey:kDOUBLE];

      [plUserDefaultsFour setObject:assetDict[kVALUES][kSTRING]  forKey:kSTRING];
      [plUserDefaultsFour setObject:assetDict[kVALUES][kDATE]    forKey:kDATE];
      [plUserDefaultsFour setObject:assetDict[kVALUES][kNUMBER]  forKey:kNUMBER];
      [plUserDefaultsFour setObject:assetDict[kVALUES][kDATA]    forKey:kDATA];

      //
      expect([plUserDefaultsFour floatForKey:kFLOAT]).to.equal((CGFloat) [assetDict[kVALUES][kFLOAT] floatValue]);
      expect([plUserDefaultsFour doubleForKey:kDOUBLE]).to.equal((double) [assetDict[kVALUES][kDOUBLE] doubleValue]);

      expect([plUserDefaultsFour stringForKey:kSTRING]).to.equal((NSString *) assetDict[kVALUES][kSTRING]);
      expect([plUserDefaultsFour dateForKey:kDATE]).to.equal((NSDate *) assetDict[kVALUES][kDATE]);
      expect([plUserDefaultsFour numberForKey:kNUMBER]).to.equal((NSNumber *) assetDict[kVALUES][kNUMBER]);
      expect([plUserDefaultsFour dataForKey:kDATA]).to.equal((NSData *) assetDict[kVALUES][kDATA]);
    });



    //------------------------ -o-
    it(@"09. re-open property list in UserDefaults (plUserDefaultsFive) with overwrite option, then verify list is empty",
    ^{
      plUserDefaultsFive = [[MOSPropertyList alloc] initInUserDefaultsWithRootKey:plUserDefaultsFour.userDefaultsDictionaryRoot overwrite:YES];
      expect(plUserDefaultsFive).toNot.beNil();

      expect([plUserDefaultsFive numberOfObjects]).to.equal(0);
      expect([plUserDefaultsFive stringForKey:kSTRING]).to.beNil();
    });


  }); // context -- #B :: USER DEFAULTS.

}); // describe -- MOSPropertyList


SpecEnd // MOSPropertyList

