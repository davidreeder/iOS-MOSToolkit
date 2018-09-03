//
// MOSNTPClock.m
//
// Implement timer to limit usage of NTP:
//   . Provides simple backoff in case of failure
//   . Use previous synchronization values (if any) in case of error
// Class level notifications regarding success/failure.
// Provide NTP time -OR- NTP time + arbitrary offset.  
// Test whether NTP protocol is currently active; test whether last iteration 
//   of time synchronization was successful.
// 
// Wrapper for ios-ntp.  Cloned from https://github.com/jbenet/ios-ntp 
//   circa early July 2014.
//
//
// BUILD REQUIREMENTS for ios-ntp--
//   (XCode target) --> Build Phases --> Compile Sources --> Compiler Flags
//       GCDAsyncUdpSocket.m  -fno-objc-arc -Wno-deprecated-declarations
//       NetAssociation.m     -fno-objc-arc 
//       NetworkClock.m       -fno-objc-arc 
//
// CHANGES to ios-ntp--
//   . Adapted ios-ntp.h to include ios-ntp-prefix.h --
//       Preceded with optional #define IOS_NTP_LOGGING.
//   . Added instance variable NetworkClock :: enableUponForegrounding --
//       Allows the class to be foregrounded without re-activating NTP.
//   . Add NetworkClock :: networkTimeWithOffset --
//       Allows fudge factor on returned time.
//   . Clarify Notification identifiers: kNetAssociationNotification{Good,Fail}
//   . Specify C language numeric types.
//
// NB
//   NetworkClock :: sharedNetworkClock may still be started without custom
//     configuration if [NSDate networkTime] executes before [self 
//     sharedNTPClient].  This case may return (unstable) time before 
//     kMOSNTPClockSuccessCountThreshold is achieved.
//   By contrast, [self date] and [self differenceFromSystemDate] will return 
//     out of bound values upon error or prior to NTP synchronization.
//
//
// CLASS DEPENDENCIES: NSString+MOSLog
//
//
// NOTIFICATIONS OBSERVED--
//   kNetAssociationNotificationGood  (from NetAssociation)
//   UIApplicationDidEnterBackgroundNotification  (from UIApplication)
//
// NOTIFICATIONS GENERATED--
//   kMOSNTPClockTimeoutBadNotification 
//   kMOSNTPClockTimeoutGoodNotification 
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#import "MOSNTPClock.h"



//-------------------------------------------------------------- -o--
#define kMOSNTPClockSuccessCountThreshold  10

#define kMOSNTPClockTimerInitialWindow     10.0



//-------------------------------------------------------------- -o--
@interface MOSNTPClock()

  @property  (strong, nonatomic)  NetworkClock   *sharedNTPClock;
  @property  (strong, nonatomic)  NSTimer        *synchronizationTimer;

  @property  (nonatomic)          NSTimeInterval  previousDifference;


  //
  @property  (nonatomic, readwrite, getter=isProtocolActive)  BOOL  protocolActive;
  @property  (nonatomic, readwrite)                           BOOL  synchronizationSuccess;

  @property  (nonatomic, readwrite)  NSUInteger     countOfSuccessfulResponses;
  @property  (nonatomic, readwrite)  NSUInteger     countOfFailedTimerStarts;



  //
  - (void) countNTPSuccess:(NSNotification *)notification;
  - (void) synchronizationTimerFires;

@end



//-------------------------------------------------------------- -o--
@implementation MOSNTPClock

#pragma mark - Lifecycle.


//--------------------- -o-
+ (MOSNTPClock *)sharedClient
{
  static MOSNTPClock      *sharedNTPClient = nil;
  static dispatch_once_t   onceToken;

  dispatch_once(&onceToken, ^{
    sharedNTPClient = [[self alloc] init];
  });
  
  return sharedNTPClient;
}


//--------------------- -o-
- (id) init
{
  if (!(self = [super init]))  { return nil; }

  _countOfFailedTimerStarts  = 0;
  _previousDifference        = DBL_MAX;

  return self;
}




//-------------------------------------------------------------- -o--
#pragma mark - Getters/setters.

//--------------------- -o-
- (NetworkClock *) sharedNTPClock
{
  if (! _sharedNTPClock) {
    _sharedNTPClock = [NetworkClock sharedNetworkClock];
    _sharedNTPClock->enableUponForegrounding = NO;
  }

  return _sharedNTPClock;
}
      



//-------------------------------------------------------------- -o--
#pragma mark - Notification receipt.

//--------------------- -o-
- (void) countNTPSuccess:(NSNotification *)notification
{
  self.countOfSuccessfulResponses += 1;

  if (self.countOfSuccessfulResponses < kMOSNTPClockSuccessCountThreshold) {
    return;
  }

  self.synchronizationSuccess    = YES;
  self.countOfFailedTimerStarts  = 0;
}




//-------------------------------------------------------------- -o--
#pragma mark - Instance methods.

//--------------------- -o-
- (void) start
{
  self.countOfSuccessfulResponses  = 0;
  self.synchronizationSuccess      = NO;

  [[NSNotificationCenter defaultCenter] addObserver: self 
                                           selector: @selector(countNTPSuccess:) 
                                               name: kNetAssociationNotificationGood
                                             object: nil ];

  [[NSNotificationCenter defaultCenter] addObserver: self 
                                           selector: @selector(stop) 
                                               name: UIApplicationDidEnterBackgroundNotification
                                             object: nil ];

  //
  [self.sharedNTPClock enableAssociations];
  self.protocolActive = YES;
}



//--------------------- -o-
// startWithTimer
//
// Geometrically increase timerDuration per number of failed starts.
//
- (void) startWithTimer
{
  NSTimeInterval   timerDuration = kMOSNTPClockTimerInitialWindow + (kMOSNTPClockTimerInitialWindow * self.countOfFailedTimerStarts);
  NSDate          *timerFireDate = [NSDate dateWithTimeIntervalSinceNow:timerDuration];

  self.synchronizationTimer = [[NSTimer alloc] initWithFireDate: timerFireDate
                                                       interval: DBL_MAX
                                                         target: self
                                                       selector: @selector(synchronizationTimerFires)
                                                       userInfo: nil
                                                        repeats: NO ];

  [self start];
  [[NSRunLoop mainRunLoop] addTimer:self.synchronizationTimer forMode:NSDefaultRunLoopMode];
}



//--------------------- -o-
- (void) synchronizationTimerFires
{
  [self stop];

  if (! self.synchronizationSuccess) 
  {
    self.countOfFailedTimerStarts += 1;
    [[NSNotificationCenter defaultCenter] postNotificationName:kMOSNTPClockTimeoutBadNotification object:self];

    if (self.previousDifference != DBL_MAX) {
      MOS_LOG_WARNING(@"Using PREVIOUSLY established NTP time. (difference=%f)", -self.previousDifference);

    } else {
      MOS_LOG_ERROR(@"FAILED to establish NTP time.");
    }

  } else {
    self.previousDifference = -[self differenceFromSystemDate];
    [[NSNotificationCenter defaultCenter] postNotificationName:kMOSNTPClockTimeoutGoodNotification object:self];
    MOS_LOG_INFO(@"SUCCESSFULLY established NTP time. (difference=%f)", -self.previousDifference);
  }


  self.synchronizationTimer = nil;
}



//--------------------- -o-
// stop
//
// NB  [self.sharedNTPClock finishAssociations] is redundant upon 
//     receiving UIApplicationDidEnterBackgroundNotification.
//
- (void) stop
{
  self.protocolActive = NO;
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (self.sharedNTPClock) {
    [self.sharedNTPClock finishAssociations];
  }
}


//--------------------- -o-
// date
//
// If [self date] is bad, fallback to previously established difference.
// NB  previousDifference may also be undefined (DBL_MAX).
//
- (NSDate *) date
{
  if (self.synchronizationSuccess) {
    return [NSDate networkDate];

  } else if (self.previousDifference != DBL_MAX) {
    return [[NSDate date] dateByAddingTimeInterval:-self.previousDifference];

  } else {
    return nil;
  }
}


//--------------------- -o-
// dateWithOffset:
//
// If [self date] is bad, fallback to previously established difference.
// NB  previousDifference may also be undefined (DBL_MAX).
//
- (NSDate *) dateWithOffset:(NSTimeInterval)offset
{
  if (self.synchronizationSuccess) {
    return [NSDate networkDateWithOffset:offset];

  } else if (self.previousDifference != DBL_MAX) {
    return [[NSDate date] dateByAddingTimeInterval:-(self.previousDifference + offset)];

  } else {
    return nil;
  }
}


//--------------------- -o-
// differenceFromSystemDate
//
// RETURN  positive value  when NTP date comes AFTER system date,
//         negative value  otherwise NTP date comes BEFORE system date.
// 
- (NSTimeInterval) differenceFromSystemDate
{
  NSTimeInterval  difference = [[self date] timeIntervalSinceDate:[NSDate date]];
  return ([self date]) ? difference : DBL_MAX;
}


//--------------------- -o-
// differenceFromSystemDateWithOffset:
//
// RETURN  positive value  when (NTP date + offset) comes AFTER system date,
//         negative value  otherwise (NTP date + offset) comes BEFORE system date.
//
- (NSTimeInterval) differenceFromSystemDateWithOffset:(NSTimeInterval)offset
{
  NSTimeInterval  difference = [[self dateWithOffset:offset] timeIntervalSinceDate:[NSDate date]];
  return ([self date]) ? difference : DBL_MAX;
}

@end

