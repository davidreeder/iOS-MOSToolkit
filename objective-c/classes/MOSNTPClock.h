//
// MOSNTPClock.h
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_NTPClock 0.2  

#import "ios-ntp.h"

#import "NSString+MOSLog.h"




//-------------------------------------------------------------- -o--
#define kMOSNTPClockTimeoutBadNotification   @"kMOSNTPClockTimeoutBadNotification"
#define kMOSNTPClockTimeoutGoodNotification  @"kMOSNTPClockTimeoutGoodNotification"




//-------------------------------------------------------------- -o--
@interface MOSNTPClock : NSObject

  @property  (nonatomic, getter=isProtocolActive, readonly)  BOOL  protocolActive;
      // YES if NTP protocol is actively determining current time.

  @property  (nonatomic, readonly)                           BOOL  synchronizationSuccess;
      // YES if NTP protocol completes within acceptable limits.

  @property  (nonatomic, readonly)  NSUInteger     countOfSuccessfulResponses;
  @property  (nonatomic, readonly)  NSUInteger     countOfFailedTimerStarts;


  //
  + (MOSNTPClock *)sharedClient;

  - (void) start;
  - (void) startWithTimer;
  - (void) stop;

  - (NSDate *) date;
  - (NSDate *) dateWithOffset: (NSTimeInterval)offset;

  - (NSTimeInterval) differenceFromSystemDate;
  - (NSTimeInterval) differenceFromSystemDateWithOffset: (NSTimeInterval)offset;

@end



