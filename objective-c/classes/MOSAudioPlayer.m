//
// MOSAudioPlayer.m
//
// Subclass AVAudioPlayer--
//   . simplify initialzation 
//   . handle notifications internally
//   . prepare sound files before playback
//   . (optionally) reset currentTime upon stopping
//   . label dump of class properties
//
//
// TBD  How to engage hardware-assisted codecs?
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#import "MOSAudioPlayer.h"



//-------------------------------------------------- -o--
@interface MOSAudioPlayer() <AVAudioPlayerDelegate>

  @property  (strong, nonatomic)  NSString  *filename;


  // Fade parameters.
  //
  @property  (nonatomic, readwrite, getter=isFadeActive)  BOOL  fadeActive;
  @property  (nonatomic, strong)                          id    fadeActiveMutex;

  @property  (nonatomic)  BOOL            fadeIncreasesVolume;
  @property  (nonatomic)  NSTimeInterval  fadeSegmentIncrement;
  @property  (nonatomic)  float           fadeTargetVolume;

  @property  (nonatomic, copy)  void  (^fadeCompletionBlock)(void);


  //
  - (void) executeFade;

@end




//-------------------------------------------------- -o--
@implementation MOSAudioPlayer

#pragma mark - Lifecycle.

//--------------- -o-
- (id) initWithFile:(NSString *)filename
{
  NSData   *fileData;
  NSError  *error = nil;


  //
  if (!filename) { 
    MOS_LOG_ERROR(@"filename is nil.");
    return nil; 
  }

  fileData = [NSData dataWithContentsOfFile:filename options:0 error:&error];

  if (!fileData) {
    MOS_LOG_ERROR(@"FAILED to open file \"%@\".  (%@)", [filename lastPathComponent], error);
    return nil;
  }



  //
  self = [super initWithData:fileData error:&error ]; 

  if (!self) {
    MOS_LOG_ERROR(@"FAILED to initialize AVAudioPlayer for \"%@\".  (%@)", [filename lastPathComponent], error);
    return nil;
  }

  fileData = nil;

  self.filename = filename;
  self.delegate = self;

  self.stopRestartsCurrentTimeToZero = YES;
  self.fadeActive = NO;

  self.targetVolume = MOS_AUDIOPLAYER_MAXVOLUME;


  //
  [self prepareToPlay];

  return self;

}  // initWithFile:




//-------------------------------------------------- -o--
#pragma mark - AVAudioPlayer delegate.

//--------------- -o-
- (void)audioPlayerDidFinishPlaying: (AVAudioPlayer *)player 
                       successfully: (BOOL)successFlag
{
  if (! successFlag) {
    MOS_LOG_ERROR(@"FINISHED PLAYING because audio decoding FAILED.  (filename=%@)", [self.filename lastPathComponent]);
  }
}


//--------------- -o-
- (void)audioPlayerDecodeErrorDidOccur: (AVAudioPlayer *)player 
                                 error: (NSError *)error
{
  MOS_LOG_ERROR(@"DECODE ERROR for filename \"%@\".  (error=%@)", [self.filename lastPathComponent], error);
  [self dump];
}




//-------------------------------------------------- -o--
#pragma mark - Instance methods (overloaded).

//--------------- -o-
// play 
//
// NB  Appears to ignore multiple invocations after the first.
//
- (void) play 
{
  [super play];
}


//--------------- -o-
- (void) stop 
{
  [super stop];

  if (self.stopRestartsCurrentTimeToZero) {
    [self setCurrentTime:0];
  }
}


//--------------- -o-
// fadeWithDuration:toTargetVolume:completionBlock: 
//
// Linear fade.
//
// TBD  Fades with curves.  Precomputing fade increments?
//
- (void) fadeWithDuration: (NSTimeInterval)fadeDurationInSeconds
           toTargetVolume: (float)targetVolume
          completionBlock: (void (^)(void))completionBlock
{
  // Sanity checks.
  //
  if (fadeDurationInSeconds < MOS_AUDIOPLAYER_FADE_SEGMENT_DURATION) {
    MOS_LOG_ERROR(@"Duration must be >= MOS_AUDIOPLAYER_FADE_SEGMENT_DURATION (%f).  (%@)", 
                    MOS_AUDIOPLAYER_FADE_SEGMENT_DURATION, [self.filename lastPathComponent]);
    return;
  }

  if (targetVolume < 0.0) {
    MOS_LOG_ERROR(@"Target volume must be greater than zero.  (%@)", [self.filename lastPathComponent]);
    return;
  }

  @synchronized(self.fadeActiveMutex)
  {
    if (self.isFadeActive) {
      MOS_LOG_WARNING(@"Fade is already active.  (%@)", [self.filename lastPathComponent]);
      return;
    }

    self.fadeActive = YES;
  }

  self.fadeCompletionBlock = completionBlock;



  // Compute fade parameters.
  //
  float  currentVolume        = self.volume;
  float  rangeToTargetVolume  = 0.0;

  NSUInteger  numberOfFadeSegments = 0;

  self.fadeTargetVolume      = targetVolume;
  self.fadeIncreasesVolume   = YES;
  self.fadeSegmentIncrement  = 0.0;


  if (currentVolume > self.fadeTargetVolume) {
    rangeToTargetVolume = currentVolume - self.fadeTargetVolume;
    self.fadeIncreasesVolume = NO;
  } else {
    rangeToTargetVolume = self.fadeTargetVolume - currentVolume;
  }

  numberOfFadeSegments = floor(fadeDurationInSeconds / MOS_AUDIOPLAYER_FADE_SEGMENT_DURATION);

  self.fadeSegmentIncrement = rangeToTargetVolume / (float)numberOfFadeSegments;
//MOS_DUMPONL(@(currentVolume), @(self.fadeTargetVolume), @(self.fadeIncreasesVolume), @(rangeToTargetVolume), @(fadeDurationInSeconds), @(numberOfFadeSegments), @(self.fadeSegmentIncrement));



  // Execute fade in background.
  //
  dispatch_queue_t  serialQueue;
  MOS_CREATE_SERIAL_QUEUE(serialQueue, [@"FADE " suffixWith:[self.filename lastPathComponent]] );

  __weak MOSAudioPlayer  *weakSelf = self;

  dispatch_async(serialQueue, ^{
    [weakSelf executeFade];
  });

}  // fadeWithDuration:toTargetVolume:completionBlock: 



//--------------- -o-
- (void) dump
{
  [super dump:self.filename];
}




//-------------------------------------------------- -o--
#pragma mark - Private methods.

//--------------- -o-
// executeFade
//
// Execute linear fade.
// Fade stops once target volume is achieved, or if sound is stopped prematurely.
// Sounds stopped amidst a fade are immediately set to the target volume.
//
// Begin playing sound before fade if it was stopped.
// BEWARE of (re)starting sounds at high volumes!
//
// 
// NB  Do not call directly, run this via fadeWithDuration:toTargetVolume:completionBlock:
//       which also manages setup of global instance variables and also executes in a separate thread.
//
// NB  Main while-loop executes until fadeTargetVolume is achieved.
//     Calling environment computes fadeSegmentIncrement such that this occurs within requested duration.
//     However, self.volume cannot be protected from external changes becaus it must also be changed here.
//       Setting it "high" will preempt the fade.  Setting it "low" will extend the fade.
//
// NB  Without environment changes, fades will completely roughly near the duration requested.
//     This is because the interpolated wait segments between volume changes add up to the total duration requested, 
//       not including the time spent to execute changes.  Thus ending a bit past the time requested.
//     Or, volume changes at each stage may meet the goal by the second to last segment.  
//       Thus ending a bit prior to the time requested.
//
- (void) executeFade
{
  BOOL   isDone = NO;
  float  currentVolume;


  //
  if (! self.isPlaying) {
    [self play];
    [NSThread sleepForTimeInterval:0.025];  // XXX
  }


  //
  while (! isDone) 
  {
    if (! self.isPlaying) 
                        // TBDXXX  Does this properly respond to pauses due to interruptions?
    {
      self.volume = self.fadeTargetVolume;
      isDone = YES;
      break;
    }


    //
    currentVolume = self.volume;

    if (self.fadeIncreasesVolume) 
    {
      currentVolume += self.fadeSegmentIncrement;

      if (currentVolume >= self.fadeTargetVolume) {
        currentVolume = self.fadeTargetVolume;
        isDone = YES;
      }

    } else {
      currentVolume -= self.fadeSegmentIncrement;

      if (currentVolume <= self.fadeTargetVolume) {
        currentVolume = self.fadeTargetVolume;
        isDone = YES;
      }
    }

    self.volume = currentVolume;


    //
    if (! isDone) {
      [NSThread sleepForTimeInterval:MOS_AUDIOPLAYER_FADE_SEGMENT_DURATION];
    }

  }  // endwhile


  //
  @synchronized(self.fadeActiveMutex) {
    self.fadeActive = NO;
  }

  if (self.fadeCompletionBlock)  { self.fadeCompletionBlock(); }
  self.fadeCompletionBlock = nil;

}  // executeFade




//-------------------------------------------------- -o--
#pragma mark - Class methods.

//--------------------------- -o-
// +crossfadeFromSourceSound:toTargetSound:atTargetVolume:withDuration: 
//
// NB  Fade-out source sound to zero, then stop.
//
+ (void) crossfadeFromSourceSound: (MOSAudioPlayer *)sourceSound
                    toTargetSound: (MOSAudioPlayer *)targetSound
                   atTargetVolume: (float)targetVolume
                     withDuration: (NSTimeInterval)duration
{
  [targetSound  fadeWithDuration: duration
                  toTargetVolume: targetVolume
                 completionBlock: nil ];

  [sourceSound  fadeWithDuration: duration
                  toTargetVolume: 0.0
                 completionBlock: ^{ [sourceSound stop]; }
   ];
}

@end

