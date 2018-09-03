//
// UIImage+MOSZed.m
//
//
// CLASS DEPENDENCIES: NSString+MOSLog
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#import "UIImage+MOSZed.h"



//------------------------------------------------ -o--
@implementation UIImage (MOSZed)

//------------------ -o-
+ (UIImage *) imageFromURL: (NSURL *)url
{
  NSData   *imageData;
  UIImage  *image;
  NSError  *error;

  imageData = [NSData dataWithContentsOfURL:  url
				    options:  NSDataReadingUncached
				      error: &error ];
  if (!imageData) { 
    MOS_LOG_NSERROR(error);
    MOS_LOG_ERROR(@"FAILED to read data from URL.  (%@)", url);
    return nil;
  }

  image = [UIImage imageWithData:imageData];

  if (!image) { 
    MOS_LOG_ERROR(@"FAILED to read image from data.");
    return nil;
  }


  return image;
}


@end

