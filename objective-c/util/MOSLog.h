//
// MOSLog.h
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

#define MOS_VERSION_Log  0.1



//------------------------------------------------------------ -o--
// Simple macros for logging location and severity.
//
#define MOS_CODE_LOCATION  [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__]

#define MOS_LOG_MARK()  	NSLog(@" MARK  %@", 		MOS_CODE_LOCATION)
#define MOS_LOG_MARKM(...)  	NSLog(@" MARK  %@ -- %@", 	MOS_CODE_LOCATION, [NSString stringWithFormat:__VA_ARGS__])
#define MOS_LOG_DEBUG(...)  	NSLog(@" DEBUG  %@ -- %@", 	MOS_CODE_LOCATION, [NSString stringWithFormat:__VA_ARGS__])
#define MOS_LOG_INFO(...)  	NSLog(@" INFO  %@ -- %@", 	MOS_CODE_LOCATION, [NSString stringWithFormat:__VA_ARGS__])
#define MOS_LOG_WARNING(...) 	NSLog(@" WARNING  %@ -- %@", 	MOS_CODE_LOCATION, [NSString stringWithFormat:__VA_ARGS__])
#define MOS_LOG_ERROR(...)  	NSLog(@" ERROR  %@ -- %@", 	MOS_CODE_LOCATION, [NSString stringWithFormat:__VA_ARGS__])

#define MOS_LOG_NSERROR(error)  NSLog(@" NSERROR  %@ -- %@%@", 	MOS_CODE_LOCATION, (error) ? @"\n" : @"", (error) ? error : @"NSError pointer is nil")

