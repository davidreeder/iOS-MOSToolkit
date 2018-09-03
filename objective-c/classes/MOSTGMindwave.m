//
// MOSTGMindwave.m
//
// Collect and smooth available data from Mindwave.
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#import "MOSTGMindwave.h"



//------------------------------------------------------------ -o--
#define MOS_TG_REFRESHRATE  0.1
//#define MOS_TG_REFRESHRATE  5.0
    // XXX -- Refresh rate appears fixed at approximately once per second. 

#define MOS_TG_POORSIGNAL_BEST  200

#define MOS_TG_HYSTERISIS_ARRAYSIZE  4

#define MOS_TG_BLINKSTRENGTH_DECAY  0.10



// Fields returned in Mindwave data dictionary.
// All values represent integers, unless otherwise noted.
//
// NB  Not receiving...  rawValue (short), respiration (float), heartRate, heartRateAverage, heartRateAcceleration.
//     (as of Tue Nov 11 21:05:18 EST 2014-2015)
//
#define MOS_TG_DATA_poorSignal     @"poorSignal"  // range: [0, 200]
#define MOS_TG_DATA_rawCount       @"rawCount"    // range: [0, 512]

#define MOS_TG_DATA_blinkStrength  @"blinkStrength"

#define MOS_TG_DATA_attention      @"eSenseAttention"
#define MOS_TG_DATA_meditation     @"eSenseMeditation"

#define MOS_TG_DATA_delta          @"eegDelta"
#define MOS_TG_DATA_theta          @"eegTheta"

#define MOS_TG_DATA_alphaHigh      @"eegHighAlpha"
#define MOS_TG_DATA_alphaLow       @"eegLowAlpha"
#define MOS_TG_DATA_betaHigh       @"eegHighBeta"
#define MOS_TG_DATA_betaLow        @"eegLowBeta"
#define MOS_TG_DATA_gammaHigh      @"eegHighGamma"
#define MOS_TG_DATA_gammaLow       @"eegLowGamma"




//------------------------------------------------------------ -o--
@interface MOSTGMindwave() <TGAccessoryDelegate>

  //
  @property (strong, nonatomic)  TGAccessoryManager  *mindwave;


  @property (strong, nonatomic)  NSMutableDictionary  *dataRecent;
  @property (strong, nonatomic)  NSMutableDictionary  *dataRangeLow;
  @property (strong, nonatomic)  NSMutableDictionary  *dataRangeHigh;
      // Three dictionaries of unsigned integers.

  @property (strong, nonatomic)  NSMutableDictionary  *dataNormalized;
      // Dictionary of percentages.
  @property (strong, nonatomic)  NSMutableDictionary  *dataNormalizedHysteresis;
      // Dictionary of arrays of percentages.

  @property (nonatomic)  NSInteger  captureIteration;
  @property (nonatomic)  float      mediatedBlinkStrength;


  //
  - (instancetype) init   NS_DESIGNATED_INITIALIZER;

  - (void) captureData: (NSDictionary *)incomingData;
  - (NSArray *) listOfFieldsWithInterestingRanges;
  - (void) normalizeRangeForKey: (NSString *)key;
  - (NSMutableDictionary *) decayBlinkStrength: (NSMutableDictionary *)incomingData;
  - (float) normalizedValue: (NSString *)attribute;

@end




//------------------------------------------------------------ -o--
@implementation MOSTGMindwave

#pragma mark - Constructors.

//--------------------- -o-
- (instancetype) init                             // NS_DESIGNATED_INITIALIZER
{
  if (!(self = [super init])) {
    MOS_LOG_ERROR(@"FAILED to initialize self.");
    return nil;
  }

  self.captureIteration = 0;

  return self;
}


//--------------------- -o-
+ (MOSTGMindwave *) singleton  
{
  static MOSTGMindwave     *singleton = nil;
  static dispatch_once_t    onceToken;

  dispatch_once(&onceToken, ^{
    singleton = [[MOSTGMindwave alloc] init];
  });

  return singleton;
}




//------------------------------------------------------------ -o--
#pragma mark - Getters/setters and matching delegate methods.

//--------------------- -o-
- (TGAccessoryManager *) mindwave
{
  if (! _mindwave) {
    _mindwave = [TGAccessoryManager sharedTGAccessoryManager];
  }

  return _mindwave;
}


//--------------------- -o-
- (NSMutableDictionary *) dataRecent;
{
  if (! _dataRecent) {
    _dataRecent = [[NSMutableDictionary alloc] init];
  }
  return _dataRecent;
}

//--------------------- -o-
- (NSMutableDictionary *) dataRangeLow;
{
  if (! _dataRangeLow) {
    _dataRangeLow = [[NSMutableDictionary alloc] init];
  }
  return _dataRangeLow;
}

//--------------------- -o-
- (NSMutableDictionary *) dataRangeHigh;
{
  if (! _dataRangeHigh) {
    _dataRangeHigh = [[NSMutableDictionary alloc] init];
  }
  return _dataRangeHigh;
}
 
//--------------------- -o-
- (NSMutableDictionary *) dataNormalized;
{
  if (! _dataNormalized) {
    _dataNormalized = [[NSMutableDictionary alloc] init];
  }
  return _dataNormalized;
}

//--------------------- -o-
- (NSMutableDictionary *) dataNormalizedHysteresis;
{
  if (! _dataNormalizedHysteresis) {
    _dataNormalizedHysteresis = [[NSMutableDictionary alloc] init];
  }
  return _dataNormalizedHysteresis;
}
 

//--------------------- -o-
- (NSUInteger) signalStrength
{
  if (! [[self.mindwave accessory] isConnected])  { return 0; }

  NSUInteger  poorSignal = [[self.dataRecent valueForKey:MOS_TG_DATA_poorSignal] unsignedIntegerValue];
  return (MOS_TG_POORSIGNAL_BEST - poorSignal) / 2;
}


//--------------------- -o-
- (float) attention    { return [self normalizedValue:MOS_TG_DATA_attention]; }
- (float) meditation   { return [self normalizedValue:MOS_TG_DATA_meditation]; }

- (float) blinkStrength   { return [self normalizedValue:MOS_TG_DATA_blinkStrength]; }


//--------------------- -o-
- (float) delta   { return [self normalizedValue:MOS_TG_DATA_delta]; }
- (float) theta   { return [self normalizedValue:MOS_TG_DATA_theta]; }


//--------------------- -o-
- (float) alphaHigh  { return [self normalizedValue:MOS_TG_DATA_alphaHigh]; }
- (float) alphaLow   { return [self normalizedValue:MOS_TG_DATA_alphaLow]; }

- (float) betaHigh   { return [self normalizedValue:MOS_TG_DATA_betaHigh]; }
- (float) betaLow    { return [self normalizedValue:MOS_TG_DATA_betaLow]; }

- (float) gammaHigh  { return [self normalizedValue:MOS_TG_DATA_gammaHigh]; }
- (float) gammaLow   { return [self normalizedValue:MOS_TG_DATA_gammaLow]; }





//------------------------------------------------------------ -o--
#pragma mark - Public methods and matching delegate methods.

//--------------------- -o-
// -start
//
// XXX  setRawEnabled:YES will hang system...  Problem with dictionary processing?
//
// TBD  Explore raw.
// TBD  Why refreshrate not configurable in practice?
//
- (void) start
{
//MOS_LOG_MARK();

  if ([self.mindwave accessory]) {
    MOS_LOG_WARNING(@"%@ is already started...", [[self.mindwave accessory] name]);
    return;
  }
  
  [self.mindwave setupManagerWithInterval:MOS_TG_REFRESHRATE forAccessoryType:TGAccessoryTypeDongle];
  
  [self.mindwave setDelegate:self];
  [self.mindwave setRawEnabled:NO];

  [self.mindwave startStream];
}



//--------------------- -o-
- (void) stop
{
//MOS_LOG_MARK();
  [[TGAccessoryManager sharedTGAccessoryManager] teardownManager];

  [self clearDataAll];  // XXX
}




//--------------------- -o-
- (void) clearDataAll
{
  self.dataRecent = nil;
  [self clearDataHighsAndLows];
}



//--------------------- -o-
- (void) clearDataHighsAndLows
{
  self.dataRangeLow = nil;
  self.dataRangeHigh = nil;
  self.dataNormalized = nil;
  self.dataNormalizedHysteresis = nil;
}




//--------------------- -o-
- (NSString *) description
{
  EAAccessory  *device = [self.mindwave accessory];

  return [NSString stringWithFormat:@"%@ by %@.  Model# %@ (%@/%@).  %@ %@",
                                        device.name, device.manufacturer,
                                        device.modelNumber, device.firmwareRevision, device.hardwareRevision,
                                        (device.isConnected) ? @"Connection ID" : @"Not connected.",
                                        (device.isConnected) ? [NSString stringWithFormat:@"%lu.", (unsigned long)device.connectionID] : @"" ];
}



//--------------------- -o-
# define R(x)  (unsigned long)[[self.dataRecent    objectForKey: MOS_TG_DATA_ ## x] unsignedIntegerValue]
# define L(x)  (unsigned long)[[self.dataRangeLow  objectForKey: MOS_TG_DATA_ ## x] unsignedIntegerValue]
# define H(x)  (unsigned long)[[self.dataRangeHigh objectForKey: MOS_TG_DATA_ ## x] unsignedIntegerValue]

- (NSString *) status:(NSString *)title
{
  EAAccessory  *device  = [self.mindwave accessory];

  NSString     *header      = @"";
  NSString     *footer      = @"";
  NSString     *everything  = @"";

  //
  everything = [NSString stringWithFormat:
      @"\n"
       "attention   %lu  (%lu, %lu)\n"
       "meditation  %lu  (%lu, %lu)\n"

       "\n"
       "blinkStrength  %lu  (%lu, %lu)\n"

       "\n"
       "delta  %lu  (%lu, %lu)\n"
       "theta  %lu  (%lu, %lu)\n"

       "\n"
       "alpha\n"
       "  High  %lu  (%lu, %lu)\n"
       "  Low   %lu  (%lu, %lu) \n"

       "beta\n"
       "  High  %lu  (%lu, %lu)\n"
       "  Low   %lu  (%lu, %lu) \n"

       "gamma\n"
       "  High  %lu  (%lu, %lu)\n"
       "  Low   %lu  (%lu, %lu) \n",

         R(attention), L(attention), H(attention),
         R(meditation), L(meditation), H(meditation),

         R(blinkStrength), L(blinkStrength), H(blinkStrength),

         R(delta), L(delta), H(delta),
         R(theta), L(theta), H(theta),

         R(alphaHigh), L(alphaHigh), H(alphaHigh),
           R(alphaLow), L(alphaLow), H(alphaLow),

         R(betaHigh), L(betaHigh), H(betaHigh),
           R(betaLow), L(betaLow), H(betaLow),

         R(gammaHigh), L(gammaHigh), H(gammaHigh),
           R(gammaLow), L(gammaLow), H(gammaLow)
  ];

  //
  header = [NSString stringWithFormat:
               @"%@ by %@\n"
                "\tmodel#  %@\n"
                "\thw/sw#  %@ / %@\n"

                "\trawCount    %lu\n"
                "\tpoorSignal  %lu\n"

                "\t%@ %@\n"
                "\titeration     %ld\n",

                     device.name, device.manufacturer,
                     device.modelNumber, 
                     device.firmwareRevision, device.hardwareRevision,

                     R(rawCount), R(poorSignal), 

                     (device.isConnected) ? @"connectionID#" : @"Not connected.",
                       (device.isConnected) ? [NSString stringWithFormat:@"%lu", (unsigned long)device.connectionID] : @"" ,
                     (long)self.captureIteration

           ];

  //
  if (title) {
    header = [title stringByAppendingString:[NSString stringWithFormat:@"\n%@", header]];
  }

  return [NSString stringWithFormat:@"\n%@%@%@", header, everything, footer];
}


- (NSString *) status  // ALIAS
{
 return [self status:nil];
}




//--------------------- -o-
- (void) dump: (NSString *)title
{
  //MOS_SEP();

  //MOS_DUMPONN(self.dataRecent);
  //MOS_DUMPONN(self.dataRangeLow);
  //MOS_DUMPONN(self.dataRangeHigh);

  //MOS_DUMPONN(self.dataNormalized);
  //MOS_DUMPONN(self.dataNormalizedHysteresis);

  //MOS_DUMPONN([self.dataNormalized objectForKey:MOS_TG_DATA_blinkStrength]);
  //MOS_DUMPONN([self.dataNormalizedHysteresis objectForKey:MOS_TG_DATA_blinkStrength]);

  //MOS_DUMPO(@(self.signalStrength));

  //MOS_DUMPO([self status:title]);
}


- (void) dump  // ALIAS
{
  [self dump:nil];
}





//------------------------------------------------------------ -o--
#pragma mark - Private methods.

//--------------------- -o-
// captureData: 
//
// ASSUMES  Device never delivers spurious, fluttery data.
//
- (void) captureData: (NSDictionary *)incomingData
{
  self.captureIteration += 1;
  if (! incomingData)  { return; }

  NSMutableDictionary  *mutableIncomingData = [incomingData mutableCopy];


  mutableIncomingData = [self decayBlinkStrength:mutableIncomingData];

  [self.dataRecent addEntriesFromDictionary:mutableIncomingData];


  for (NSString *key in [mutableIncomingData allKeys]) 
  {
    if (! [key isEqualToStringInArray:[self listOfFieldsWithInterestingRanges]])  { continue; }

    //
    id  incomingValue = [self.dataRecent objectForKey:key];


    // Capture first non-zero value; capture lows and highs.
    //
    if (! [self.dataRangeLow objectForKey:key]) 
    {
      if ([incomingValue unsignedIntegerValue] == 0)  { continue; }

      [self.dataRangeLow setObject:incomingValue forKey:key];
      [self.dataRangeHigh setObject:incomingValue forKey:key];

    } else if ([incomingValue unsignedIntegerValue] < [[self.dataRangeLow objectForKey:key] unsignedIntegerValue]) {
      [self.dataRangeLow setObject:incomingValue forKey:key];
      
    } else if ([incomingValue unsignedIntegerValue] > [[self.dataRangeHigh objectForKey:key] unsignedIntegerValue]) {
      [self.dataRangeHigh setObject:incomingValue forKey:key];
    }

    //
    [self normalizeRangeForKey:key];
  }
}



//--------------------- -o-
- (NSArray *) listOfFieldsWithInterestingRanges
{
  static NSArray  *listOfFields = nil;
  
  if (! listOfFields) {
    listOfFields = [NSArray arrayWithObjects:
                              MOS_TG_DATA_blinkStrength,

                              MOS_TG_DATA_attention,
                              MOS_TG_DATA_meditation,
                              MOS_TG_DATA_delta,
                              MOS_TG_DATA_theta,

                              MOS_TG_DATA_alphaHigh, MOS_TG_DATA_alphaLow,
                              MOS_TG_DATA_betaHigh,  MOS_TG_DATA_betaLow,
                              MOS_TG_DATA_gammaHigh, MOS_TG_DATA_gammaLow,

                              nil ];
  }

  return listOfFields;
}



//--------------------- -o-
// normalizeRangeForKey:
//
// ASSUME  If a key/value pair appears in one of data{Range*,Recent}, it appears in ALL of them.
//
- (void) normalizeRangeForKey: (NSString *)key
{
  float  high    = (float) [[self.dataRangeHigh objectForKey:key] unsignedIntegerValue];
  float  low     = (float) [[self.dataRangeLow objectForKey:key] unsignedIntegerValue];
  float  recent  = (float) [[self.dataRecent objectForKey:key] unsignedIntegerValue];

  float          percentage;
  float          adjustedNormalized;
  __block float  sum = 0;

  NSMutableArray  *history;


  //
  if ((high-low) <= 0) {
    percentage = 0;
  } else {
    percentage = (recent - low) / (high - low);
  }


  //
  history = (NSMutableArray *) [self.dataNormalizedHysteresis objectForKey:key];
  if (!history) {
    history = [[NSMutableArray alloc] init];
  }

  [history insertObject:@(percentage) atIndex:[history count]];
  if ([history count] > MOS_TG_HYSTERISIS_ARRAYSIZE) {
    [history removeObjectAtIndex:0];
  }
  [self.dataNormalizedHysteresis setObject:history forKey:key];


  //
  [history enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
               {
                 sum += [obj floatValue];
               } ];

  adjustedNormalized = sum / [history count];

  [self.dataNormalized setObject:@(adjustedNormalized) forKey:key];
}


//--------------------- -o-
- (NSMutableDictionary *) decayBlinkStrength: (NSMutableDictionary *)incomingData
{
//MOS_LOG_MARK();
  id  blinkStrengthObj = [self.dataRecent objectForKey:MOS_TG_DATA_blinkStrength];
  

  // Ignore cases where Blink Strength has not yet been recorded, or HAS BEEN UPDATED in the last cycle.
  //   (Thus, restarting the history...)
  // When a new value arrives, clear the history of previous values as they have been artificially generated via this method.
  //
  if (! blinkStrengthObj)  { return incomingData; }

  if ([incomingData objectForKey:MOS_TG_DATA_blinkStrength])
  { 
    [self.dataNormalizedHysteresis removeObjectForKey:MOS_TG_DATA_blinkStrength];
    return incomingData;
  }


  // Otherwise, decay the recent, existing value of Blink Strength and inject it into incoming data, thus slowly lowering the rolling average.
  //
  float  blinkStrength = (float) [(NSNumber *) blinkStrengthObj unsignedIntegerValue];

  blinkStrength *= (1.0 - MOS_TG_BLINKSTRENGTH_DECAY);

  NSUInteger  blinkStrengthValue = (NSUInteger) round(blinkStrength);

  [incomingData setObject:@(blinkStrengthValue) forKey:MOS_TG_DATA_blinkStrength];

  return incomingData;
}


//--------------------- -o-
- (float) normalizedValue: (NSString *)attribute
{
  return [[self.dataNormalized objectForKey:attribute] floatValue];
}




//------------------------------------------------------------ -o--
#pragma mark - TGAccessoryDelegate.

//--------------------- -o-
- (void)accessoryDidConnect: (EAAccessory *)accessory
{
  if (! accessory) {
    MOS_LOG_WARNING(@"ACCESSORY is undefined.");
    return;
  }

  MOS_LOG_INFO(@"ACCESSORY is ONLINE.  :: %@", [self description]);
}


//--------------------- -o-
- (void)accessoryDidDisconnect 
{
  MOS_LOG_INFO(@"ACCESSORY is OFFLINE.");
}


//--------------------- -o-
- (void) dataReceived: (NSDictionary *)data
{
  [self captureData:data];

  //[self dump];  // DEBUG
}

@end // @implementation MOSTGMindwave

