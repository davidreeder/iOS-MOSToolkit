//
// NSData+MOSZed.m
//
// DEPENDENCIES: MOSLog
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#import "NSData+MOSZed.h"



//------------------------------------------------ -o-
@implementation NSData (MOSZed)

//------------------------------- -o-
+ (NSData *)  randomDataOfSize: (NSUInteger) sizeInBytes
		   withPattern: (NSString *) fourByteHexPattern
{
  if ( (nil != fourByteHexPattern) && (8 != [fourByteHexPattern length]) )
  {
    MOS_LOG_ERROR(@"fourByteHexPattern is not 8 characters.");
    return nil;
  }


  //
  if (!fourByteHexPattern) 
  {
    const char  *hexChar = [@"abcdef0123456789" cStringUsingEncoding:NSASCIIStringEncoding];
    NSString    *randomPattern = @"";

    sranddev();

    for (int i = 8; i > 0; i--) {
      randomPattern = [randomPattern stringByAppendingString:
                        [NSString stringWithFormat:@"%c", hexChar[rand() % 16] ]];
    }

    fourByteHexPattern = randomPattern;
  }


  //
  NSScanner     *scanner = [NSScanner scannerWithString:fourByteHexPattern];
  unsigned int   bytePattern;

  BOOL  rval = [scanner scanHexInt:&bytePattern];
  if (!rval) {
    MOS_LOG_ERROR(@"fourByteHexPattern (\"%@\") is not a hexadecimal number.", fourByteHexPattern);
    return nil;
  }
  bytePattern = (unsigned int) htonl((__uint32_t)bytePattern);

  char  *newData = (char *) malloc(sizeInBytes);
  if (!newData) {
    MOS_LOG_ERROR(@"Could not malloc() newData.");
    return nil;
  }

  memset_pattern4((void *)newData, (const void *)&bytePattern, sizeInBytes);


  //
  return [NSData dataWithBytesNoCopy:newData length:sizeInBytes freeWhenDone:YES];
  		
} // randomDataOfSize:withPattern:

@end

