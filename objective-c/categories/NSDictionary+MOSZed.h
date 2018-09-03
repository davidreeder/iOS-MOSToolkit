//
// NSDictionary+MOSZed.h
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_NSDictionary_MOSZed  0.2


#import <Foundation/Foundation.h>



//------------------------------------------------ -o-
@interface NSDictionary (MOSZed)

  // 
  - (NSArray *) sortValuesWithKeyPath: (NSString *)keyPath
			    ascending: (BOOL)ascending;


  // Simplify object fetch: type cast result and copy when possible.
  //
  - (NSInteger)   integerForKey: (NSString *)key;
  - (NSUInteger) uIntegerForKey: (NSString *)key;

  - (short)           shortForKey: (NSString *)key;
  - (unsigned short) uShortForKey: (NSString *)key;

  - (long long)           longLongForKey: (NSString *)key;
  - (unsigned long long) uLongLongForKey: (NSString *)key;

  - (CGFloat) floatForKey: (NSString *)key;
  - (double) doubleForKey: (NSString *)key;

  - (BOOL) boolForKey: (NSString *)key;

  - (NSMutableDictionary *) dictionaryForKey: (NSString *)key;

  - (NSMutableArray *) arrayForKey: (NSString *)key;

  - (NSString *) stringForKey: (NSString *)key;

  - (NSDate *) dateForKey: (NSString *)key;

  - (NSNumber *) numberForKey: (NSString *)key;

  - (NSMutableData *) dataForKey: (NSString *)key;

@end

