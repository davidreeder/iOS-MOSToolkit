//
// MOSPropertyList.m
//
// Manage property lists.  
// Via files/URLs or alternatively in UserDefaults.
//
//
// Naming conventions for files--
//   . Initializing with a filename always creates the property list in  
//       MOS_PROPERTYLIST_DIRECTORY at the root of the application file system;
//   . Property lists initialized as URLs may be stored anywhere available to the app;
//   . nil input at initialization always creates MOS_PROPERTYLIST_DEFAULT_FILENAME 
//       within MOS_PROPERTYLIST_DIRECTORY.
//
// NB--
//   . Not threadsafe;
//   . Multiple instances of files will not stay in sync and may overwrite one another.
//
//
// CLASS DEPENDENCIES: 
//   NSString+MOSLog
//   NSDictionary+MOSZed, NSDictionary+MOSDump
//   NSURL+MOSZed
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#import "MOSPropertyList.h"




//------------------------------------------------------------ -o-
#define MOS_PROPERTYLIST_USERDEFAULTS         [NSUserDefaults standardUserDefaults]
#define MOS_PROPERTYLIST_USERDEFAULTS_SYNC()  [MOS_PROPERTYLIST_USERDEFAULTS synchronize]

//
#define MOS_PROPERTYLIST_DIRECTORY         @"MOSPropertyListDirectory"
#define MOS_PROPERTYLIST_DEFAULT_FILENAME  @"MOSPropertyListDefaultFile"
#define MOS_PROPERTYLIST_DEFAULT_ROOT      @"MOSPropertyListDefaultRoot"




//------------------------------------------------------------ -o--
@interface MOSPropertyList() 

  @property  (strong, nonatomic, readwrite)  NSURL      *url;
  @property  (strong, nonatomic, readwrite)  NSString   *userDefaultsDictionaryRoot;

  @property  (nonatomic, readwrite, getter=isUsingUserDefaults)  BOOL  usingUserDefaults;

  @property  (strong, nonatomic)  NSMutableDictionary  *propertyListDictionary;


  //
  - (id) initWithURL: (NSURL *)url 
           overwrite: (BOOL)shouldOverwrite   NS_DESIGNATED_INITIALIZER;

  - (id) initInUserDefaultsWithRootKey: (NSString *)rootDictionaryName
                             overwrite: (BOOL)shouldOverwrite   NS_DESIGNATED_INITIALIZER;


  //
  - (NSURL *) defaultURLWithFilename: (NSString *)filename;
  - (NSString *) udRootWithPrefix;
  - (BOOL) sync;

@end




//------------------------------------------------------------ -o--
@implementation MOSPropertyList

#pragma mark - Constructors.

//-------------------------------- -o-
- (id) init
{
  return  [self initWithURL:nil overwrite:NO];
}


//-------------------------------- -o-
- (id) initWithURL: (NSURL *)url 
         overwrite: (BOOL)shouldOverwrite               // NS_DESIGNATED_INITIALIZER
{
  if (!(self = [super init])) {
    MOS_LOG_ERROR(@"[super init] FAILED.");
    return nil;
  }

  if (url) {
    if (![url createDirectoryPathToFile])  { return nil; }
  } else {
    url = [self defaultURLWithFilename:nil];
    if (!url)  { return nil; }
  }


  //
  if (shouldOverwrite)
  {
    if ([url doesExist]) {
      MOS_LOG_WARNING(@"DELETING existing URL. (%@)", [url path]);

      if (![url remove]) {
        MOS_LOG_ERROR(@"FAILED to delete existing URL. (%@)", [url path]);
        return nil;
      }
    }

  } else {
    if ([url doesExist]) {
      _propertyListDictionary = [[NSDictionary dictionaryWithContentsOfURL:url] mutableCopy];

      if (! _propertyListDictionary) {
        MOS_LOG_ERROR(@"FAILED to read existing property list URL. (%@)", [url path]);
        return nil;
      }
    }
  }


  //
  _url = url;

  if (!_propertyListDictionary) {
    _propertyListDictionary = [[NSMutableDictionary alloc] init];
  }

  if (![self sync]) {
    MOS_LOG_ERROR(@"FAILED to create property list URL. (%@)", [url path]);
    return nil;
  }

  

  return self;
}

//-------------------------------- -o-
- (id) initWithURL: (NSURL *)url 
{
  return [self initWithURL:url overwrite:NO];
}



//-------------------------------- -o-
- (id) initWithFilename: (NSString *)filename
              overwrite: (BOOL)shouldOverwrite
{
  NSURL  *newURL = [self defaultURLWithFilename:filename];

  if (!newURL)  { return nil; }

  return [self initWithURL:newURL overwrite:shouldOverwrite];
}

//-------------------------------- -o-
- (id) initWithFilename: (NSString *)filename
{
  return [self initWithFilename:filename overwrite:NO];
}



//-------------------------------- -o-
- (id) initInUserDefaultsWithRootKey: (NSString *)rootDictionaryName
                           overwrite: (BOOL)shouldOverwrite                // NS_DESIGNATED_INITIALIZER
{
  if (!(self = [super init])) {
    MOS_LOG_ERROR(@"[super init] FAILED.");
    return nil;
  }

  _usingUserDefaults = YES;


  //
  _userDefaultsDictionaryRoot = (rootDictionaryName) ? rootDictionaryName : MOS_PROPERTYLIST_DEFAULT_ROOT;


  //
  if (shouldOverwrite)
  {
    if ([MOS_PROPERTYLIST_USERDEFAULTS dictionaryForKey:[self udRootWithPrefix]]) {
      MOS_LOG_WARNING(@"DELETING pre-existing dictionary root. (%@)", [self udRootWithPrefix]);
      [MOS_PROPERTYLIST_USERDEFAULTS removeObjectForKey:[self udRootWithPrefix]];
    }

  } else {
    _propertyListDictionary = [[MOS_PROPERTYLIST_USERDEFAULTS dictionaryForKey:[self udRootWithPrefix]] mutableCopy];
  }


  //
  if (!_propertyListDictionary) {
    _propertyListDictionary = [[NSMutableDictionary alloc] init];
  }

  [self sync];  // XXX  Never fails.


  return self;
}

//-------------------------------- -o-
- (id) initInUserDefaultsWithRootKey: (NSString *)rootDictionaryName
{
  return [self initInUserDefaultsWithRootKey:rootDictionaryName overwrite:NO];
}




//------------------------------------------------------------ -o--
#pragma mark - Public methods.

//-------------------------------- -o-
// setObject:forKey:
//
// NB  Reading NSDate as an object from a new instance of MOSPropertyList
//     on a file seems to introduce errs in the decimal portion of the 
//     NSTimeInterval.  Not a problem with UserDefaults or within a single 
//     instance of MOSPropertyList on a file.  ?!
//     Converting to NSTimeInterval directly seems to avoid the problem...
//
// XXX  Incompatible with property lists that contain NSDates instead of their equivalent timeInterval double values.
//
- (void) setObject: (id)object 
            forKey: (NSString *)key
{
  if ([object isKindOfClass:[NSDate class]]) {
    [self setObject:@([(NSDate *)object timeIntervalSinceReferenceDate]) forKey:key];
  } else {
    [self.propertyListDictionary setObject:object forKey:key];
  }

  [self sync];
}


//-------------------------------- -o-
- (void) removeObjectForKey: (NSString *)key
{
  [self.propertyListDictionary removeObjectForKey:key];
  [self sync];
}


//-------------------------------- -o-
- (BOOL) doesKeyExist: (NSString *)key
{
  return (nil != [self objectForKey:key]);
}


//-------------------------------- -o-
- (NSUInteger) numberOfObjects
{
  return [self.propertyListDictionary count];
}



//-------------------------------- -o-
- (void) dump
{
  NSString  *header = [NSString stringWithFormat:@"In %@ @ %@",
			 [self isUsingUserDefaults] ? @"UserDefaults" : @"file",
			 [self isUsingUserDefaults] ? [self udRootWithPrefix] : self.url ];

  [self.propertyListDictionary dumpWithHeader:header];
}



//-------------------------------- -o-
- (BOOL) saveWithURL:(NSURL *)url
{
  if (![url createDirectoryPathToFile])  { return NO; }

  if (![self.propertyListDictionary writeToURL:url atomically:YES]) {
    MOS_LOG_ERROR(@"FAILED to write property list URL. (%@)", [url path]);
    return NO;
  }

  return YES;
}



//-------------------------------- -o-
// delete
//
// Does not sync in normal fashion.  
// Remove all traces of UserDefaults root or property list file, respectively.
// Recreate property list dictionary internally, but wait until new data 
//   is written before recreating an actual property list.
//
// RETURNS:  YES  if property list is deleted
//           NO   on error -- internal property list is also retained.
//
- (BOOL) delete
{
  if (self.isUsingUserDefaults) {
    [MOS_PROPERTYLIST_USERDEFAULTS removeObjectForKey:[self udRootWithPrefix]];
    MOS_PROPERTYLIST_USERDEFAULTS_SYNC();

  } else {
    if (![self.url remove]) {
      MOS_LOG_ERROR(@"FAILED to delete URL. (%@)", [self.url path]);
      return NO;
    }
  }

  self.propertyListDictionary = [[NSMutableDictionary alloc] init];


  return YES;
}


//-------------------------------- -o-
+ (BOOL) deleteDefaultDirectory
{
  NSURL  *defaultDirectory = [[NSURL userRootDirectory] appendPathToDirectory:MOS_PROPERTYLIST_DIRECTORY];

  if ([defaultDirectory doesExist]) {
    return [defaultDirectory remove];
  }

  return YES;
}



//-------------------------------- -o-
- (id) objectForKey: (NSString *)key
{
  return [self.propertyListDictionary objectForKey:key];
}


//-------------------------------- -o-
- (NSInteger) integerForKey: (NSString *)key
{
  return [self.propertyListDictionary integerForKey:key];
}

//-------------------------------- -o-
- (NSUInteger) uIntegerForKey: (NSString *)key
{
  return [self.propertyListDictionary uIntegerForKey:key];
}


//-------------------------------- -o-
- (short) shortForKey: (NSString *)key
{
  return [self.propertyListDictionary shortForKey:key];
}

//-------------------------------- -o-
- (unsigned short) uShortForKey: (NSString *)key
{
  return [self.propertyListDictionary uShortForKey:key];
}


//-------------------------------- -o-
- (long long) longLongForKey: (NSString *)key
{
  return [self.propertyListDictionary longLongForKey:key];
}

//-------------------------------- -o-
- (unsigned long long) uLongLongForKey: (NSString *)key
{
  return [self.propertyListDictionary uLongLongForKey:key];
}


//-------------------------------- -o-
- (CGFloat) floatForKey: (NSString *)key
{
  return [self.propertyListDictionary floatForKey:key];
}

//-------------------------------- -o-
- (double) doubleForKey: (NSString *)key
{
  return [self.propertyListDictionary doubleForKey:key];
}


//-------------------------------- -o-
- (BOOL) boolForKey: (NSString *)key
{
  return [self.propertyListDictionary boolForKey:key];
}


//-------------------------------- -o-
- (NSMutableDictionary *) dictionaryForKey: (NSString *)key
{
  return [self.propertyListDictionary dictionaryForKey:key];
}


//-------------------------------- -o-
- (NSMutableArray *) arrayForKey: (NSString *)key
{
  return [self.propertyListDictionary arrayForKey:key];
}


//-------------------------------- -o-
- (NSString *) stringForKey: (NSString *)key
{
  return [self.propertyListDictionary stringForKey:key];
}


//-------------------------------- -o-
// dateForKey:
//
// Cf. setObject:forKey:.
//
- (NSDate *) dateForKey: (NSString *)key
{
  NSTimeInterval  ti = [[self.propertyListDictionary numberForKey:key] doubleValue];

  if (0 >= ti) {
    return nil;
  } else {
    return [NSDate dateWithTimeIntervalSinceReferenceDate:ti];
  }
}


//-------------------------------- -o-
- (NSNumber *) numberForKey: (NSString *)key
{
  return [self.propertyListDictionary numberForKey:key];
}


//-------------------------------- -o-
- (NSData *) dataForKey: (NSString *)key
{
  return [self.propertyListDictionary dataForKey:key];
}




//------------------------------------------------------------ -o--
#pragma mark - Private methods.

//-------------------------------- -o-
- (NSURL *)  defaultURLWithFilename: (NSString *)filename
{
  NSURL  *newUrl = [[NSURL userRootDirectory] appendPathToDirectory:MOS_PROPERTYLIST_DIRECTORY];

  if (![newUrl createDirectory])  { return nil; }

  if (!filename) {
    filename = MOS_PROPERTYLIST_DEFAULT_FILENAME;
  }

  newUrl = [newUrl appendPathToFile:filename withExtension:@"plist"];

  if (!newUrl) { 
    MOS_LOG_ERROR(@"FAILED to generate url from filename. (%@)", filename);
  }

  return newUrl;
}


//-------------------------------- -o-
- (NSString *) udRootWithPrefix
{
  return [NSString stringWithFormat:@"__%@", self.userDefaultsDictionaryRoot];
}


//-------------------------------- -o-
- (BOOL) sync
{
  if (self.isUsingUserDefaults) 
  {
    [MOS_PROPERTYLIST_USERDEFAULTS setObject:self.propertyListDictionary forKey:[self udRootWithPrefix]];
    MOS_PROPERTYLIST_USERDEFAULTS_SYNC();

  } else {
    if (![self.propertyListDictionary writeToURL:self.url atomically:YES]) 
    {
      MOS_LOG_ERROR(@"FAILED to write property list URL. (%@)", [self.url path]);
      return NO;
    }
  }

  return YES;
}


@end // @implementation MOSPropertyList

