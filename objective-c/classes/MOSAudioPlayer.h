//
// MOSAudioPlayer.h
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_AUDIOPLAYER  0.1


#import <AVFoundation/AVFoundation.h>

#import "MOSMobileSound.h"



//-------------------------------------------------- -o--
#define MOS_AUDIOPLAYER_FADE_SEGMENT_DURATION  0.05   // XXX  Excessive?

#define MOS_AUDIOPLAYER_MAXVOLUME  1.0




//-------------------------------------------------- -o--
@interface MOSAudioPlayer : AVAudioPlayer
  
  @property  (nonatomic, readonly, getter=isInterrupted)  BOOL  interrupted;

  @property  (nonatomic)  BOOL  stopRestartsCurrentTimeToZero;

  @property  (nonatomic, readonly, getter=isFadeActive)  BOOL  fadeActive;

  @property  (nonatomic)  float  targetVolume;


  //
  - (id) initWithFile:(NSString *)filename;

  - (void) play;
  - (void) stop;

  - (void) fadeWithDuration: (NSTimeInterval)fadeDurationInSeconds
             toTargetVolume: (float)targetVolume
            completionBlock: (void (^)(void))completionBlock;

  - (void) dump;


  //
  + (void) crossfadeFromSourceSound: (MOSAudioPlayer *)sourceSound
                      toTargetSound: (MOSAudioPlayer *)targetSound
                     atTargetVolume: (float)targetVolume
                       withDuration: (NSTimeInterval)duration;

@end

