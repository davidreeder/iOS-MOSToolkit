/*╔══════════════════════════════════════════════════════════════════════════════════════════════════╗
  ║ NetworkClock.h                                                                                   ║
  ║                                                                                                  ║
  ║ Created by Gavin Eadie on Oct17/10                                                               ║
  ║ Copyright 2010 Ramsay Consulting. All rights reserved.                                           ║
  ╚══════════════════════════════════════════════════════════════════════════════════════════════════╝*/


#undef IOS_NTP_LOGGING
#define IOS_NTP_LOGGING  // DEBUG -- Chatty feedback with time servers.

#import "ios-ntp-prefix.h"

#import "NetAssociation.h"
#import "NetworkClock.h"
#import "NSDate+NetworkClock.h"

