//
// MOSPropertyList.h
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_PropertyList  0.2

#import "MOSMobileSound.h"



//------------------------------------------------------------ -o-
@interface MOSPropertyList : NSObject

  @property  (strong, nonatomic, readonly)  NSURL      *url;
  @property  (strong, nonatomic, readonly)  NSString   *userDefaultsDictionaryRoot;
      // NB  url and userDefaultsDictionaryRoot are mutually exclusive, only one may be defined in a given instance.

  @property  (nonatomic, readonly, getter=isUsingUserDefaults)  BOOL  usingUserDefaults;


  //
  - (id) initWithURL: (NSURL *)url 
	   overwrite: (BOOL)shouldOverwrite;

  - (id) initWithURL: (NSURL *)url;

  - (id) initWithFilename: (NSString *)filename
		overwrite: (BOOL)shouldOverwrite;

  - (id) initWithFilename: (NSString *)filename;

  - (id) initInUserDefaultsWithRootKey: (NSString *)rootDictionaryName
			     overwrite: (BOOL)shouldOverwrite;

  - (id) initInUserDefaultsWithRootKey: (NSString *)rootDictionaryName;


  //
  - (void) setObject:(id)object forKey:(NSString *)key;

  - (void) removeObjectForKey: (NSString *)key;

  - (BOOL) doesKeyExist: (NSString *)key;

  - (NSUInteger) numberOfObjects;

  - (void) dump;

  - (BOOL) saveWithURL:(NSURL *)url;

  - (BOOL) delete;
  + (BOOL) deleteDefaultDirectory;


  //
  - (id)  objectForKey: (NSString *)key;

  - (NSInteger)   integerForKey: (NSString *)key;
  - (NSUInteger) uIntegerForKey: (NSString *)key;

  - (short)           shortForKey: (NSString *)key;
  - (unsigned short) uShortForKey: (NSString *)key;

  - (long long)           longLongForKey: (NSString *)key;
  - (unsigned long long) uLongLongForKey: (NSString *)key;

  - (CGFloat) floatForKey:  (NSString *)key;
  - (double)  doubleForKey: (NSString *)key;

  - (BOOL) boolForKey: (NSString *)key;

  - (NSMutableDictionary *) dictionaryForKey: (NSString *)key;

  - (NSMutableArray *) arrayForKey: (NSString *)key;

  - (NSString *) stringForKey: (NSString *)key;

  - (NSDate *) dateForKey: (NSString *)key;

  - (NSNumber *) numberForKey: (NSString *)key;

  - (NSData *) dataForKey: (NSString *)key;

@end

