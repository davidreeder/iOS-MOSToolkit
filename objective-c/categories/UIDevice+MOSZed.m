//
//  UIDevice+MOSZed.m
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#import "UIDevice+MOSZed.h"


//---------------------------------------------------------- -o--
@implementation UIDevice (MOSZed)

//---------------------------- -o-
// Cf. https://github.com/dennisweissmann/Basics/blob/master/Device.swift
//
+ (NSString *)modelDetail
{
  struct utsname systemInfo;
  uname(&systemInfo);

  NSString  *systemInfoMachine = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

  NSDictionary  *modelDetailDictionary = @{
                                            @"iPod5,1"    : @"iPod Touch 5",
                                            @"iPod7,1"    : @"iPod Touch 6",

                                            @"iPhone3,1"  : @"iPhone 4",
                                            @"iPhone3,2"  : @"iPhone 4",
                                            @"iPhone3,3"  : @"iPhone 4",

                                            @"iPhone4,1"  : @"iPhone 4s",

                                            @"iPhone5,1"  : @"iPhone 5",
                                            @"iPhone5,2"  : @"iPhone 5",

                                            @"iPhone5,3"  : @"iPhone 5c",
                                            @"iPhone5,4"  : @"iPhone 5c",

                                            @"iPhone6,1"  : @"iPhone 5s",
                                            @"iPhone6,2"  : @"iPhone 5s",

                                            @"iPhone7,2"  : @"iPhone 6",
                                            @"iPhone7,1"  : @"iPhone 6 Plus",
                                            @"iPhone8,1"  : @"iPhone 6s",
                                            @"iPhone8,2"  : @"iPhone 6s Plus",

                                            @"iPad2,1"    : @"iPad 2",
                                            @"iPad2,2"    : @"iPad 2",
                                            @"iPad2,3"    : @"iPad 2",
                                            @"iPad2,4"    : @"iPad 2",

                                            @"iPad3,1"    : @"iPad 3",
                                            @"iPad3,2"    : @"iPad 3",
                                            @"iPad3,3"    : @"iPad 3",

                                            @"iPad3,4"    : @"iPad 4",
                                            @"iPad3,5"    : @"iPad 4",
                                            @"iPad3,6"    : @"iPad 4",

                                            @"iPad4,1"    : @"iPad Air",
                                            @"iPad4,2"    : @"iPad Air",
                                            @"iPad4,3"    : @"iPad Air",

                                            @"iPad5,1"    : @"iPad Air 2",
                                            @"iPad5,3"    : @"iPad Air 2",
                                            @"iPad5,4"    : @"iPad Air 2",

                                            @"iPad2,5"    : @"iPad Mini",
                                            @"iPad2,6"    : @"iPad Mini",
                                            @"iPad2,7"    : @"iPad Mini",

                                            @"iPad4,4"    : @"iPad Mini 2",
                                            @"iPad4,5"    : @"iPad Mini 2",
                                            @"iPad4,6"    : @"iPad Mini 2",

                                            @"iPad4,7"    : @"iPad Mini 3",
                                            @"iPad4,8"    : @"iPad Mini 3",
                                            @"iPad4,9"    : @"iPad Mini 3",

                                            @"iPad5,1"    : @"iPad Mini 4",
                                            @"iPad5,2"    : @"iPad Mini 4",

                                            @"i386"       : @"Simulator",
                                            @"x86_64"     : @"Simulator",
                                          };

  NSString  *modelDetailName = [modelDetailDictionary objectForKey:systemInfoMachine];

  if (! modelDetailName)  { modelDetailName = systemInfoMachine; }


  return  modelDetailName;
}


@end

