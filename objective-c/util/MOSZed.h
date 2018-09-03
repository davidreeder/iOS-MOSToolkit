//
// MOSZed.h
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_Zed  0.7

#import "MOSMobileSound.h"




//------------------------------------------------------------ -o--
#define MOS_STR_NS2C(s)                                                               \
    ((char *) [[NSData dataWithBytes: [s cStringUsingEncoding:NSASCIIStringEncoding]  \
                              length: [s length] + 1                                  \
                ] bytes] )


// ASSUMES  queueVariable has already been declared.
//
#define MOS_CREATE_SERIAL_QUEUE(queueVariable, label)                                      \
    {                                                                                      \
      NSString  *newLabel = [MOS_CODE_LOCATION stringByAppendingFormat:@" -- %@", label];  \
      queueVariable = dispatch_queue_create(MOS_STR_NS2C(newLabel), NULL);                 \
    }

