//
// MOSTGMindwave.h
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_TGMindwave  0.1


#import "MOSMobileSound.h"

#import "TGAccessoryManager.h"



//------------------------------------------------------------ -o--
@interface MOSTGMindwave : NSObject

  //
  @property (nonatomic, readonly)  NSUInteger  signalStrength;

  @property (nonatomic, readonly)  float  attention;
  @property (nonatomic, readonly)  float  meditation;
  @property (nonatomic, readonly)  float  blinkStrength;

  @property (nonatomic, readonly)  float  delta;
  @property (nonatomic, readonly)  float  theta;
  @property (nonatomic, readonly)  float  alphaHigh;
  @property (nonatomic, readonly)  float  alphaLow;
  @property (nonatomic, readonly)  float  betaHigh;
  @property (nonatomic, readonly)  float  betaLow;
  @property (nonatomic, readonly)  float  gammaHigh;
  @property (nonatomic, readonly)  float  gammaLow;


  
  //
  + (MOSTGMindwave *) singleton;


  //
  - (void) start;
  - (void) stop;


  - (void) clearDataAll;
  - (void) clearDataHighsAndLows;

  - (NSString *) status: (NSString *)title;
  - (NSString *) status;

  - (void) dump: (NSString *)title;
  - (void) dump;


  // TGAccessoryDelegate.
  //
  - (void) dataReceived: (NSDictionary *)data;

@end

