//
// NSDictionary+MOSZed.m
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#import "NSDictionary+MOSZed.h"



//------------------------------------------------ -o--
@implementation NSDictionary (MOSZed)

#pragma mark - Convenience methods.

//------------------------------- -o-
- (NSArray *) sortValuesWithKeyPath: (NSString *)keyPath
			  ascending: (BOOL)ascending
{
  NSMutableArray  *array = [[NSMutableArray alloc] init];

  for (id key in self) {
    [array addObject:[self objectForKey:key]];
  }

  NSSortDescriptor  *sd      = [[NSSortDescriptor alloc] initWithKey:keyPath ascending:ascending];
  NSArray           *sdList  = [NSArray arrayWithObjects:sd, nil];

  return [array sortedArrayUsingDescriptors:sdList];
}




//------------------------------------------------ -o--
#pragma mark - Simplify object fetch: Type cast result and copy when possible.

//------------------------------- -o-
- (NSInteger) integerForKey: (NSString *)key
{
  return [(NSNumber *)[self objectForKey:key] integerValue];
}

//------------------------------- -o-
- (NSUInteger) uIntegerForKey: (NSString *)key
{
  return [(NSNumber *)[self objectForKey:key] unsignedIntegerValue];
}


//------------------------------- -o-
- (short) shortForKey: (NSString *)key
{
  return [(NSNumber *)[self objectForKey:key] shortValue];
}

//------------------------------- -o-
- (unsigned short) uShortForKey: (NSString *)key
{
  return [(NSNumber *)[self objectForKey:key] unsignedShortValue];
}


//------------------------------- -o-
- (long long) longLongForKey: (NSString *)key
{
  return [(NSNumber *)[self objectForKey:key] longLongValue];
}

//------------------------------- -o-
- (unsigned long long) uLongLongForKey: (NSString *)key
{
  return [(NSNumber *)[self objectForKey:key] unsignedLongLongValue];
}


//------------------------------- -o-
- (CGFloat) floatForKey: (NSString *)key
{
  return [(NSNumber *)[self objectForKey:key] floatValue];
}

//------------------------------- -o-
- (double) doubleForKey: (NSString *)key
{
  return [(NSNumber *)[self objectForKey:key] doubleValue];
}


//------------------------------- -o-
- (BOOL) boolForKey: (NSString *)key
{
  return [(NSNumber *)[self objectForKey:key] boolValue];
}


//------------------------------- -o-
- (NSMutableDictionary *) dictionaryForKey: (NSString *)key
{
  return [[self objectForKey:key] mutableCopy];
}


//------------------------------- -o-
- (NSMutableArray *) arrayForKey: (NSString *)key
{
  return [[self objectForKey:key] mutableCopy];
}


//------------------------------- -o-
- (NSString *) stringForKey: (NSString *)key
{
  return [[self objectForKey:key] mutableCopy];
}


//------------------------------- -o-
- (NSDate *) dateForKey: (NSString *)key
{
  return [self objectForKey:key];
}


//------------------------------- -o-
- (NSNumber *) numberForKey: (NSString *)key
{
  return [self objectForKey:key];
}


//------------------------------- -o-
- (NSMutableData *) dataForKey: (NSString *)key
{
  return [[self objectForKey:key] mutableCopy];
}


@end

