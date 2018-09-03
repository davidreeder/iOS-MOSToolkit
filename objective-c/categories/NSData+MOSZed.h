//
// NSData+MOSZed.h
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_NSData_Zed  0.1    // 


#import <Foundation/Foundation.h>

#import "MOSMobileSound.h"



//------------------------------------------------ -o-
@interface NSData (MOSZed)

  + (NSData *)  randomDataOfSize: (NSUInteger) sizeInBytes
		     withPattern: (NSString *) fourByteHexPattern;

@end

