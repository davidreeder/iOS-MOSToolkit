//
// UIImage+MOSZed.h
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_UIImage_MOSZed  0.2


#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>



//------------------------------------------------ -o--
@interface UIImage (MOSZed)

  + (UIImage *) imageFromURL: (NSURL *)url;

@end

