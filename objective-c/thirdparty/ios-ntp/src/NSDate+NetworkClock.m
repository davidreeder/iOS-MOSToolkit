

#import "NSDate+NetworkClock.h"

@implementation NSDate (NetworkClock)

- (NSTimeInterval) timeIntervalSinceNetworkDate {
  return [self timeIntervalSinceDate:[NSDate networkDate]];
}

+ (NSTimeInterval) timeIntervalSinceNetworkDate {
  return [[self date] timeIntervalSinceNetworkDate];
}


+ (NSDate *) networkDate {
  return [[NetworkClock sharedNetworkClock] networkTime];
}

+ (NSDate *) networkDateWithOffset:(NSTimeInterval)offset {
  return [[NetworkClock sharedNetworkClock] networkTimeWithOffset:offset];
}


+ (NSDate *) threadsafeNetworkDate {
  NetworkClock *sharedClock = [NetworkClock sharedNetworkClock];
  @synchronized(sharedClock) {
    return [sharedClock networkTime];
  }
}


@end